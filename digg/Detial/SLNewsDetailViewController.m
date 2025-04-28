//
//  SLNewsDetailViewController.m
//  digg
//
//  Created by Tim Bao on 2023/5/20.
//

#import "SLNewsDetailViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@interface SLNewsDetailViewController () <WKNavigationDelegate, UIScrollViewDelegate>

// UI 组件
@property (nonatomic, strong) UIView *navigationBarView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *tabBarView;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIButton *exportButton;

@property (nonatomic, strong) WKWebView *webView;

// 控制变量
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) CGFloat navBarHeight;
@property (nonatomic, assign) CGFloat tabBarHeight;
@property (nonatomic, assign) BOOL isNavBarHidden;
@property (nonatomic, assign) BOOL isTabBarHidden;
@property (nonatomic, assign) CGFloat scrollThreshold;
@property (nonatomic, assign) NSTimeInterval lastScrollTime;
@property (nonatomic, assign) CGFloat scrollVelocity;

@property (nonatomic, assign) BOOL isViewVisible;


@end

@implementation SLNewsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化控制变量
    UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.allObjects.firstObject;
    self.navBarHeight = 44.0 + windowScene.statusBarManager.statusBarFrame.size.height;
    self.tabBarHeight = 49.0 + kiPhoneXBottomMargin;
    self.isNavBarHidden = NO;
    self.isTabBarHidden = NO;
    self.scrollThreshold = 20.0;
    self.lastScrollTime = 0;
    
    // 创建 UI 组件
    [self setupNavigationBar];
    [self setupTabBar];
    [self setupWebView];
    
    // 加载内容
    if (self.newsURL) {
        NSURL *url = [NSURL URLWithString:self.newsURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.webView addGestureRecognizer:tapGesture];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isViewVisible = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isViewVisible = NO;
}

#pragma mark - UI Setup

- (void)setupNavigationBar {
    // 创建导航栏视图
    self.navigationBarView = [[UIView alloc] init];
    self.navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.navigationBarView];
    
    // 设置导航栏阴影
    self.navigationBarView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.navigationBarView.layer.shadowOffset = CGSizeMake(0, 1);
    self.navigationBarView.layer.shadowOpacity = 0.1;
    self.navigationBarView.layer.shadowRadius = 2;
    
    // 设置导航栏约束
    [self.navigationBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@(self.navBarHeight));
    }];
    
    // 返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationBarView addSubview:self.backButton];
    
    // 更多按钮
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationBarView addSubview:self.moreButton];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.newsTitle ?: @"新闻详情";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.navigationBarView addSubview:self.titleLabel];
    
    // 设置导航栏内部组件约束
    UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.allObjects.firstObject;
    CGFloat statusBarHeight = windowScene.statusBarManager.statusBarFrame.size.height;
    
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.navigationBarView).offset(16);
        make.top.equalTo(self.navigationBarView).offset(statusBarHeight + 10);
        make.width.height.equalTo(@24);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationBarView).offset(-16);
        make.top.equalTo(self.navigationBarView).offset(statusBarHeight + 10);
        make.width.height.equalTo(@24);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navigationBarView);
        make.top.equalTo(self.navigationBarView).offset(statusBarHeight + 10);
        make.left.equalTo(self.backButton.mas_right).offset(10);
        make.right.equalTo(self.moreButton.mas_left).offset(-10);
    }];
}

