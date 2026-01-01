//
//  AppDelegate.m
//  digg
//
//  Created by hey on 2024/9/24.
//

#import "AppDelegate.h"
#import "SLTabbarController.h"
#import "SLUser.h"
#import "IQKeyboardManager.h"
// #import "SLWebViewController.h"
// #import "SLWebViewPool.h"
#import <UMCommon/UMCommon.h>
// #import <WebKit/WebKit.h>

@interface AppDelegate ()<UIApplicationDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [UMConfigure initWithAppkey:@"680205bdbc47b67d8340d966" channel:@"Internal"];

    [[IQKeyboardManager sharedManager] setEnable:YES];

    [[SLUser defaultUser] loadUserInfoFromLocal];

    // WebView 性能优化：DNS 预解析 + WebView 预热
    // [self performWebViewOptimizations];

    SLTabbarController *rootVC = [[SLTabbarController alloc] init];

    if ([UIApplication sharedApplication].delegate.window == nil) {
        [UIApplication sharedApplication].delegate.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [UIApplication sharedApplication].delegate.window.backgroundColor = [UIColor blackColor];
    }
    [UIApplication sharedApplication].delegate.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}

// - (void)performWebViewOptimizations {
//     // WebView 必须在主线程创建，但延迟执行避免阻塞启动
//     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//         // 1. 预创建 WebView 池（2个实例）
//         [[SLWebViewPool sharedPool] preloadWebViews:2];

//         // 2. 同步全局 Token Cookie
//         [SLWebViewController syncGlobalTokenCookie];

//         NSLog(@"[AppDelegate] WebView 优化完成：池预热 + Cookie 同步");
//     });
// }


@end
