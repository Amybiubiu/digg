//
//  SLWebViewControllerV2.m
//  digg
//
//  Created by hey on 2024/10/10.
//

#import "SLWebViewControllerV2.h"
#import <Masonry/Masonry.h>
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import <WebKit/WKPreferences.h>
#import "SLGeneralMacro.h"
#import <WebKit/WebKit.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#import "SLGeneralMacro.h"
#import "SLUser.h"
#import "SLProfileViewController.h"
#import "SLRecordViewController.h"
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import "SLTrackingManager.h"
#import "SLCommentInputViewController.h"
#import "NSObject+SLEmpty.h"
#import "SLTagListContainerViewController.h"

@interface SLWebViewControllerV2 ()<UIWebViewDelegate,WKScriptMessageHandler,WKNavigationDelegate,UIScrollViewDelegate>

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

// 控制变量
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) CGFloat navBarHeight;
@property (nonatomic, assign) CGFloat tabBarHeight;
@property (nonatomic, assign) BOOL isNavBarHidden;
@property (nonatomic, assign) BOOL isTabBarHidden;
@property (nonatomic, assign) CGFloat scrollThreshold;
@property (nonatomic, assign) NSTimeInterval lastScrollTime;
@property (nonatomic, assign) CGFloat scrollVelocity;

// webview
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
@property (nonatomic, strong) WKWebView *wkwebView;
@property (nonatomic, assign) BOOL isSetUA;
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;

@end

@implementation SLWebViewControllerV2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    [self setupInitValue];
    [self setupNavigationBar];
    [self setupTabBar];
    
    [self.view addSubview:self.wkwebView];
    [self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationBarView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tabBarView.mas_top);
    }];

    [self setupDefailUA];
    
    if (self.navigationController.interactivePopGestureRecognizer != nil) {
        [self.wkwebView.scrollView.panGestureRecognizer shouldRequireFailureOfGestureRecognizer:self.navigationController.interactivePopGestureRecognizer];
    }
    
    self.commentVC = [[SLCommentInputViewController alloc] init];
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.wkwebView addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[SLTrackingManager sharedInstance] trackPageViewBegin:self uniqueIdentifier:self.requestUrl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[SLTrackingManager sharedInstance] trackPageViewEnd:self uniqueIdentifier:self.requestUrl parameters:nil];
}

