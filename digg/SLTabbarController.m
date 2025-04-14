//
//  SLTabbarController.m
//  digg
//
//  Created by hey on 2024/10/5.
//

#import "SLTabbarController.h"
#import "SLNavigationController.h"
#import "SLHomePageViewController.h"
#import "SLRecordViewController.h"
#import "SLConcernedViewController.h"
#import "SLHomeWebViewController.h"
#import "EnvConfigHeader.h"
#import "SLUser.h"
#import "SLGeneralMacro.h"
#import <WebKit/WebKit.h>
#import "SLProfileViewController.h"
#import "SLColorManager.h"

@interface SLTabbarController () <UITabBarControllerDelegate>

@property (nonatomic, strong) SLNavigationController *homeNavi;
@property (nonatomic, strong) SLNavigationController *noticeNavi;
@property (nonatomic, strong) SLConcernedViewController *noticeVC;
@property (nonatomic, strong) SLNavigationController *recordNavi;
@property (nonatomic, strong) SLRecordViewController *recordVC;
@property (nonatomic, strong) SLNavigationController *mineNavi;
@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation SLTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupTabBarAppearance];

    self.delegate = self;
    
    [self createTabbarControllers];
    [self setDefaultUA];
    [self noticeUserLogin];
}

- (void)setupTabBarAppearance {
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    self.tabBar.backgroundColor = [SLColorManager tabbarBackgroundColor];
    
    [self configureTabBarAppearance:self.tabBar];
}

- (void)configureTabBarAppearance:(UITabBar *)tabBar {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];

    appearance.backgroundColor = [SLColorManager tabbarBackgroundColor];

    UIColor *normalColor = [SLColorManager tabbarNormalTextColor];
    UIColor *selectedColor = [SLColorManager tabbarSelectedTextColor];
    [appearance setStackedLayoutAppearance:[self itemAppearanceWithNormalColor:normalColor selectedColor:selectedColor]];
    
    tabBar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        tabBar.scrollEdgeAppearance = appearance;
    }
}

- (UITabBarItemAppearance *)itemAppearanceWithNormalColor:(UIColor *)normalColor selectedColor:(UIColor *)selectedColor {
    UITabBarItemAppearance *itemAppearance = [[UITabBarItemAppearance alloc] init];
    UIFont *tabBarFont = [UIFont pingFangRegularWithSize:10.0];
    [itemAppearance.normal setTitleTextAttributes:@{
        NSForegroundColorAttributeName: normalColor,
        NSFontAttributeName: tabBarFont
    }];
    [itemAppearance.selected setTitleTextAttributes:@{
        NSForegroundColorAttributeName: selectedColor,
        NSFontAttributeName: tabBarFont
    }];
    return itemAppearance;
}

- (void)setDefaultUA {
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
    [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable defaultUserAgent, NSError * _Nullable error) {
        if (stringIsEmpty(defaultUserAgent)) {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"digg_default_userAgent"];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:defaultUserAgent forKey:@"digg_default_userAgent"];
        }
    }];
}

- (void)noticeUserLogin{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogin:)
                                                 name:NEUserDidLoginNotification
                                               object:nil];
}

- (void)didLogin:(NSNotification *)object {
    BOOL fromLocal = [object.object boolValue];
    if (fromLocal) return;
    //登录成功之后
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)createTabbarControllers{
    self.tabBar.tintColor = [UIColor blackColor];
    
    SLHomePageViewController *homeVC = [[SLHomePageViewController alloc] init];
    SLNavigationController *homeNavi = [self createRootNavi];
    homeNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"首页" image:[UIImage imageNamed:@"home_unsel"] selectedImage:[UIImage imageNamed:@"home_selected"]];
    homeNavi.viewControllers = @[homeVC];
    self.homeNavi = homeNavi;

    self.noticeVC = [[SLConcernedViewController alloc] init];
    SLNavigationController *noticeNavi = [self createRootNavi];
    self.noticeNavi = noticeNavi;
    noticeNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"关注" image:[UIImage imageNamed:@"notice_unsel"] selectedImage:[UIImage imageNamed:@"notice_selected"]];
    noticeNavi.viewControllers = @[self.noticeVC];
    self.noticeVC.navigationController.navigationBar.hidden = YES;

    self.recordVC = [[SLRecordViewController alloc] init];
    SLNavigationController *recordNavi = [self createRootNavi];
    self.recordNavi = recordNavi;
    recordNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"记录" image:[UIImage imageNamed:@"record_unsel"] selectedImage:[UIImage imageNamed:@"record_selected"]];
    recordNavi.viewControllers = @[self.recordVC];
    self.recordVC.navigationController.navigationBar.hidden = YES;
    
    SLProfileViewController *userVC = [[SLProfileViewController alloc] init];
    userVC.userId = [SLUser defaultUser].userEntity.userId;
    SLNavigationController *userNavi = [self createRootNavi];
    self.mineNavi = userNavi;
    userNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"我的" image:[UIImage imageNamed:@"mine_unsel"] selectedImage:[UIImage imageNamed:@"mine_selected"]];
    userNavi.viewControllers = @[userVC];
    userVC.navigationController.navigationBar.hidden = YES;

    self.viewControllers = @[homeNavi, noticeNavi, recordNavi, userNavi];
}

- (SLNavigationController *)createRootNavi{
    SLNavigationController *navi = [[SLNavigationController alloc] init];
    return navi;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    
    if ([viewController isEqual:self.homeNavi]
        || [viewController isEqual:self.mineNavi]
        || [viewController isEqual:self.recordNavi]) {
        return YES;
    } else {
        if (![SLUser defaultUser].isLogin) {
            [self jumpToLogin];
            return NO;
        }
    }
    return YES;
}


- (void)jumpToLogin {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login",H5BaseUrl]];
    UINavigationController *currentNav = self.selectedViewController;
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [currentNav presentViewController:dvc animated:YES completion:nil];
}

@end
