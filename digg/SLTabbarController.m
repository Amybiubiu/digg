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
#import "SLHomeWebViewController.h"
#import "EnvConfigHeader.h"
#import "SLUser.h"
#import "SLGeneralMacro.h"
#import <WebKit/WebKit.h>
#import "SLColorManager.h"
#import "SLWebViewController.h"
#import "SLWebViewPreloaderManager.h"

// --- 自定义 Tab 按钮 ---
@interface SLCustomTabButton : UIButton
@end
@implementation SLCustomTabButton
// 仅仅是为了禁用系统按钮默认的高亮效果，让切换更丝滑
- (void)setHighlighted:(BOOL)highlighted {}
@end
// --------------------

@interface SLTabbarController () <UITabBarControllerDelegate>

@property (nonatomic, strong) SLNavigationController *homeNavi;
@property (nonatomic, strong) SLNavigationController *noticeNavi;
@property (nonatomic, strong) SLNavigationController *recordNavi;
@property (nonatomic, strong) SLRecordViewController *recordVC;
@property (nonatomic, strong) SLNavigationController *mineNavi;
@property (nonatomic, strong) WKWebView *wkWebView;

// 自定义 TabBar 相关的视图
@property (nonatomic, strong) UIView *customTabBarView;
@property (nonatomic, strong) NSMutableArray<SLCustomTabButton *> *tabButtons;

@end

@implementation SLTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1. 基础设置
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    self.delegate = self; // 保持 delegate 以处理登录拦截逻辑
    [SLWebViewPreloaderManager shared];
    
    // 2. 创建子控制器
    [self createTabbarControllers];
    
    // 3. 设置 UA
    [self setDefaultUA];
    
    // 4. 监听登录
    [self noticeUserLogin];
    
    // 5. 初始化自定义 TabBar UI
    // 注意：要在 createTabbarControllers 之后调用
    [self setupCustomTabBarUI];
}

#pragma mark - Custom UI Setup (核心重构部分)

- (void)setupCustomTabBarUI {
    // 1. 处理系统 TabBar
    // 我们保留系统 TabBar 作为容器，这样 hideBottomBarWhenPushed 依然有效。
    // 但是我们要去掉系统自带的分割线和背景，防止干扰。
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithTransparentBackground]; // 透明背景
    appearance.shadowImage = [UIImage new]; // 去掉系统阴影线
    appearance.shadowColor = [UIColor clearColor];
    
    self.tabBar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        self.tabBar.scrollEdgeAppearance = appearance;
    }
    
    // 2. 创建自定义容器 View，覆盖在 self.tabBar 上
    // 这样它的生命周期和 frame 会自动跟随系统 TabBar
    self.customTabBarView = [[UIView alloc] initWithFrame:self.tabBar.bounds];
    self.customTabBarView.backgroundColor = [SLColorManager tabbarBackgroundColor];
    self.customTabBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tabBar addSubview:self.customTabBarView];
    
    // 3. 添加自定义分割线 (顶部细线)
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]; // 分割线颜色
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.customTabBarView addSubview:lineView];
    
    [NSLayoutConstraint activateConstraints:@[
        [lineView.topAnchor constraintEqualToAnchor:self.customTabBarView.topAnchor],
        [lineView.leadingAnchor constraintEqualToAnchor:self.customTabBarView.leadingAnchor],
        [lineView.trailingAnchor constraintEqualToAnchor:self.customTabBarView.trailingAnchor],
        [lineView.heightAnchor constraintEqualToConstant:0.5] // 0.5px 细线
    ]];
    
    // 4. 使用 StackView 实现 "align-items: center" 和 "justify-content: space-around"
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually; // 等分宽度
    stackView.alignment = UIStackViewAlignmentFill; // 垂直填满
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.customTabBarView addSubview:stackView];
    
    // StackView 布局约束：铺满 TabBar (忽略安全区底部，内容自己控制)
    // 注意：tabBar 自身的高度是包含 safeArea 的
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.customTabBarView.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:self.customTabBarView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.customTabBarView.trailingAnchor],
        // 底部需要留出安全区，或者让 StackView 铺满，但按钮内容向上偏移。
        // 更好的做法是：让 StackView 仅仅占据 Top ~ 49pt 的区域
        [stackView.heightAnchor constraintEqualToConstant:49.0]
    ]];

    // 5. 创建按钮
    NSArray *titles = @[@"首页", @"关注", @"发布", @"我的"];
    self.tabButtons = [NSMutableArray array];
    
    for (int i = 0; i < titles.count; i++) {
        SLCustomTabButton *btn = [SLCustomTabButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        
        // 绑定点击事件
        btn.tag = i;
        [btn addTarget:self action:@selector(customTabBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        // 字体和颜色配置
        [btn setTitleColor:Color16(0x999999) forState:UIControlStateNormal];
        [btn setTitleColor:[SLColorManager themeColor] forState:UIControlStateSelected];
        
        // 设置默认字体 (15号)
        btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        
        // --- 核心：Align Items Center ---
        // UIButton 默认就是垂直居中的。
        // 只要 StackView 高度固定(49)，Button 高度也就是 49，
        // titleLabel 就会绝对居中，不需要任何偏移量。
        
        [stackView addArrangedSubview:btn];
        [self.tabButtons addObject:btn];
    }
    
    // 6. 初始化选中状态 (选中第0个)
    [self updateCustomTabBarState:0];
}

// 按钮点击事件
- (void)customTabBtnClicked:(UIButton *)sender {
    NSInteger index = sender.tag;

    // 特殊处理：点击发布按钮(index == 2)时，以全屏modal方式打开
    if (index == 2) {
        [self presentRecordViewController];
        return;
    }

    // 1. 模拟 UITabBarControllerDelegate 的 shouldSelect 检查
    UIViewController *targetVC = self.viewControllers[index];
    BOOL shouldSelect = YES;

    if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        shouldSelect = [self.delegate tabBarController:self shouldSelectViewController:targetVC];
    }

    if (!shouldSelect) {
        return;
    }

    // 2. 切换控制器
    self.selectedIndex = index;

    // 3. 更新 UI 状态
    [self updateCustomTabBarState:index];

    // 4. 刷新首页(0)、关注(1)和我的(3)页面的webview
    if (index == 0 || index == 1 || index == 3) {
        [self refreshWebViewForTab:index];
    }

    // 5. 通知代理 didSelect
    if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [self.delegate tabBarController:self didSelectViewController:targetVC];
    }
}