- (void)dealloc {
    [self.bridge setWebViewDelegate:nil];
    if ([self isViewLoaded]) {
        [self.wkwebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }

    // if you have set either WKWebView delegate also set these to nil here
    [self.wkwebView setNavigationDelegate:nil];
    [self.wkwebView setUIDelegate:nil];
}

- (void)reload {
    [self.wkwebView reload];
}

- (void)backTo:(BOOL)rootVC {
    NSArray *viewcontrollers = self.navigationController.viewControllers;
    if (viewcontrollers.count > 1) {
        if ([viewcontrollers objectAtIndex:viewcontrollers.count - 1] == self) { //push方式
            if (rootVC) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    else { //present方式
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)jsBridgeMethod {
    @weakobj(self);
    [self.bridge registerHandler:@"backToHomePage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"backToHomePage: %@", data);
        [self backTo:YES];
        self.tabBarController.selectedIndex = 0;
        responseCallback(data);
    }];
    
    [self.bridge registerHandler:@"userLogin" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"userLogin called with: %@", data);

        NSString *userId = [NSString stringWithFormat:@"%@",[data objectForKey:@"userId"]];
        [[SLTrackingManager sharedInstance] setUserId:userId];
        NSString *token = [NSString stringWithFormat:@"%@",[data objectForKey:@"token"]];
        SLUserEntity *entity = [[SLUserEntity alloc] init];
        entity.token = token;
        entity.userId = userId;
        [[SLUser defaultUser] saveUserInfo:entity];
        if (self.loginSucessCallback) {
            self.loginSucessCallback();
        }
        responseCallback(data);
        
        [self backTo:NO];
    }];
    
    [self.bridge registerHandler:@"userLogout" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"userLogout with: %@", data);
        [[SLUser defaultUser] clearUserInfo];
        responseCallback(data);
    }];

    [self.bridge registerHandler:@"page_back" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"page_back = %@",data);
        @strongobj(self);
        [self backTo:NO];
    }];
    
    [self.bridge registerHandler:@"jumpToH5" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"jumpToH5 called with: %@", data);
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            if (self.isLoginPage) {
                [self.navigationController popViewControllerAnimated:NO];
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                NSString *url = [dic objectForKey:@"url"];
                NSString* type = [dic objectForKey:@"pageType"];
                BOOL isJumpToLogin = [type isEqualToString:@"login"];
                BOOL isOuterUrl = [type isEqualToString:@"outer"];
                
                if (isOuterUrl) {
                    SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                   message:nil
                                                       url:[NSURL URLWithString:url]
                                                   urlText:url
                                              confirmTitle:@"是"
                                               cancelTitle:@"否"
                                            confirmHandler:^{
                                                [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_WEB" parameters:@{@"url": url}];
                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
                                            }
                                             cancelHandler:^{
                                            }
                                         fromViewController:nil];
                    [alertView show];
                } else {
                    SLWebViewControllerV2 *dvc = [[SLWebViewControllerV2 alloc] init];
                    [dvc startLoadRequestWithUrl:url];
                    dvc.hidesBottomBarWhenPushed = YES;
                    if (isJumpToLogin) {
                        [self.navigationController presentViewController:dvc animated:YES completion:nil];
                    } else {
                        [self.navigationController pushViewController:dvc animated:YES];
                    }
                }
            });
        }
        responseCallback(data);
    }];
    
    [self.bridge registerHandler:@"closeH5" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"closeH5 called with: %@", data);
        @strongobj(self);
        [self backTo:YES];
    }];
    
    [self.bridge registerHandler:@"openUserPage" handler:^(id data, WVJBResponseCallback responseCallback) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                NSString *uid = [[dic objectForKey:@"uid"] stringValue];
                SLProfileViewController *dvc = [[SLProfileViewController alloc] init];
                dvc.userId = uid;
                dvc.fromWeb = YES;
                [self.navigationController pushViewController:dvc animated:YES];
            });
        }
        responseCallback(data);
    }];
    
    [self.bridge registerHandler:@"openRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                NSString *articleId = [NSString stringWithFormat:@"%@", [dic objectForKey:@"articleId"]];
                NSString *titleText = [NSString stringWithFormat:@"%@", [dic objectForKey:@"title"]];
                NSString *url = [NSString stringWithFormat:@"%@", [dic objectForKey:@"url"]];
                NSString *content = [NSString stringWithFormat:@"%@", [dic objectForKey:@"content"]];
                NSString *htmlContent = [NSString stringWithFormat:@"%@", [dic objectForKey:@"richContent"]];
                NSArray *labels = [dic objectForKey:@"labels"];
                SLRecordViewController *dvc = [[SLRecordViewController alloc] init];
                dvc.articleId = articleId;
                dvc.titleText = titleText;
                dvc.url = url;
                dvc.content = content;
                dvc.htmlContent = htmlContent;
                dvc.labels = labels;
                dvc.isEdit = YES;
                [self.navigationController pushViewController:dvc animated:YES];
            });
        }
        responseCallback(data);
    }];
    [self.bridge registerHandler:@"openCommentInput" handler:^(id data, WVJBResponseCallback responseCallback) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                if (!dic || [dic sl_isEmpty]) {
                    return;
                }

                NSString *placeholder = @"写评论";
                NSObject* placeholderObj = [dic objectForKey:@"placeholder"];
                if (placeholderObj && ![placeholderObj sl_isEmpty]) {
                    placeholder = [NSString stringWithFormat:@"%@", placeholderObj];
                }

                NSString *lastInput = @"";
                NSObject* placeholderObj2 = [dic objectForKey:@"lastInput"];
                if (placeholderObj2 && ![placeholderObj2 sl_isEmpty]) {
                    lastInput = [NSString stringWithFormat:@"%@", placeholderObj2];
                }
                
                // 创建评论输入控制器
                self.commentVC.placeholder = placeholder;
                self.commentVC.textView.text = lastInput;
                self.commentVC.placeholderLabel.hidden = lastInput.length > 0;
                __weak typeof(self) weakSelf = self;
                self.commentVC.submitHandler = ^(NSString *comment) {
                    // 调用前端onCommentInputClose方法，传递评论内容和动作类型
                    NSString *action = comment.length > 0 ? @"send" : @"close";
                    
                    // 使用WebViewJavascriptBridge调用注册的处理程序，而不是直接调用window上的方法
                    NSDictionary *params = @{
                        @"content": comment ?: @"",
                        @"action": action
                    };
                    
                    [weakSelf.bridge callHandler:@"onCommentInputClose" data:params responseCallback:^(id responseData) {
                        NSLog(@"onCommentInputClose 回调结果: %@", responseData);
                    }];
                };
                
                // 添加取消回调
                self.commentVC.cancelHandler = ^(NSString *comment) {
                    NSDictionary *params = @{
                        @"content": comment ?: @"",
                        @"action": @"close"
                    };
                    
                    [weakSelf.bridge callHandler:@"onCommentInputClose" data:params responseCallback:^(id responseData) {
                        NSLog(@"onCommentInputClose 取消回调结果: %@", responseData);
                    }];
                };
                
                [self.commentVC showInViewController:self];
            });
        }
        responseCallback(data);
    }];
    
    [self.bridge registerHandler:@"openTagDetail" handler:^(id data, WVJBResponseCallback responseCallback) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                NSString *tag = [[dic objectForKey:@"tag"] stringValue];
                NSString *url = [[dic objectForKey:@"url"] stringValue];
                SLTagListContainerViewController* vc = [SLTagListContainerViewController new];
                vc.label = tag;
                vc.articleId = url;
                vc.source = @"article";
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            });
        }
        responseCallback(data);
    }];
}

