//
//  SLTabbarController.h
//  digg
//
//  Created by hey on 2024/10/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTabbarController : UITabBarController

// TabBar 遮罩控制方法
- (void)showTabbarMaskWithColor:(UIColor *)color;
- (void)hideTabbarMask;

@end

NS_ASSUME_NONNULL_END
