//
//  SLAddLinkViewController.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLAddLinkViewController : UIViewController

// 回调处理
@property (nonatomic, copy) void (^submitHandler)(NSString *title, NSString *link);

// 显示方法
- (void)showInViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END