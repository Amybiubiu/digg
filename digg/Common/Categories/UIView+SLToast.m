//
//  UIView+SLToast.m
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import "UIView+SLToast.h"

@implementation UIView (SLToast)

- (void)sl_showToast:(NSString *)message {
    [self sl_showToast:message duration:2.0];
}

- (void)sl_showToast:(NSString *)message duration:(NSTimeInterval)duration {
    // 创建一个带有圆角和半透明背景的容器视图
    UIView *toastContainer = [[UIView alloc] init];
    toastContainer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    toastContainer.alpha = 0.0;
    [self addSubview:toastContainer];
    
    // 创建消息标签
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = message;
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.font = [UIFont systemFontOfSize:15.0];
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [toastContainer addSubview:messageLabel];
    
    // 设置约束
    toastContainer.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [messageLabel.leadingAnchor constraintEqualToAnchor:toastContainer.leadingAnchor constant:20.0].active = YES;
    [messageLabel.trailingAnchor constraintEqualToAnchor:toastContainer.trailingAnchor constant:-20.0].active = YES;
    [messageLabel.topAnchor constraintEqualToAnchor:toastContainer.topAnchor constant:12.0].active = YES;
    [messageLabel.bottomAnchor constraintEqualToAnchor:toastContainer.bottomAnchor constant:-12.0].active = YES;
    
    [toastContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    [toastContainer.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
    [toastContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.8].active = YES;
    
    // 布局后设置胶囊圆角
    [self layoutIfNeeded];
    toastContainer.layer.cornerRadius = toastContainer.frame.size.height / 2.0;
    toastContainer.layer.masksToBounds = YES;
    
    // 显示动画
    [UIView animateWithDuration:0.3 animations:^{
        toastContainer.alpha = 1.0;
    } completion:^(BOOL finished) {
        // 延迟后隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toastContainer.alpha = 0.0;
            } completion:^(BOOL finished) {
                [toastContainer removeFromSuperview];
            }];
        });
    }];
}

@end