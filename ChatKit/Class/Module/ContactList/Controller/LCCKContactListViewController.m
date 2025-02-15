//
//  LCCKContactListViewController.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKContactListViewController.h"
#import "LCCKContactCell.h"
#import "LCCKContactManager.h"
#import "LCCKAlertController.h"

static NSString *const LCCKContactListViewControllerIdentifier = @"LCCKContactListViewControllerIdentifier";

@interface LCCKContactListViewController ()<UISearchBarDelegate,UISearchDisplayDelegate>
@property (nonatomic, copy) LCCKSelectedContactCallback selectedContactCallback;

@property (nonatomic, copy) LCCKSelectedContactsCallback selectedContactsCallback;
@property (nonatomic, copy) LCCKDeleteContactCallback deleteContactCallback;

//=========================================================
//================== origin TableView =====================
//=========================================================
@property (nonatomic, copy) NSDictionary *originSections;
@property (nonatomic, copy) NSArray<NSString *> *userNames;

//=========================================================
//================ searchResults TableView ================
//=========================================================
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, copy) NSArray *searchContacts;
@property (nonatomic, copy) NSDictionary *searchSections;
@property (nonatomic, copy) NSArray<NSString *> *searchUserIds;

//=========================================================
//================ TableView Contoller ====================
//=========================================================
@property (nonatomic, strong) NSMutableDictionary *dictionaryTableRowCheckedState;
@property (nonatomic, copy) NSString *selectedContact;
@property (nonatomic, strong) NSMutableArray *selectedContacts;

@property (nonatomic, copy, readwrite) NSArray<LCCKContact *> *contacts;

@end

@implementation LCCKContactListViewController

- (instancetype)initWithMode:(LCCKContactListMode)mode {
    return [self initWithExcludedUserIds:nil mode:mode];
}

- (instancetype)initWithExcludedUserIds:(NSArray *)excludedUserIds
                                   mode:(LCCKContactListMode)mode {
    return [self initWithContacts:nil excludedUserIds:excludedUserIds mode:mode];
}

- (instancetype)initWithContacts:(NSArray<LCCKContact *> *)contacts
                         userIds:(NSArray<NSString *> *)userIds
                 excludedUserIds:(NSArray *)excludedUserIds
                            mode:(LCCKContactListMode)mode {
    self = [super init];
    if (!self) {
        return nil;
    }
    _contacts = contacts;
    _excludedUserIds = excludedUserIds;
    _mode = mode;
    _userIds = userIds;
    return self;
}

- (instancetype)initWithContacts:(NSArray<LCCKContact *> *)contacts
                 excludedUserIds:(NSArray *)excludedUserIds
                            mode:(LCCKContactListMode)mode {
    return [self initWithContacts:contacts userIds:nil excludedUserIds:excludedUserIds mode:mode];
}

#pragma mark -
#pragma mark - Lazy Load Method

