//
//  LCChatKit.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCChatKit.h"

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCChatKit ()
/*!
 *  appId
 */
@property (nonatomic, copy, readwrite) NSString *appId;

/*!
 *  appkey
 */
@property (nonatomic, copy, readwrite) NSString *appKey;
@end

@implementation LCChatKit
@synthesize sessionNotOpenedHandler = _sessionNotOpenedHandler;
@synthesize clientId = _clientId;
@synthesize client = _client;
@synthesize fetchProfilesBlock = _fetchProfilesBlock;
@synthesize generateSignatureBlock = _generateSignatureBlock;
@synthesize openProfileBlock = _openProfileBlock;
@synthesize previewImageMessageBlock = _previewImageMessageBlock;
@synthesize previewLocationMessageBlock = _previewLocationMessageBlock;
@synthesize longPressMessageBlock = _longPressMessageBlock;
@synthesize showNotificationBlock = _showNotificationBlock;
@synthesize HUDActionBlock = _HUDActionBlock;
@synthesize avatarImageViewCornerRadiusBlock = _avatarImageViewCornerRadiusBlock;
@synthesize useDevPushCerticate = _useDevPushCerticate;
@synthesize didSelectConversationsListCellBlock = _didSelectConversationsListCellBlock;
@synthesize didDeleteConversationsListCellBlock = _didDeleteConversationsListCellBlock;
@synthesize conversationEditActionBlock = _conversationEditActionBlock;
@synthesize markBadgeWithTotalUnreadCountBlock = _markBadgeWithTotalUnreadCountBlock;

#pragma mark -

+ (void)initialize {
    if (_sharedInstances == nil) {
        _sharedInstances = [NSMutableDictionary dictionary];
    }
}

+ (id)allocWithZone:(NSZone *)zone {
    // Not allow allocating memory in a different zone
    return [self sharedInstance];
}

+ (id)copyWithZone:(NSZone *)zone {
    // Not allow copying to a different zone
    return [self sharedInstance];
}

+ (instancetype)sharedInstance {
    id sharedInstance = nil;
    
    @synchronized(self) {
        NSString *instanceClass = NSStringFromClass(self);
        
        // Looking for existing instance
        sharedInstance = [_sharedInstances objectForKey:instanceClass];
        
        // If there's no instance – create one and add it to the dictionary
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
            [_sharedInstances setObject:sharedInstance forKey:instanceClass];
        }
    }
    
    return sharedInstance;
}

#pragma mark -
#pragma mark - LCChatKit Method

+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    [AVOSCloud setApplicationId:appId clientKey:appKey];
    [LCChatKit sharedInstance].appId = appId;
    [LCChatKit sharedInstance].appKey = appKey;
    if ([LCCKSettingService allLogsEnabled]) {
        NSLog(@"LeanCloudKit Version is %@", [LCCKSettingService ChatKitVersion]);
    }
}

#pragma mark -
#pragma mark - Service Delegate Method

- (LCCKSessionService *)sessionService {
    return [LCCKSessionService sharedInstance];
}

- (LCCKUserSystemService *)userSystemService {
    return [LCCKUserSystemService sharedInstance];
}

- (LCCKSignatureService *)signatureService {
    return [LCCKSignatureService sharedInstance];
}

- (LCCKSettingService *)settingService {
    return [LCCKSettingService sharedInstance];
}

- (LCCKUIService *)UIService {
    return [LCCKUIService sharedInstance];
}

- (LCCKConversationService *)conversationService {
    return [LCCKConversationService sharedInstance];
}

- (LCCKConversationListService *)conversationListService {
    return [LCCKConversationListService sharedInstance];
}

///---------------------------------------------------------------------
///---------------------LCCKSessionService------------------------------
///---------------------------------------------------------------------

- (NSString *)clientId {
    return self.sessionService.clientId;
}

- (AVIMClient *)client {
    return self.sessionService.client;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback {
    [self.sessionService openWithClientId:clientId callback:callback];
}

- (void)closeWithCallback:(LCCKBooleanResultBlock)callback {
    [self.sessionService closeWithCallback:callback];
}
- (void)setSessionNotOpenedHandler:(LCCKSessionNotOpenedHandler)sessionNotOpenedHandler {
    [self.sessionService setSessionNotOpenedHandler:sessionNotOpenedHandler];
}

///--------------------------------------------------------------------
///----------------------LCCKUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKUserSystemService

- (void)setFetchProfilesBlock:(LCCKFetchProfilesBlock)fetchProfilesBlock {
    [self.userSystemService setFetchProfilesBlock:fetchProfilesBlock];
}

- (void)removeAllCachedProfiles {
    [self.userSystemService removeAllCachedProfiles];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatarURL:(NSURL **)avatarURL error:(NSError * __autoreleasing *)error {
    [self.userSystemService getCachedProfileIfExists:userId name:name avatarURL:avatarURL error:error];
}

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCCKUserResultCallBack)callback {
    [self.userSystemService getProfileInBackgroundForUserId:userId callback:callback];
}

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCCKUserResultsCallBack)callback {
    [self.userSystemService getProfilesInBackgroundForUserIds:userIds callback:callback];
}

