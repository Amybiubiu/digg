//
//  SLCustomAlertView.h
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SLCustomAlertActionHandler)(void);

@interface SLCustomAlertView : UIView

// 创建并显示自定义 Alert
+ (instancetype)showAlertWithTitle:(nullable NSString *)title
                           message:(nullable NSString *)message
                      confirmTitle:(nullable NSString *)confirmTitle
                       cancelTitle:(nullable NSString *)cancelTitle
                    confirmHandler:(nullable SLCustomAlertActionHandler)confirmHandler
                     cancelHandler:(nullable SLCustomAlertActionHandler)cancelHandler;

// 设置标题样式
- (void)setTitleFont:(UIFont *)font color:(UIColor *)color;

// 设置内容样式
- (void)setMessageFont:(UIFont *)font color:(UIColor *)color;

// 设置确认按钮样式
- (void)setConfirmButtonFont:(UIFont *)font color:(UIColor *)color;

// 设置取消按钮样式
- (void)setCancelButtonFont:(UIFont *)font color:(UIColor *)color;

// 设置按钮位置（YES: 确认按钮在右侧，NO: 确认按钮在左侧）
- (void)setConfirmButtonOnRight:(BOOL)onRight;

// 设置背景样式
- (void)setBackgroundColor:(UIColor *)color withAlpha:(CGFloat)alpha;

// 设置背景模糊效果
- (void)setBackgroundBlurWithStyle:(UIBlurEffectStyle)style;

// 设置URL链接
- (void)setURL:(NSURL *)url withText:(NSString *)text;

// 显示 Alert
- (void)show;

// 关闭 Alert
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END