/**
 *  lazy load selectedContacts
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)selectedContacts {
    if (_selectedContacts == nil) {
        _selectedContacts = [[NSMutableArray alloc] init];
    }
    return _selectedContacts;
}

/**
 *  lazy load dictionaryTableRowCheckedState
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)dictionaryTableRowCheckedState {
    if (_dictionaryTableRowCheckedState == nil) {
        _dictionaryTableRowCheckedState = [[NSMutableDictionary alloc] init];
    }
    return _dictionaryTableRowCheckedState;
}

#pragma mark -
#pragma mark - Setter Method

- (void)setSelectedContact:(NSString *)selectedContact {
    _selectedContact = [selectedContact copy];
    if (selectedContact) {
        [self selectedContactCallback](self, selectedContact); //Callback callback to update parent TVC
    }
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"联系人";
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
    [searchBar sizeToFit];
    searchBar.delegate = self;
    searchBar.placeholder = @"搜索";
    self.tableView.tableHeaderView = searchBar;
    self.tableView.tableFooterView = [[UIView alloc] init];
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    // searchResultsDataSource 就是 UITableViewDataSource
    searchDisplayController.searchResultsDataSource = self;
    // searchResultsDelegate 就是 UITableViewDelegate
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.delegate = self;
    self.searchController = searchDisplayController;
    searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] init];
    NSBundle *bundle = [NSBundle bundleForClass:[LCChatKit class]];
    [searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"LCCKContactCell" bundle:bundle]
                                         forCellReuseIdentifier:LCCKContactListViewControllerIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"LCCKContactCell" bundle:bundle]
         forCellReuseIdentifier:LCCKContactListViewControllerIdentifier];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.f*0xdf/0xff alpha:1.f];
    if ([self.tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
    [self.navigationItem setTitle:@"联系人"];
    if (self.mode == LCCKContactListModeNormal) {
        self.navigationItem.title = @"联系人";
        //TODO:
        //        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"搜索"
        //                                                                                  style:UIBarButtonItemStylePlain
        //                                                                                target:self
        //                                                                                action:@selector(searchBarButtonItemPressed:)];
        //        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"登出"
        //                                                                                  style:UIBarButtonItemStylePlain
        //                                                                                 target:self
        //                                                                                 action:@selector(signOut)];
    } else {
        self.navigationItem.title = @"选择联系人";
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(doneBarButtonItemPressed:)];
        self.navigationItem.rightBarButtonItem = doneButtonItem;
        //        [self.tableView setEditing:YES animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.presentingViewController) {
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelBarButtonItemPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButtonItem;
    }
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self setDictionaryTableRowCheckedState:[NSMutableDictionary dictionary]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.mode == LCCKContactListModeMultipleSelection) {
        //  Return an array of selectedContacts
        [self selectedContactsCallback](self, self.selectedContacts);
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _originSections = nil;
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[self sortedSectionTitlesForTableView:tableView].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionKey = [self sortedSectionTitlesForTableView:tableView][(NSUInteger)section];
    NSArray *array = [self currentSectionsForTableView:tableView][sectionKey];
    return (NSInteger)array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKContactCell *cell = [tableView dequeueReusableCellWithIdentifier:LCCKContactListViewControllerIdentifier forIndexPath:indexPath];
    id contact = [self contactAtIndexPath:indexPath tableView:tableView];
    NSURL *avatarURL = nil;
    NSString *name = nil;
    NSString *clientId = nil;
    if ([contact isKindOfClass:[NSString class]]) {
        name = contact;
        clientId = contact;
    } else {
        LCCKContact *contact_ = (LCCKContact *)contact;
        avatarURL = contact_.avatarURL;
        name = contact_.name ?: contact_.clientId;
        clientId = contact_.clientId;
    }
    [self contactAtIndexPath:indexPath tableView:tableView];
    [cell configureWithAvatarURL:avatarURL title:name subtitle:nil model:self.mode];
    BOOL isChecked = NO;
    if (self.mode == LCCKContactListModeSingleSelection) {
        if (clientId == self.selectedContact) {
            isChecked = YES;
        }
        cell.checked = isChecked;
    } else if (self.mode == LCCKContactListModeMultipleSelection) {
        if ([self.selectedContacts containsObject:clientId]) {
            isChecked = YES;
        }
        self.dictionaryTableRowCheckedState[indexPath] = @(isChecked);
        cell.checked = isChecked;
    } else {
        NSLog(@"%@ - %@ - has (possible undefined) E~R~R~O~R attempting to set UITableViewCellAccessory at indexPath: %@_", NSStringFromClass(self.class), NSStringFromSelector(_cmd), indexPath);
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self sortedSectionTitlesForTableView:tableView][(NSUInteger)section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self sortedSectionTitlesForTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}
#pragma mark - Helpers

- (id)contactAtIndexPath:(NSIndexPath*)indexPath {
    return [self contactAtIndexPath:indexPath tableView:self.tableView];
}

- (id)contactAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView *)tableView {
    NSArray *contactsGroupedInSections = [self sortedSectionTitlesForTableView:tableView];
    if (indexPath.section < contactsGroupedInSections.count) {
        NSString *sectionKey = contactsGroupedInSections[(NSUInteger)indexPath.section];
        NSArray *contactsInSection = [self currentSectionsForTableView:tableView][sectionKey];
        if (indexPath.row < contactsInSection.count) {
            id contact = contactsInSection[(NSUInteger)indexPath.row];;
            return contact;
        }
    }
    return nil;
}

- (NSString *)currentClientIdAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    id contact = [self contactAtIndexPath:indexPath tableView:tableView];
    if ([contact isKindOfClass:[NSString class]]) {
        return contact;
    }
    LCCKContact *contact_ = contact;
    NSString *clientId = contact_.clientId;
    return clientId;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKContactCell *cell = [tableView dequeueReusableCellWithIdentifier:LCCKContactListViewControllerIdentifier forIndexPath:indexPath];
    NSString *clientId = [self currentClientIdAtIndexPath:indexPath tableView:tableView];
    if (self.mode == LCCKContactListModeSingleSelection) {
        if (clientId == self.selectedContact) {
            cell.checked = NO;
            self.selectedContact = nil;
        } else {
            cell.checked = YES;
            self.selectedContact = clientId;
        }
        [self.searchController setActive:NO animated:NO];
        [self reloadData:tableView];
        return;
    }
    if (self.mode == LCCKContactListModeMultipleSelection) {
        //  Toggle the cell checked state
        __block BOOL isChecked = !((NSNumber *)self.dictionaryTableRowCheckedState[indexPath]).boolValue;
        self.dictionaryTableRowCheckedState[indexPath] = @(isChecked);
        cell.checked = isChecked;
        if (isChecked) {
            [self.selectedContacts addObject:clientId];
        } else {
            [self.selectedContacts removeObject:clientId];
        }
        [self reloadData:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchController setActive:NO animated:NO];
    self.selectedContact = clientId;
    [self reloadData:tableView];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return NO;
    }
    if (self.mode == LCCKContactListModeNormal) {
        return YES;
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)deleteClientId:(NSString *)clientId {
    NSMutableArray<LCCKContact *> *array = [NSMutableArray arrayWithArray:self.contacts];
    [array removeObjectsInArray:[array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"clientId == %@", clientId]]];
    NSAssert(self.contacts.count > array.count, @"self.contacts.count <= array.count?");
    self.contacts = [array copy];
    self.originSections = nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == LCCKContactListModeNormal) {
        NSString *peerId = [self currentClientIdAtIndexPath:indexPath tableView:tableView];
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSString *title = [NSString stringWithFormat:@"%@?", NSLocalizedStringFromTable(@"deleteFriend", @"LCChatKitString", @"解除好友关系吗")];
            LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                               message:@""
                                                                        preferredStyle:LCCKAlertControllerStyleAlert];
            NSString *cancelActionTitle = NSLocalizedStringFromTable(@"cancel", @"LCChatKitString", @"取消");
            LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {}];
            [alert addAction:cancelAction];
            NSString *resendActionTitle = NSLocalizedStringFromTable(@"ok", @"LCChatKitString", @"确定");
            LCCKAlertAction* resendAction = [LCCKAlertAction actionWithTitle:resendActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {
                                                                         if (self.deleteContactCallback) {
                                                                             BOOL delegateSuccess = self.deleteContactCallback(self, peerId);
                                                                             if (delegateSuccess) {
                                                                                 [self deleteClientId:peerId];
                                                                                 [self reloadDataAfterDeleteData:tableView];
                                                                             }
                                                                         }
                                                                     }];
            [alert addAction:resendAction];
            [alert showWithSender:nil controller:self animated:YES completion:NULL];
        }
    }
}

#pragma mark - Data

- (NSDictionary *)currentSectionsForTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return self.searchSections;
    }
    return self.originSections;
}

- (NSArray *)excludedUserNames {
    NSArray<id<LCCKUserDelegate>> *excludedUsers = [[LCChatKit sharedInstance] getProfilesForUserIds:self.excludedUserIds error:nil];
    NSMutableArray *excludedUserNames = [NSMutableArray arrayWithCapacity:excludedUsers.count];
    [excludedUsers enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @try {
            if (obj.name) {
                [excludedUserNames addObject:obj.name];
            } else {
                [excludedUserNames addObject:obj.clientId];
            }
            
        } @catch (NSException *exception) {        }
    }];
    if (excludedUsers.count > 0) {
        return [excludedUserNames copy];
    }
    return [self.excludedUserIds copy];
}

- (NSArray *)contactsFromContactsOrUserIds:(NSArray *)contacts userIds:(NSArray *)userIds{
    if (contacts.count > 0) {
        return contacts;
    } else {
        return userIds;
    }
}

- (NSMutableDictionary *)sortedSectionForUserNames:(NSArray *)contactsOrUserNames {
    NSMutableDictionary *originSections = [NSMutableDictionary dictionary];
    [contactsOrUserNames enumerateObjectsUsingBlock:^(id  _Nonnull contactOrUserName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *userName;
        LCCKContact *contact;
        if ([contactOrUserName isKindOfClass:[NSString class]]) {
            userName = (NSString *)contactOrUserName;
        } else {
            contact = (LCCKContact *)contactOrUserName;
            userName = contact.name ?: contact.clientId;
        }
        if ([self.excludedUserNames containsObject:userName]) {
            return;
        }
        NSString *indexKey = [self indexTitleForName:userName];
        NSMutableArray *names = originSections[indexKey];
        if (!names) {
            names = [NSMutableArray array];
            originSections[indexKey] = names;
        }
        [names addObject:contactOrUserName];
    }];
    return originSections;
}

- (NSDictionary *)searchSections {
    return  [self sortedSectionForUserNames:[self contactsFromContactsOrUserIds:self.searchContacts userIds:self.searchUserIds]];
}

- (NSDictionary *)originSections {
    if (!_originSections) {
        _originSections = [self sortedSectionForUserNames:[self contactsFromContactsOrUserIds:self.contacts userIds:self.userIds]];
    }
    return _originSections;
}

- (NSArray *)sortedSectionTitlesForTableView:(UITableView *)tableView {
    return [[[self currentSectionsForTableView:tableView] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSString *)indexTitleForName:(NSString *)name {
    static NSString *otherKey = @"#";
    if (!name) {
        return otherKey;
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:[name substringToIndex:1]];
    CFMutableStringRef mutableStringRef = (__bridge CFMutableStringRef)mutableString;
    CFStringTransform(mutableStringRef, nil, kCFStringTransformToLatin, NO);
    CFStringTransform(mutableStringRef, nil, kCFStringTransformStripCombiningMarks, NO);
    
    NSString *key = [[mutableString uppercaseString] substringToIndex:1];
    unichar capital = [key characterAtIndex:0];
    if (capital >= 'A' && capital <= 'Z') {
        return key;
    }
    return otherKey;
}

- (void)cancelBarButtonItemPressed:(id)sender {
    self.selectedContacts = nil;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doneBarButtonItemPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)refresh {
    //TODO: add refesh
}

- (void)reloadDataAfterDeleteData:(UITableView *)tableView {
    [tableView reloadData];
    [self reloadData:tableView];
}

- (void)reloadAllTableViewData:(UITableView *)tableView {
    [self reloadData:tableView];
    [self reloadData:self.tableView];
}

- (void)reloadData:(UITableView *)tableView {
    [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadData {
    [self reloadData:self.tableView];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.searchController setActive:YES animated:YES];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self reloadAllTableViewData:tableView];
}

#pragma mark - UISearchDisplayDelegate

// return YES to reload table. called when search string/option changes. convenience methods on top UISearchBar delegate methods
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(nullable NSString *)searchString NS_DEPRECATED_IOS(3_0,8_0){
    [self filterContentForSearchText:searchString];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption NS_DEPRECATED_IOS(3_0,8_0){
    return YES;
}

- (void)filterContentForSearchText:(NSString *)searchString {
    //  for (NSString *searchString in searchItems) {
    // each searchString creates an OR predicate for: name, id
    //
    // example if searchItems contains "iphone 599 2007":
    //      name CONTAINS[c] "lanmaq"
    //      id CONTAINS[c] "1568689942"
    if (!self.contacts) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", searchString];
        self.searchUserIds = [self.userIds filteredArrayUsingPredicate:predicate];
        self.searchContacts = nil;
        return;
    }
    NSMutableArray *searchResults = [self.contacts mutableCopy];
    
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    NSMutableArray *searchItemsPredicate = [NSMutableArray array];
    
    // use NSExpression represent expressions in predicates.
    // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
    
    // name field matching
    NSExpression *leftExpression = [NSExpression expressionForKeyPath:@"name"];
    NSExpression *rightExpression = [NSExpression expressionForConstantValue:searchString];
    NSPredicate *finalPredicate = [NSComparisonPredicate
                                   predicateWithLeftExpression:leftExpression
                                   rightExpression:rightExpression
                                   modifier:NSDirectPredicateModifier
                                   type:NSContainsPredicateOperatorType
                                   options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // userId field matching
    leftExpression = [NSExpression expressionForKeyPath:@"userId"];
    rightExpression = [NSExpression expressionForConstantValue:searchString];
    finalPredicate = [NSComparisonPredicate
                      predicateWithLeftExpression:leftExpression
                      rightExpression:rightExpression
                      modifier:NSDirectPredicateModifier
                      type:NSContainsPredicateOperatorType
                      options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // ClientId field matching
    leftExpression = [NSExpression expressionForKeyPath:@"clientId"];
    rightExpression = [NSExpression expressionForConstantValue:searchString];
    finalPredicate = [NSComparisonPredicate
                      predicateWithLeftExpression:leftExpression
                      rightExpression:rightExpression
                      modifier:NSDirectPredicateModifier
                      type:NSContainsPredicateOperatorType
                      options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // at this OR predicate to our master AND predicate
    NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
    [andMatchPredicates addObject:orMatchPredicates];
    
    // match up the fields of the Product object
    NSCompoundPredicate *finalCompoundPredicate =
    [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    self.searchContacts = [[searchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    [self reloadData];
}

@end