#pragma mark - 按钮事件

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
    [self.wkwebView reload];
}

- (void)exportButtonTapped {
    // 实现导出功能
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"保存为 PDF" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"分享链接" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)setupInitValue {
    UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.allObjects.firstObject;
    self.navBarHeight = 44.0 + windowScene.statusBarManager.statusBarFrame.size.height;
    self.tabBarHeight = 49.0 + kiPhoneXBottomMargin;
    self.isNavBarHidden = NO;
    self.isTabBarHidden = NO;
    self.scrollThreshold = 20.0;
    self.lastScrollTime = 0;
}

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
    self.favoriteButton = [self createTabBarButtonWithImage:@"star" title:@"" action:@selector(favoriteButtonTapped)];
    self.replyButton = [self createTabBarButtonWithImage:@"bubble.right" title:@"" action:@selector(replyButtonTapped)];
    self.refreshButton = [self createTabBarButtonWithImage:@"arrow.clockwise" title:@"" action:@selector(refreshButtonTapped)];
    self.exportButton = [self createTabBarButtonWithImage:@"square.and.arrow.up" title:@"" action:@selector(exportButtonTapped)];
    
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

- (void)setupDefailUA {
    if (self.isSetUA) {
        return;
    }
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.wkwebView];
    [self.bridge setWebViewDelegate:self];
    [self jsBridgeMethod];
    
    NSString *defaultUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"digg_default_userAgent"];
    if (stringIsEmpty(defaultUserAgent)) {
        NSString *model = [UIDevice currentDevice].model;
        NSString *systemVersion = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        defaultUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B92", model, systemVersion];
    };
    NSString *modifiedUserAgent = [NSString stringWithFormat:@"%@ infoflow", defaultUserAgent];
    NSLog(@"设置 ua = %@",modifiedUserAgent);
    self.wkwebView.customUserAgent = modifiedUserAgent;
    self.isSetUA = YES;
}

- (void)startLoadRequestWithUrl:(NSString *)url {
    if(stringIsEmpty(url)){
        NSLog(@"url为空");
        @weakobj(self);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"url 为空" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongobj(self);
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];

        
        return;
    }
    [self setupDefailUA];
    self.requestUrl = url;
    NSLog(@"加载的url = %@",url);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self addThemeToURL:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [self.wkwebView loadRequest:request];
}

- (NSURL *)addThemeToURL:(NSString *)url {
    NSString *themeParam = @"theme=light";
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        themeParam = @"theme=dark";
    }

    // 处理URL，添加theme参数
    NSURL *originalURL = [NSURL URLWithString:url];
    NSURLComponents *components = [NSURLComponents componentsWithURL:originalURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray *queryItems = [NSMutableArray array];
    if (components.queryItems) {
        [queryItems addObjectsFromArray:components.queryItems];
    }
    
    // 检查是否已有theme参数
    BOOL hasThemeParam = NO;
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"theme"]) {
            hasThemeParam = YES;
            break;
        }
    }
    
    // 如果没有theme参数，添加一个
    if (!hasThemeParam) {
        NSArray *themeComponents = [themeParam componentsSeparatedByString:@"="];
        if (themeComponents.count == 2) {
            NSURLQueryItem *themeItem = [NSURLQueryItem queryItemWithName:themeComponents[0] value:themeComponents[1]];
            [queryItems addObject:themeItem];
        }
    }
    
    components.queryItems = queryItems;
    NSURL *finalURL = components.URL;
    
    // 如果URL处理失败，使用原始URL
    if (!finalURL) {
        finalURL = originalURL;
    }
    return finalURL;
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

// 根据最终速度决定导航栏和底部工具栏的最终状态
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

#pragma mark - WKWebView

- (WKWebView *)wkwebView{
    if (!_wkwebView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        configuration.preferences = preferences;
        configuration.allowsInlineMediaPlayback = YES;
        
        
        _wkwebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _wkwebView.backgroundColor = [UIColor clearColor];
        [_wkwebView setOpaque:NO];
        _wkwebView.scrollView.bounces = NO;
        _wkwebView.navigationDelegate = self;
        _wkwebView.scrollView.delegate = self;
        _wkwebView.allowsBackForwardNavigationGestures = YES;
        [_wkwebView.scrollView.panGestureRecognizer setEnabled:YES];
    }
    return _wkwebView;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"js bridge message =%@",message.name);
}

@end
