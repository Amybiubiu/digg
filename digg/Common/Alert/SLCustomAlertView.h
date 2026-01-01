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

// 系统风格：打开链接弹窗（标题+URL+三个纵向按钮）
// 按钮顺序：阅读器打开、浏览器打开、取消
// URL 文本显示为蓝色，支持长按复制
+ (instancetype)showSystemPopupForURL:(NSURL *)url
                       openInReader:(nullable SLCustomAlertActionHandler)readerHandler
                      openInBrowser:(nullable SLCustomAlertActionHandler)browserHandler
                        cancelHandler:(nullable SLCustomAlertActionHandler)cancelHandler;

// 通用系统风格弹窗（标题、URL文本、按钮文案可配置，取消默认“取消”）
+ (instancetype)showSystemStylePopupWithTitle:(NSString *)title
                                          url:(nullable NSURL *)url
                                      urlText:(nullable NSString *)urlText
                           primaryButtonTitle:(NSString *)primaryTitle
                         secondaryButtonTitle:(NSString *)secondaryTitle
                              primaryHandler:(nullable SLCustomAlertActionHandler)primaryHandler
                            secondaryHandler:(nullable SLCustomAlertActionHandler)secondaryHandler
                              cancelHandler:(nullable SLCustomAlertActionHandler)cancelHandler;

// 包装：打开链接弹窗（调用通用接口）
+ (instancetype)showOpenLinkPopupWithURL:(NSURL *)url
                           openInReader:(nullable SLCustomAlertActionHandler)readerHandler
                          openInBrowser:(nullable SLCustomAlertActionHandler)browserHandler
                           cancelHandler:(nullable SLCustomAlertActionHandler)cancelHandler;

@end

NS_ASSUME_NONNULL_END