- (void)setupTabBar {
    // 创建底部工具栏视图
    self.tabBarView = [[UIView alloc] init];
    self.tabBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tabBarView];
    
    // 设置底部工具栏阴影
    self.tabBarView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabBarView.layer.shadowOffset = CGSizeMake(0, -1);
    self.tabBarView.layer.shadowOpacity = 0.1;
    self.tabBarView.layer.shadowRadius = 2;
    
    // 设置底部工具栏约束
    [self.tabBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@(self.tabBarHeight));
    }];
    
    // 创建底部工具栏按钮
    self.favoriteButton = [self createTabBarButtonWithImage:@"star" title:@"收藏" action:@selector(favoriteButtonTapped)];
    self.replyButton = [self createTabBarButtonWithImage:@"bubble.right" title:@"回复" action:@selector(replyButtonTapped)];
    self.refreshButton = [self createTabBarButtonWithImage:@"arrow.clockwise" title:@"刷新" action:@selector(refreshButtonTapped)];
    self.exportButton = [self createTabBarButtonWithImage:@"square.and.arrow.up" title:@"导出" action:@selector(exportButtonTapped)];
    
    // 添加按钮到底部工具栏
    [self.tabBarView addSubview:self.favoriteButton];
    [self.tabBarView addSubview:self.replyButton];
    [self.tabBarView addSubview:self.refreshButton];
    [self.tabBarView addSubview:self.exportButton];
    
    // 设置按钮约束
    CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width / 4;
    
    [self.favoriteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tabBarView);
        make.top.equalTo(self.tabBarView);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(self.tabBarView);
    }];
    
    [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.favoriteButton.mas_right);
        make.top.equalTo(self.tabBarView);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(self.tabBarView);
    }];
    
    [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.replyButton.mas_right);
        make.top.equalTo(self.tabBarView);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(self.tabBarView);
    }];
    
    [self.exportButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.refreshButton.mas_right);
        make.top.equalTo(self.tabBarView);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(self.tabBarView);
    }];
}

- (UIButton *)createTabBarButtonWithImage:(NSString *)imageName title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    // 设置图标
    [button setImage:[UIImage systemImageNamed:imageName] forState:UIControlStateNormal];
    
    // 设置标题
    [button setTitle:title forState:UIControlStateNormal];
    
    // 设置图标和标题的位置
    button.titleEdgeInsets = UIEdgeInsetsMake(30, -30, 0, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, -30);
    
    // 设置字体大小
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    
    // 添加点击事件
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)setupWebView {
    // 创建 WKWebView 配置
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    // 创建 WKWebView
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.scrollView.delegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.webView];
    
    // 设置 WKWebView 约束
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationBarView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tabBarView.mas_top);
    }];
}

#pragma mark - 手势处理

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    if (self.isNavBarHidden || self.isTabBarHidden) {
        [self updateBarsPosition:0.0 animated:YES]; // 显示
    } else {
        [self updateBarsPosition:1.0 animated:YES]; // 隐藏
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 计算滚动速度
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - self.lastScrollTime;
    
    if (timeDiff > 0) {
        CGFloat distance = scrollView.contentOffset.y - self.lastContentOffset;
        self.scrollVelocity = fabs(distance / timeDiff);
    }
    
    self.lastScrollTime = currentTime;
    
    // 判断滚动方向和速度
    CGFloat contentOffset = scrollView.contentOffset.y;
    
    // 滚动到顶部时显示导航栏
    if (contentOffset <= 0) {
        [self updateBarsPosition:0.0 animated:NO];
        self.lastContentOffset = contentOffset;
        return;
    }

    // 检测是否滚动到底部
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - 10); // 添加10像素的容差
    
    if (isAtBottom) {
        // 滚动到底部时显示导航栏和底部工具栏
        [self updateBarsPosition:0.0 animated:YES];
        self.lastContentOffset = contentOffset;
        return;
    }
    
    // 计算导航栏和底部工具栏应该移动的距离
    CGFloat maxOffset = self.navBarHeight * 2; // 增加滚动距离，使过渡更平滑
    CGFloat progress = MIN(1.0, MAX(0.0, contentOffset / maxOffset)); // 0.0 到 1.0 之间
    
    // 根据滚动方向调整进度
    CGFloat diff = contentOffset - self.lastContentOffset;
    
    // 移除快速滚动的直接跳变，改为根据滚动方向逐渐调整进度
    CGFloat currentProgress = fabs(self.navigationBarView.frame.origin.y) / self.navBarHeight;
    CGFloat targetProgress = currentProgress;
    
    // 向下滚动（内容向上移动），增加进度（隐藏导航栏）
    if (diff > 0) {
        // 根据滚动速度调整进度增量
        CGFloat increment = MIN(0.05, self.scrollVelocity / 500.0);
        targetProgress = MIN(1.0, currentProgress + increment);
    } 
    // 向上滚动（内容向下移动），减少进度（显示导航栏）
    else if (diff < 0) {
        // 根据滚动速度调整进度减量
        CGFloat decrement = MIN(0.05, self.scrollVelocity / 500.0);
        targetProgress = MAX(0.0, currentProgress - decrement);
    }
    
    // 更新导航栏和底部工具栏位置，使用平滑过渡
    [self updateBarsPosition:targetProgress animated:NO];
    
    self.lastContentOffset = contentOffset;
}

