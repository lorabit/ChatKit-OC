//
//  LCCKStatusView.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKStatusView.h"
#import "LCChatKit.h"
#import "UIImage+LCCKExtension.h"

static CGFloat LCCKStatusImageViewHeight = 20;
static CGFloat LCCKHorizontalSpacing = 15;
static CGFloat LCCKHorizontalLittleSpacing = 5;

@interface LCCKStatusView ()

@property (nonatomic, strong) UIImageView *statusImageView;

@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation LCCKStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:199 / 255.0 blue:199 / 255.0 alpha:1];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.statusImageView];
    [self addSubview:self.statusLabel];
}

#pragma mark - Propertys

- (UIImageView *)statusImageView {
    if (_statusImageView == nil) {
        _statusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCCKHorizontalSpacing, (LCCKStatusViewHight - LCCKStatusImageViewHeight) / 2, LCCKStatusImageViewHeight, LCCKStatusImageViewHeight)];
        _statusImageView.image =  ({
            NSString *imageName = @"MessageSendFail";
            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
            image;});
    }
    return _statusImageView;
}

- (UILabel *)statusLabel {
    if (_statusLabel == nil) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_statusImageView.frame) + LCCKHorizontalLittleSpacing, 0, self.frame.size.width - CGRectGetMaxX(_statusImageView.frame) - LCCKHorizontalSpacing - LCCKHorizontalLittleSpacing, LCCKStatusViewHight)];
        _statusLabel.font = [UIFont systemFontOfSize:15.0];
        _statusLabel.textColor = [UIColor grayColor];
        _statusLabel.text = NSLocalizedStringFromTable(@"netDisconnected", @"LCChatKitString", @"当前网络不可用，请检查你的网络设置");
    }
    return _statusLabel;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(statusViewClicked:)]) {
        [self.delegate statusViewClicked:self];
    }
}

@end