- (NSArray<id<LCCKUserDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error {
    return [self.userSystemService getProfilesForUserIds:userIds error:error];
}

///--------------------------------------------------------------------
///----------------------LCCKSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKSignatureService

- (void)setGenerateSignatureBlock:(LCCKGenerateSignatureBlock)generateSignatureBlock {
    [self.signatureService setGenerateSignatureBlock:generateSignatureBlock];
}

- (LCCKGenerateSignatureBlock)generateSignatureBlock {
    return [self.signatureService generateSignatureBlock];
}

///--------------------------------------------------------------------
///----------------------------LCCKUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKUIService

#pragma mark - - Open Profile

- (void)setOpenProfileBlock:(LCCKOpenProfileBlock)openProfileBlock {
    [self.UIService setOpenProfileBlock:openProfileBlock];
}

- (void)setPreviewImageMessageBlock:(LCCKPreviewImageMessageBlock)previewImageMessageBlock {
    [self.UIService setPreviewImageMessageBlock:previewImageMessageBlock];
}

- (void)setPreviewLocationMessageBlock:(LCCKPreviewLocationMessageBlock)previewLocationMessageBlock {
    [self.UIService setPreviewLocationMessageBlock:previewLocationMessageBlock];
}

- (void)setShowNotificationBlock:(LCCKShowNotificationBlock)showNotificationBlock {
    [self.UIService setShowNotificationBlock:showNotificationBlock];
}
- (void)setHUDActionBlock:(LCCKHUDActionBlock)HUDActionBlock {
    [self.UIService setHUDActionBlock:HUDActionBlock];
}

- (void)setAvatarImageViewCornerRadiusBlock:(LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    [self.UIService setAvatarImageViewCornerRadiusBlock:avatarImageViewCornerRadiusBlock];
}

- (LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    return self.UIService.avatarImageViewCornerRadiusBlock;
}

- (void)setLongPressMessageBlock:(LCCKLongPressMessageBlock)longPressMessageBlock {
    return [self.UIService setLongPressMessageBlock:longPressMessageBlock];
}

- (LCCKLongPressMessageBlock)longPressMessageBlock {
    return self.UIService.longPressMessageBlock;
}

///---------------------------------------------------------------------
///------------------LCCKSettingService---------------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKSettingService

+ (void)setAllLogsEnabled:(BOOL)enabled {
    [LCCKSettingService setAllLogsEnabled:YES];
}

+ (BOOL)allLogsEnabled {
   return [LCCKSettingService allLogsEnabled];
}

+ (NSString *)ChatKitVersion {
    return [LCCKSettingService ChatKitVersion];
}

- (void)syncBadge {
    [[LCCKSettingService sharedInstance] syncBadge];
}

- (BOOL)useDevPushCerticate {
    return [[LCCKSettingService sharedInstance] useDevPushCerticate];
}

- (void)setUseDevPushCerticate:(BOOL)useDevPushCerticate {
    [LCCKSettingService sharedInstance].useDevPushCerticate = useDevPushCerticate;
}

///---------------------------------------------------------------------
///---------------------LCCKConversationService-------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKConversationService

- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(AVIMConversationResultBlock)callback {
    [self.conversationService fecthConversationWithConversationId:conversationId callback:callback];
}

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
    [self.conversationService fecthConversationWithPeerId:peerId callback:callback];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self.conversationService didReceiveRemoteNotification:userInfo];
}

- (void)increaseUnreadCountWithConversationId:(NSString *)conversationId {
    [self.conversationService increaseUnreadCountWithConversationId:conversationId];
}

- (void)deleteRecentConversationWithConversationId:(NSString *)conversationId {
    [self.conversationService deleteRecentConversationWithConversationId:conversationId];
}

- (void)updateUnreadCountToZeroWithConversationId:(NSString *)conversationId {
    [self.conversationService updateUnreadCountToZeroWithConversationId:conversationId];
}

- (BOOL)removeAllCachedRecentConversations {
    return [self.conversationService removeAllCachedRecentConversations];
}

///---------------------------------------------------------------------
///---------------------LCCKConversationsListService--------------------
///---------------------------------------------------------------------

- (void)setDidSelectConversationsListCellBlock:(LCCKDidSelectConversationsListCellBlock)didSelectConversationsListCellBlock {
    [self.conversationListService setDidSelectConversationsListCellBlock:didSelectConversationsListCellBlock];
}

- (void)setDidDeleteConversationsListCellBlock:(LCCKDidDeleteConversationsListCellBlock)didDeleteConversationsListCellBlock {
    [self.conversationListService setDidDeleteConversationsListCellBlock:didDeleteConversationsListCellBlock];
}

- (void)setConversationEditActionBlock:(LCCKConversationEditActionsBlock)conversationEditActionBlock {
    [self.conversationListService setConversationEditActionBlock:conversationEditActionBlock];
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCCKMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    [self.conversationListService setMarkBadgeWithTotalUnreadCountBlock:markBadgeWithTotalUnreadCountBlock];
}

//TODO:CacheService;

@end