// 修改更新方法，添加平滑过渡
- (void)updateBarsPosition:(CGFloat)progress animated:(BOOL)animated {
    // 计算导航栏应该移动的距离
    CGFloat navBarOffset = -self.navBarHeight * progress;
    CGFloat tabBarOffset = self.tabBarHeight * progress;
    
    // 更新导航栏位置
    [self.navigationBarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(navBarOffset);
    }];
    
    // 更新底部工具栏位置
    [self.tabBarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(tabBarOffset);
    }];
    
    // 更新状态
    self.isNavBarHidden = (progress >= 0.99);
    self.isTabBarHidden = (progress >= 0.99);
    
    if (animated) {
        // 使用弹性动画效果，更接近 Apple News
        [UIView animateWithDuration:0.3 
                              delay:0 
             usingSpringWithDamping:0.8 
              initialSpringVelocity:0.2 
                            options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        [self.view layoutIfNeeded];
    }
}

// 修改滚动结束处理，使其更平滑
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 检测是否滚动到底部
    CGFloat contentOffset = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - 10);
    
    if (isAtBottom) {
        // 滚动到底部时显示导航栏和底部工具栏
        [self updateBarsPosition:0.0 animated:YES];
        return;
    }
    
    if (!decelerate) {
        [self finishScrollingWithVelocity:0];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 检测是否滚动到底部
    CGFloat contentOffset = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - 10);
    
    if (isAtBottom) {
        // 滚动到底部时显示导航栏和底部工具栏
        [self updateBarsPosition:0.0 animated:YES];
        return;
    }
    
    [self finishScrollingWithVelocity:0];
}

// 新增方法：根据最终速度决定导航栏和底部工具栏的最终状态
- (void)finishScrollingWithVelocity:(CGFloat)velocity {
    // 获取当前导航栏的位置
    CGFloat currentProgress = fabs(self.navigationBarView.frame.origin.y) / self.navBarHeight;
    
    // 如果接近某个状态，直接设置为该状态
    if (currentProgress < 0.1) {
        [self updateBarsPosition:0.0 animated:YES]; // 显示
    } else if (currentProgress > 0.9) {
        [self updateBarsPosition:1.0 animated:YES]; // 隐藏
    } else {
        // 如果在中间状态，根据进度决定
        if (currentProgress > 0.5) {
            [self updateBarsPosition:1.0 animated:YES]; // 隐藏
        } else {
            [self updateBarsPosition:0.0 animated:YES]; // 显示
        }
    }
}

#pragma mark - 按钮事件

- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)moreButtonTapped {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"复制链接" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"在浏览器中打开" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)favoriteButtonTapped {
    // 实现收藏功能
    self.favoriteButton.selected = !self.favoriteButton.selected;
    
    if (self.favoriteButton.selected) {
        [self.favoriteButton setImage:[UIImage systemImageNamed:@"star.fill"] forState:UIControlStateNormal];
    } else {
        [self.favoriteButton setImage:[UIImage systemImageNamed:@"star"] forState:UIControlStateNormal];
    }
}

- (void)replyButtonTapped {
    // 实现回复功能
}

- (void)refreshButtonTapped {
    // 实现刷新功能
    [self.webView reload];
}

- (void)exportButtonTapped {
    // 实现导出功能
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"保存为 PDF" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"分享链接" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
