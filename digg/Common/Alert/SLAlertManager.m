//
//  SLAlertManager.m
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import "SLAlertManager.h"

@implementation SLAlertManager

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                       url:(NSURL *)url
                   urlText:(NSString *)urlText
              confirmTitle:(NSString *)confirmTitle
               cancelTitle:(NSString *)cancelTitle
            confirmHandler:(SLAlertActionHandler)confirmHandler
             cancelHandler:(SLAlertActionHandler)cancelHandler
         fromViewController:(UIViewController *)viewController {
    
    // 如果没有提供视图控制器，则使用当前最顶层的视图控制器
    if (!viewController) {
        viewController = [self topViewController];
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加确认按钮
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmTitle
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        if (confirmHandler) {
            confirmHandler();
        }
    }];
    [alertController addAction:confirmAction];
    
    // 添加取消按钮（如果有）
    if (cancelTitle) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
            if (cancelHandler) {
                cancelHandler();
            }
        }];
        [alertController addAction:cancelAction];
    }
    
    // 如果有URL，添加URL处理
    if (url && urlText) {
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message ? message : @""];
        
        // 添加换行和URL文本
        if (message && message.length > 0) {
            [attributedMessage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
        }
        
        NSMutableAttributedString *urlString = [[NSMutableAttributedString alloc] initWithString:urlText];
        [urlString addAttribute:NSLinkAttributeName value:url range:NSMakeRange(0, urlText.length)];
        [urlString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(0, urlText.length)];
        [urlString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, urlText.length)];
        
        [attributedMessage appendAttributedString:urlString];
        
        // 设置富文本消息
        [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    }
    
    // 显示警告框
    [viewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)showSimpleAlertWithTitle:(NSString *)title
                         message:(NSString *)message
                    confirmTitle:(NSString *)confirmTitle
                     cancelTitle:(NSString *)cancelTitle
                  confirmHandler:(SLAlertActionHandler)confirmHandler
                   cancelHandler:(SLAlertActionHandler)cancelHandler
               fromViewController:(UIViewController *)viewController {
    
    [self showAlertWithTitle:title
                     message:message
                         url:nil
                     urlText:nil
                confirmTitle:confirmTitle
                 cancelTitle:cancelTitle
              confirmHandler:confirmHandler
               cancelHandler:cancelHandler
          fromViewController:viewController];
}

#pragma mark - Helper Methods

// 获取当前最顶层的视图控制器
+ (UIViewController *)topViewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self topViewControllerWithRootViewController:rootViewController];
}

+ (UIViewController *)topViewControllerWithRootViewController:(UIViewController *)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        return [self topViewControllerWithRootViewController:rootViewController.presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
