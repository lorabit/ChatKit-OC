//
//  LCCKUserSystemService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"

NSString *const LCCKUserSystemServiceErrorDomain = @"LCCKUserSystemServiceErrorDomain";

@interface LCCKUserSystemService ()
@property (nonatomic, strong) NSMutableDictionary *cachedUsers;
@end

@implementation LCCKUserSystemService
@synthesize fetchProfilesBlock = _fetchProfilesBlock;

- (void)setFetchProfilesBlock:(LCCKFetchProfilesBlock)fetchProfilesBlock {
    _fetchProfilesBlock = fetchProfilesBlock;
}

- (NSArray<id<LCCKUserDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCCKUserDelegate>> *blockUsers = [NSArray array];
    if (!_fetchProfilesBlock) {
        // This enforces implementing `-setFetchProfilesBlock:`.
        NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow LeanCloudChatKit to get user information by user id."];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
        return nil;
    }
    LCCKFetchProfilesCallBack callback = ^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        blockUsers = users;
        [self cacheUsers:users];
    };
    _fetchProfilesBlock(userIds, callback);
    
    return blockUsers;
}

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCCKUserResultsCallBack)callback {
    if (userIds.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_fetchProfilesBlock) {
            // This enforces implementing `-setFetchProfilesBlock:`.
            NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow LeanCloudChatKit to get user information by user id."];
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
        
        _fetchProfilesBlock(userIds, ^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (!error && (users.count > 0)) {
                [self cacheUsers:users];
                dispatch_async(dispatch_get_main_queue(),^{
                    !callback ?: callback(users, nil);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(nil, error);
            });
        });
    });
}

- (id<LCCKUserDelegate>)getProfileForUserId:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        if (*theError == nil) {
            *theError = error;
        }
        return nil;
    }
    
    id<LCCKUserDelegate> user = [self getCachedProfileIfExists:userId error:nil];
    if (user) {
        return user;
    }
    NSArray *users = [self getProfilesForUserIds:@[userId] error:theError];
    if (users.count > 0) {
        return users[0];
    }
    return nil;
}

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCCKUserResultCallBack)callback {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        !callback ?: callback(nil, error);
        return;
    }
    [self getProfilesInBackgroundForUserIds:@[userId] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        if (!error && (users.count > 0)) {
            !callback ?: callback(users[0], nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatarURL:(NSURL **)avatarURL error:(NSError * __autoreleasing *)theError {
    if (userId) {
        NSString *userName_ = nil;
        NSURL *avatarURL_ = nil;
        id<LCCKUserDelegate> user = self.cachedUsers[userId];
        userName_ = user.name;
        avatarURL_ = user.avatarURL;
        if (userName_ || avatarURL_) {
            if (*name == nil) {
                *name = userName_;
            }
            if (*avatarURL == nil) {
                *avatarURL = avatarURL_;
            }
            return;
        }
        
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (*theError == nil) {
        *theError = error;
    }
}

- (void)removeCachedProfileForPeerId:(NSString *)peerId {
    [self.cachedUsers removeObjectForKey:peerId];
}

- (void)removeAllCachedProfiles {
    self.cachedUsers = nil;
}

- (id<LCCKUserDelegate>)fetchCurrentUser {
    NSError *error = nil;
    id<LCCKUserDelegate> user = [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return user;
    }
    error = nil;
    id<LCCKUserDelegate> currentUser = [[LCCKUserSystemService sharedInstance] getProfileForUserId:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return currentUser;
    }
//    NSLog(@"%@", error);
    return nil;
}

- (void)fetchCurrentUserInBackground:(LCCKUserResultCallBack)callback {
    NSError *error = nil;
    id<LCCKUserDelegate> user = [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        !callback ?: callback(user, nil);
        return;
    }
    
    [[LCCKUserSystemService sharedInstance] getProfileInBackgroundForUserId:[LCCKSessionService sharedInstance].clientId callback:^(id<LCCKUserDelegate> user, NSError *error) {
        if (!error) {
            !callback ?: callback(user, nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}


- (id<LCCKUserDelegate>)getCachedProfileIfExists:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    id<LCCKUserDelegate> user;
    if (userId) {
        user = self.cachedUsers[userId];
    }
    if (user) {
        return user;
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (theError) {
        *theError = error;
    }
    return nil;
}

- (void)cacheUsersWithIds:(NSSet<id<LCCKUserDelegate>> *)userIds callback:(LCCKBooleanResultBlock)callback {
    NSMutableSet *uncachedUserIds = [[NSMutableSet alloc] init];
    for (NSString *userId in userIds) {
        if ([self getCachedProfileIfExists:userId error:nil] == nil) {
            [uncachedUserIds addObject:userId];
        }
    }
    if ([uncachedUserIds count] > 0) {
        [self getProfilesInBackgroundForUserIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (users) {
                [self cacheUsers:users];
            }
            callback(YES, error);
        }];
    } else {
        callback(YES, nil);
    }
}

- (void)cacheUsers:(NSArray<id<LCCKUserDelegate>> *)users {
    for (id<LCCKUserDelegate> user in users) {
        @try {
            self.cachedUsers[user.clientId] = user;
        } @catch (NSException *exception) { }
    }
}

#pragma mark -
#pragma mark - LazyLoad Method

/**
 *  lazy load cachedUsers
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)cachedUsers {
    if (_cachedUsers == nil) {
        _cachedUsers = [[NSMutableDictionary alloc] init];
    }
    return _cachedUsers;
}



@end