// 全屏展示发布页面
- (void)presentRecordViewController {
    SLRecordViewController *recordVC = [[SLRecordViewController alloc] init];
    recordVC.modalPresentationStyle = UIModalPresentationFullScreen;
    recordVC.isModalPresentation = YES; // 标记为modal展示

    [self presentViewController:recordVC animated:YES completion:nil];
}

// 更新按钮的字体和颜色状态
- (void)updateCustomTabBarState:(NSInteger)selectedIndex {
    for (int i = 0; i < self.tabButtons.count; i++) {
        UIButton *btn = self.tabButtons[i];
        BOOL isSelected = (i == selectedIndex);

        btn.selected = isSelected;

        if (isSelected) {
            // 选中：16.5 Bold
            btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        } else {
            // 未选中：15 Medium
            btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        }
    }
}

// 覆盖系统 setSelectedIndex 方法，确保代码跳转时（如 push 后返回）UI 也能同步更新
- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    [self updateCustomTabBarState:selectedIndex];
}

#pragma mark - System Logic

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
    
    // 注意：这里不再设置 tabBarItem.title，因为我们有自定义 View 了
    // 保持 tabBarItem 为空，避免系统 TabBar 绘制出重影
    
    SLHomePageViewController *homeVC = [[SLHomePageViewController alloc] init];
    SLNavigationController *homeNavi = [self createRootNavi];
    // 为了占位，保留 item 实例，但不设置 title
    homeNavi.tabBarItem = [[UITabBarItem alloc] init];
    homeNavi.viewControllers = @[homeVC];
    self.homeNavi = homeNavi;

    // 关注
    //  self.noticeVC = [[SLConcernedViewController alloc] init];
    SLWebViewController *noticeVC = [[SLWebViewController alloc] init];
    [noticeVC ensureUAAndTokenIfNeeded];
    noticeVC.shouldReuseWebView = NO; // Tab 常驻页面，禁止回收 WebView
    [noticeVC startLoadRequestWithUrl:FOLLOW_PAGE_URL];
    noticeVC.hidesBottomBarWhenPushed = NO; // 保持 tabbar 显示
    SLNavigationController *noticeNavi = [self createRootNavi];
    self.noticeNavi = noticeNavi;
    noticeNavi.tabBarItem = [[UITabBarItem alloc] init];
    noticeNavi.viewControllers = @[noticeVC];
    noticeVC.navigationController.navigationBar.hidden = YES;

    // 记录
    self.recordVC = [[SLRecordViewController alloc] init];
    SLNavigationController *recordNavi = [self createRootNavi];
    self.recordNavi = recordNavi;
    recordNavi.tabBarItem = [[UITabBarItem alloc] init];
    recordNavi.viewControllers = @[self.recordVC];
    self.recordVC.navigationController.navigationBar.hidden = YES;
    
    // 用户
    SLWebViewController *userVC = [[SLWebViewController alloc] init];
    [userVC ensureUAAndTokenIfNeeded];
    userVC.shouldReuseWebView = NO; // Tab 常驻页面，禁止回收 WebView
    [userVC startLoadRequestWithUrl:MY_PAGE_URL];
    userVC.hidesBottomBarWhenPushed = NO; // 保持 tabbar 显示
    SLNavigationController *userNavi = [self createRootNavi];
    self.mineNavi = userNavi;
    userNavi.tabBarItem = [[UITabBarItem alloc] init];
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
    [dvc startLoadRequestWithUrl:LOGIN_PAGE_URL];
    UINavigationController *currentNav = self.selectedViewController;
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [currentNav presentViewController:dvc animated:YES completion:nil];
}

// 刷新指定tab的webview - 向H5发送refreshPageData消息
- (void)refreshWebViewForTab:(NSInteger)tabIndex {
    UINavigationController *navi = self.viewControllers[tabIndex];
    if (navi && navi.viewControllers.count > 0) {
        UIViewController *topVC = navi.viewControllers[0];
        if (tabIndex == 0 && [topVC isKindOfClass:[SLHomePageViewController class]]) {
            SLHomePageViewController *homeVC = (SLHomePageViewController *)topVC;
            [homeVC refreshCurrentPage];
        } else if ([topVC isKindOfClass:[SLWebViewController class]]) {
            SLWebViewController *webVC = (SLWebViewController *)topVC;
            // 向H5发送refreshPageData消息
            [webVC sendRefreshPageDataMessage];
        }
    }
}

@end
