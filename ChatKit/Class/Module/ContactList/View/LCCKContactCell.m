//
//  LCCKContactCell.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKContactCell.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
    #import <SDWebImage/UIImageView+WebCache.h>
#else
    #import "UIImageView+WebCache.h"
#endif

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

@interface LCCKContactCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectionStatusButton;

@end

@implementation LCCKContactCell

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    self.selectionStatusButton.selected = checked;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCChatKit sharedInstance].avatarImageViewCornerRadiusBlock;
    if (avatarImageViewCornerRadiusBlock) {
        CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(self.avatarImageView.frame.size);
        [self.avatarImageView lcck_cornerRadiusAdvance:avatarImageViewCornerRadius rectCornerType:UIRectCornerAllCorners];
    }
    NSString *selectionStatusButtonNormalImageName = @"CellGraySelected";
    NSString *selectionStatusButtonSelectedImageName = @"CellBlueSelected";
    UIImage *selectionStatusButtonNormalImage = [UIImage lcck_imageNamed:selectionStatusButtonNormalImageName bundleName:@"Common" bundleForClass:[LCChatKit class]];
    UIImage *selectionStatusButtonSelectedImage = [UIImage lcck_imageNamed:selectionStatusButtonSelectedImageName bundleName:@"Common" bundleForClass:[LCChatKit class]];
    [self.selectionStatusButton setImage:selectionStatusButtonNormalImage forState:UIControlStateNormal];
    [self.selectionStatusButton setImage:selectionStatusButtonSelectedImage forState:UIControlStateSelected];
}

- (void)configureWithAvatarURL:(NSURL *)avatarURL title:(NSString *)title subtitle:(NSString *)subtitle model:(LCCKContactListMode)model {
    NSString *imageName = @"Placeholder_Avatar";
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[LCChatKit class]];
    UIImage *avatarImage = image;
    [self.avatarImageView sd_setImageWithURL:avatarURL placeholderImage:avatarImage];
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    if (subtitle.length == 0) {
        [self.subtitleLabel removeFromSuperview];
    }
    if (model == LCCKContactListModeNormal) {
        [self.selectionStatusButton removeFromSuperview];
    }
}

@end