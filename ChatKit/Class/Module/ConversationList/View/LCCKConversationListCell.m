//
//  LCCKConversationListCell.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKConversationListCell.h"
#import "LCCKBadgeView.h"
#import "LCChatKit.h"
#import "UIImageView+LCCKExtension.h"

static CGFloat LCCKImageSize = 45;
static CGFloat LCCKVerticalSpacing = 8;
static CGFloat LCCKHorizontalSpacing = 10;
static CGFloat LCCKTimestampeLabelWidth = 100;
static CGFloat LCCKAutoResizingDefaultScreenWidth = 320;
static CGFloat LCCKNameLabelHeightProportion = 3.0 / 5;
static CGFloat LCCKNameLabelHeight;
static CGFloat LCCKMessageLabelHeight;
static CGFloat LCCKLittleBadgeSize = 10;
static CGFloat LCCKRemindMuteSize = 18;

CGFloat const LCCKConversationListCellDefaultHeight = 61; //LCCKImageSize + LCCKVerticalSpacing * 2;

@implementation LCCKConversationListCell

+ (instancetype)dequeueOrCreateCellByTableView :(UITableView *)tableView {
    LCCKConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:[LCCKConversationListCell identifier]];
    if (cell == nil) {
        cell = [[LCCKConversationListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[[self class] identifier]];
    }
    return cell;
}

+ (void)registerCellToTableView:(UITableView *)tableView {
    [tableView registerClass:[LCCKConversationListCell class] forCellReuseIdentifier:[[self class] identifier]];
}

+ (NSString *)identifier {
    return NSStringFromClass([LCCKConversationListCell class]);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    LCCKNameLabelHeight = LCCKImageSize * LCCKNameLabelHeightProportion;
    LCCKMessageLabelHeight = LCCKImageSize - LCCKNameLabelHeight;
    [self addSubview:self.avatarImageView];
    [self.avatarImageView addSubview:self.badgeView];
    [self addSubview:self.timestampLabel];
    [self.contentView addSubview:self.litteBadgeView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.messageTextLabel];
    [self.contentView addSubview:self.remindMuteImageView];
}

- (UIImageView *)avatarImageView {
    if (_avatarImageView == nil) {
        UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCCKHorizontalSpacing, LCCKVerticalSpacing, LCCKImageSize, LCCKImageSize)];
        LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCChatKit sharedInstance].avatarImageViewCornerRadiusBlock;
        if (avatarImageViewCornerRadiusBlock) {
            CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(avatarImageView.frame.size);
            [avatarImageView lcck_cornerRadiusAdvance:avatarImageViewCornerRadius rectCornerType:UIRectCornerAllCorners];
        }
        _avatarImageView = avatarImageView;
    }
    return _avatarImageView;
}

- (UIView *)litteBadgeView {
    if (_litteBadgeView == nil) {
        UIView *litteBadgeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LCCKLittleBadgeSize, LCCKLittleBadgeSize)];
        litteBadgeView.layer.masksToBounds = YES;
        litteBadgeView.layer.cornerRadius = LCCKLittleBadgeSize / 2;
        litteBadgeView.center = CGPointMake(CGRectGetMaxX(_avatarImageView.frame), CGRectGetMinY(_avatarImageView.frame));
        litteBadgeView.hidden = YES;
        _litteBadgeView = litteBadgeView;
    }
    return _litteBadgeView;
}

- (UILabel *)timestampLabel {
    if (_timestampLabel == nil) {
        UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(LCCKAutoResizingDefaultScreenWidth - LCCKHorizontalSpacing - LCCKTimestampeLabelWidth, CGRectGetMinY(_avatarImageView.frame), LCCKTimestampeLabelWidth, LCCKNameLabelHeight)];
        timestampLabel.font = [UIFont systemFontOfSize:13];
        timestampLabel.textAlignment = NSTextAlignmentRight;
        timestampLabel.textColor = [UIColor grayColor];
        timestampLabel.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _timestampLabel = timestampLabel;
    }
    return _timestampLabel;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_avatarImageView.frame) + LCCKHorizontalSpacing, CGRectGetMinY(_avatarImageView.frame), CGRectGetMinX(_timestampLabel.frame) - LCCKHorizontalSpacing * 3 - LCCKImageSize, LCCKNameLabelHeight)];
        nameLabel.font = [UIFont systemFontOfSize:17];
        nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _nameLabel = nameLabel;
    }
    return _nameLabel;
}

- (UILabel *)messageTextLabel {
    if (_messageTextLabel == nil) {
        UILabel *messageTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nameLabel.frame), CGRectGetMaxY(_nameLabel.frame), LCCKAutoResizingDefaultScreenWidth - 4 * LCCKHorizontalSpacing - LCCKImageSize - LCCKRemindMuteSize, LCCKMessageLabelHeight)];
        messageTextLabel.backgroundColor = [UIColor clearColor];
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _messageTextLabel = messageTextLabel;
    }
    return _messageTextLabel;
}

- (UIButton *)remindMuteImageView {
    if (_remindMuteImageView == nil) {
        UIButton *remindMuteImageView = [UIButton buttonWithType:UIButtonTypeCustom];
        remindMuteImageView.frame = CGRectMake(CGRectGetMaxX(_messageTextLabel.frame) + LCCKHorizontalSpacing, CGRectGetMinY(_messageTextLabel.frame), LCCKRemindMuteSize, LCCKRemindMuteSize);
        NSString *remindMuteImageName = @"Remind_Mute";
        remindMuteImageView.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
        UIImage *remindMuteImage = [UIImage lcck_imageNamed:remindMuteImageName bundleName:@"Common" bundleForClass:[LCChatKit class]];
        [remindMuteImageView setImage:remindMuteImage forState:UIControlStateNormal];
        remindMuteImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        remindMuteImageView.hidden = YES;
        _remindMuteImageView = remindMuteImageView;
    }
    return _remindMuteImageView;
}


- (LCCKBadgeView *)badgeView {
    if (_badgeView == nil) {
        LCCKBadgeView *badgeView = [[LCCKBadgeView alloc] initWithParentView:self.avatarImageView
                                                               alignment:LCCKBadgeViewAlignmentTopRight];
        [self.avatarImageView addSubview:(_badgeView = badgeView)];
        [self.avatarImageView bringSubviewToFront:_badgeView];
    }
    return _badgeView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.badgeView.badgeText = nil;
    self.badgeView = nil;
    self.litteBadgeView.hidden = YES;
    self.messageTextLabel.text = nil;
    self.timestampLabel.text = nil;
    self.nameLabel.text = nil;
}

@end
