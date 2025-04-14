//
//  SLAlertManager.h
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SLAlertActionHandler)(void);

@interface SLAlertManager : NSObject

/**
 * 显示带URL的系统提示框
 * @param title 标题
 * @param message 消息内容
 * @param url 可点击的URL
 * @param urlText URL显示的文本
 * @param confirmTitle 确认按钮标题
 * @param cancelTitle 取消按钮标题（可为nil）
 * @param confirmHandler 确认按钮回调
 * @param cancelHandler 取消按钮回调
 * @param viewController 要显示在哪个视图控制器上
 */
+ (void)showAlertWithTitle:(nullable NSString *)title
                   message:(nullable NSString *)message
                       url:(nullable NSURL *)url
                   urlText:(nullable NSString *)urlText
              confirmTitle:(NSString *)confirmTitle
               cancelTitle:(nullable NSString *)cancelTitle
            confirmHandler:(nullable SLAlertActionHandler)confirmHandler
             cancelHandler:(nullable SLAlertActionHandler)cancelHandler
         fromViewController:(nullable UIViewController *)viewController;

/**
 * 显示简单的系统提示框（不带URL）
 * @param title 标题
 * @param message 消息内容
 * @param confirmTitle 确认按钮标题
 * @param cancelTitle 取消按钮标题（可为nil）
 * @param confirmHandler 确认按钮回调
 * @param cancelHandler 取消按钮回调
 * @param viewController 要显示在哪个视图控制器上
 */
+ (void)showSimpleAlertWithTitle:(nullable NSString *)title
                         message:(nullable NSString *)message
                    confirmTitle:(NSString *)confirmTitle
                     cancelTitle:(nullable NSString *)cancelTitle
                  confirmHandler:(nullable SLAlertActionHandler)confirmHandler
                   cancelHandler:(nullable SLAlertActionHandler)cancelHandler
               fromViewController:(nullable UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
