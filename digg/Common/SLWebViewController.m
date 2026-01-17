//
//  SLWebViewController.m
//  digg
//
//  Created by hey on 2024/10/10.
//

#import "SLWebViewController.h"
#import <Masonry/Masonry.h>
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import <WebKit/WKPreferences.h>
#import <WebKit/WKWebsiteDataStore.h>
#import <WebKit/WKHTTPCookieStore.h>
#import "SLGeneralMacro.h"
#import <WebKit/WebKit.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#import "SLGeneralMacro.h"
#import "SLUser.h"
#import "SLRecordViewController.h"
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import "SLCommentInputViewController.h"
#import "NSObject+SLEmpty.h"
#import "SLWebViewPreloaderManager.h"
#import <StoreKit/StoreKit.h>


@interface SLWebViewController ()<UIWebViewDelegate,WKScriptMessageHandler,WKNavigationDelegate>
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
@property (nonatomic, strong) WKWebView *wkwebView;
@property (nonatomic, assign) BOOL isSetUA;
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) UIProgressView* progressView;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;
@property (nonatomic, assign) NSTimeInterval lastAppearTime; // 上次显示的时间戳
@property (nonatomic, assign) BOOL needReload; // 记录更新后需要刷新的标志

@end

@implementation SLWebViewController

// 获取全局共享的 ProcessPool
+ (WKProcessPool *)sharedProcessPool {
    static WKProcessPool *_sharedPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPool = [[WKProcessPool alloc] init];
    });
    return _sharedPool;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSLog(@"🔵 [DEBUG] viewDidLoad - URL: %@, shouldReuseWebView: %d, WebView exists: %d",
          self.requestUrl ?: @"nil", self.shouldReuseWebView, self.wkwebView != nil);

    // 设置默认值
    if (self.refreshInterval == 0) {
        self.refreshInterval = 300; // 默认5分钟
    }

    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];;
    [self.view addSubview:self.wkwebView];

    if (self.isShowProgress) {
        [self.wkwebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.view addSubview:self.progressView];
        [self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.equalTo(self.view);
            make.top.equalTo(self.view).offset(NAVBAR_HEIGHT);
        }];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view).offset(NAVBAR_HEIGHT);
            make.height.equalTo(@2);
        }];
    } else {
        self.navigationController.navigationBar.hidden = YES;
        [self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);

            // 判断是否是Tab页面：如果 hidesBottomBarWhenPushed = NO，说明是Tab常驻页面
            if (!self.hidesBottomBarWhenPushed) {
                // Tab页面：使用安全区域底部，自动适配 TabBar
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            } else {
                // 修复非Tab页面（push进来的页面）；例如详情页；底部过高问题，支持h5 fit：cover模式去自定义安全区高度
                make.bottom.equalTo(self.view);
            }
        }];
    }

    if (self.navigationController.interactivePopGestureRecognizer != nil) {
        [self.wkwebView.scrollView.panGestureRecognizer shouldRequireFailureOfGestureRecognizer:self.navigationController.interactivePopGestureRecognizer];
    }
    
    self.commentVC = [[SLCommentInputViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    BOOL isInStack = [self.navigationController.viewControllers containsObject:self];
    NSInteger stackDepth = self.navigationController.viewControllers.count;

    NSLog(@"🟢 [DEBUG] viewWillAppear - URL: %@, WebView: %@, shouldReuse: %d, inStack: %d, stackDepth: %ld",
          self.requestUrl ?: @"nil",
          self.wkwebView ? [NSString stringWithFormat:@"exists(%@)", self.wkwebView.URL ?: @"no URL"] : @"nil",
          self.shouldReuseWebView,
          isInStack,
          (long)stackDepth);

    // 如果 WebView 被回收了，重新加载（解决手势返回白屏问题）
    if (!self.wkwebView && !stringIsEmpty(self.requestUrl)) {
        NSLog(@"⚠️ [DEBUG] WebView 被回收，重新加载: %@", self.requestUrl);
        [self startLoadRequestWithUrl:self.requestUrl];
    } else if (self.wkwebView) {
        NSLog(@"✅ [DEBUG] WebView 存在，URL: %@", self.wkwebView.URL);
        // WebView 存在时，也需要应用 bounces 设置（处理复用的情况）
        if (!stringIsEmpty(self.requestUrl)) {
            [self applyBouncesSettingFromURL:self.requestUrl];
        }
    } else {
        NSLog(@"❌ [DEBUG] WebView 和 requestUrl 都为空！");
    }

    if (self.isShowProgress) {
        self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
        self.navigationController.navigationBar.hidden = NO;
    }

    // 监听登录后刷新通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadAfterLogin:)
                                                 name:@"WebViewShouldReloadAfterLogin"
                                               object:nil];

    // 监听退出登录后刷新通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadAfterLogout:)
                                                 name:NEUserDidLogoutNotification
                                               object:nil];

    // 监听记录更新后刷新通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appearReload:)
                                                 name:@"RecordDidUpdateNotification"
                                               object:nil];

    // 根据刷新策略决定是否刷新
    [self checkAndRefreshIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSLog(@"🟢🟢 [DEBUG] viewDidAppear - WebView: %@, isLoading: %d",
          self.wkwebView ? @"exists" : @"nil",
          self.wkwebView.isLoading);

    if (self.needsRefresh) {
        [self sendRefreshPageDataMessage];
        self.needsRefresh = NO;
    }

    if(self.needReload){
        [self.wkwebView reload];
        self.needReload = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    BOOL isInStack = [self.navigationController.viewControllers containsObject:self];
    NSLog(@"🟡 [DEBUG] viewWillDisappear - URL: %@, WebView: %@, inStack: %d",
          self.requestUrl ?: @"nil",
          self.wkwebView ? @"exists" : @"nil",
          isInStack);

    if (self.isShowProgress) {
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.hidden = YES;
    }

    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"WebViewShouldReloadAfterLogin" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEUserDidLogoutNotification object:nil];
    // 注意：不移除 RecordDidUpdateNotification，因为需要在页面不可见时也能接收通知
}

- (void)dealloc {
    // 移除所有通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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

- (void)smartRefresh {
    // 只有在webview已经加载且可见的情况下才刷新
    if (self.isViewLoaded && self.view.window) {
        [self refreshCurrentURL];
    }
}

- (void)sendRefreshPageDataMessage {
    NSLog(@"refreshPageData call@");
    // 只有在webview已经加载且可见的情况下才发送刷新消息
    if (self.isViewLoaded && self.view.window) {
        NSLog(@"refreshPageData 消息发送，@");
        // 向H5发送refreshPageData消息
        [self.bridge callHandler:@"refreshPageData" data:nil responseCallback:^(id responseData) {
            NSLog(@"refreshPageData 消息发送成功，H5响应: %@", responseData);
        }];
        // [self.wkwebView reload];
    } else {
        // 如果视图还没准备好，标记为需要刷新，在viewDidAppear时再执行
        self.needsRefresh = YES;
    }
}

// 检查并根据策略决定是否刷新
- (void)checkAndRefreshIfNeeded {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastAppear = currentTime - self.lastAppearTime;

    BOOL shouldRefresh = NO;

    switch (self.refreshPolicy) {
        case SLWebViewRefreshPolicyNone:
            // 不刷新
            NSLog(@"🔄 [REFRESH] 策略: None - 不刷新");
            break;

        case SLWebViewRefreshPolicyAlways:
            // 总是刷新
            NSLog(@"🔄 [REFRESH] 策略: Always - 总是刷新");
            shouldRefresh = YES;
            break;

        case SLWebViewRefreshPolicyInterval:
            // 间隔时间刷新
            if (self.lastAppearTime == 0) {
                // 首次进入，不刷新，只记录时间
                NSLog(@"🔄 [REFRESH] 策略: Interval - 首次进入，不刷新");
            } else if (timeSinceLastAppear >= self.refreshInterval) {
                // 超过间隔时间，需要刷新
                NSLog(@"🔄 [REFRESH] 策略: Interval - 超过间隔(%.0f秒 >= %.0f秒)，需要刷新",
                      timeSinceLastAppear, self.refreshInterval);
                shouldRefresh = YES;
            } else {
                NSLog(@"🔄 [REFRESH] 策略: Interval - 未超过间隔(%.0f秒 < %.0f秒)，不刷新",
                      timeSinceLastAppear, self.refreshInterval);
            }
            break;
    }

    // 更新最后显示时间
    self.lastAppearTime = currentTime;

    // 设置刷新标记，交给 viewDidAppear 统一处理
    if (shouldRefresh) {
        self.needsRefresh = YES;
    }
}

- (void)refreshCurrentURL {
    if (!self.requestUrl || [self.requestUrl length] == 0) {
        return;
    }

    // 使用新的请求重新加载，忽略本地缓存
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self addThemeToURL:self.requestUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];

    // 重新注入token cookie
    NSString *token = [SLUser defaultUser].userEntity.token;
    if (!stringIsEmpty(token)) {
        WKHTTPCookieStore *cookieStore = self.wkwebView.configuration.websiteDataStore.httpCookieStore;
        NSString *domain = [NSURL URLWithString:self.requestUrl].host;
        [SLWebViewPreloaderManager injectBpTokenCookie:token forDomain:domain intoStore:cookieStore completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[SLWebViewController] Cookie已重新注入，使用loadRequest刷新");
                [self.wkwebView loadRequest:request];
            });
        }];
    } else {
        // 没有token时直接加载
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[SLWebViewController] 没有token，直接loadRequest刷新");
            [self.wkwebView loadRequest:request];
        });
    }
}

- (void)reloadAfterLogin:(NSNotification *)notification {
    // 1. 基础校验：如果是登录页本身，或者是未加载的页面，不处理
    if (!self.isViewLoaded || !self.view.window || self.isLoginPage) {
        return;
    }
    
    // 2. 获取当前的 Token (假设存在 SLUser 单例中)
    NSString *token = [SLUser defaultUser].userEntity.token;
    
    // 如果没有 Token，说明是退出登录，直接清除缓存并刷新
    if (stringIsEmpty(token)) {
        [self clearCacheAndReload];
        return;
    }
    
    NSLog(@"[SLWebViewController] 检测到登录，准备注入 Cookie: bp-token");

    // 3. 构造 Cookie (关键步骤)
    // 动态获取当前 URL 的 host，确保 Cookie 种在正确的域名下
    NSURL *currentURL = self.wkwebView.URL ?: [NSURL URLWithString:self.requestUrl];
    NSString *domain = currentURL.host;
    
    if (!domain) {
        [self.wkwebView reload];
        return;
    }

    NSHTTPCookie *cookie = [SLWebViewPreloaderManager bpTokenCookieForDomain:domain token:token];
    
    // 4. 执行核心流程：清缓存 -> 种 Cookie -> 重新 Load
    [self forceSyncCookieAndReload:cookie];
}

// 核心辅助方法 - 修复异步竞争条件
- (void)forceSyncCookieAndReload:(NSHTTPCookie *)cookie {
    // A. 只清理旧Cookie，保留资源缓存以提升性能
    NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeCookies]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{

        // B. 注入新 Cookie
        WKHTTPCookieStore *cookieStore = self.wkwebView.configuration.websiteDataStore.httpCookieStore;

        [cookieStore setCookie:cookie completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[SLWebViewController] 旧Cookie已清理，新Cookie(bp-token)已注入，开始加载");

                // C. 重新加载 - 使用协议缓存策略，利用资源缓存提升速度
                NSString *targetUrl = self.wkwebView.URL.absoluteString ?: self.requestUrl;
                if (targetUrl) {
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:targetUrl]];
                    request.cachePolicy = NSURLRequestUseProtocolCachePolicy;
                    [self.wkwebView loadRequest:request];
                }
            });
        }];
    }];
}

- (void)reloadAfterLogout:(NSNotification *)notification {
    // 1. 基础校验：如果是登录页本身，或者是未加载的页面，不处理
    if (!self.isViewLoaded || !self.view.window || self.isLoginPage) {
        return;
    }

    NSLog(@"[SLWebViewController] 检测到退出登录，准备清除 Cookie 并刷新");

    // 2. 清除 Cookie 并刷新页面
    [self clearCacheAndReload];
}

// 退出登录时用的辅助方法
- (void)clearCacheAndReload {
    // 退出登录只需清理 Cookie，保留资源缓存
    NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeCookies]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.wkwebView reload];
        });
    }];
}

- (void) appearReload:(NSNotification *)notification {
    self.needReload = YES;
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
        NSString *token = [NSString stringWithFormat:@"%@",[data objectForKey:@"token"]];
        SLUserEntity *entity = [[SLUserEntity alloc] init];
        entity.token = token;
        entity.userId = userId;
        [[SLUser defaultUser] saveUserInfo:entity];
        if (self.loginSucessCallback) {
            self.loginSucessCallback();
        }
        responseCallback(data);

        // 发送通知，让其他WebView也刷新
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WebViewShouldReloadAfterLogin" object:nil];

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
                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
                                            }
                                             cancelHandler:^{
                                            }
                                         fromViewController:nil];
                    [alertView show];
                } else {
                    SLWebViewController *dvc = [[SLWebViewController alloc] init];
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
                //TODO:
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
//                dvc.htmlContent = htmlContent;
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
                //TODO:标签详情
            });
        }
        responseCallback(data);
    }];
    
    [self.bridge registerHandler:@"openArticlePage" handler:^(id data, WVJBResponseCallback responseCallback) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;
                NSString *articleId = [[dic objectForKey:@"id"] stringValue];
                //TODO：文章详情
            });
        }
        responseCallback(data);
    }];

    [self.bridge registerHandler:@"requestAppStoreReview" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"requestAppStoreReview called");
        @strongobj(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 14.0, *)) {
                // iOS 14+ 使用 SKStoreReviewController 的新 API
                UIWindowScene *windowScene = nil;
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        windowScene = (UIWindowScene *)scene;
                        break;
                    }
                }

                if (windowScene) {
                    [SKStoreReviewController requestReviewInScene:windowScene];
                    responseCallback(@{@"success": @YES, @"message": @"评分请求已发送"});
                } else {
                    NSLog(@"无法获取 UIWindowScene");
                    responseCallback(@{@"success": @NO, @"message": @"无法获取窗口场景"});
                }
            } else {
                // iOS 10.3 - iOS 13 使用旧 API
                [SKStoreReviewController requestReview];
                responseCallback(@{@"success": @YES, @"message": @"评分请求已发送"});
            }
        });
    }];

    [self.bridge registerHandler:@"openAppStoreReviewPage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"openAppStoreReviewPage called with data: %@", data);
        @strongobj(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            // 从 data 中获取 App Store ID，如果没有提供则使用默认值
            NSString *appId = @"6738596193"; // 默认 App ID
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dic = (NSDictionary *)data;
                NSString *customAppId = [dic objectForKey:@"appId"];
                if (customAppId && ![customAppId isEqual:[NSNull null]] && customAppId.length > 0) {
                    appId = customAppId;
                }
            }

            // 这个页面可以直接由h5 跳转
            // 构造 App Store 评分页面 URL
            NSString *appStoreUrl = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appId];
            NSURL *url = [NSURL URLWithString:appStoreUrl];

            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    if (success) {
                        responseCallback(@{@"success": @YES, @"message": @"已跳转到 App Store"});
                    } else {
                        NSLog(@"跳转 App Store 失败");
                        responseCallback(@{@"success": @NO, @"message": @"跳转失败"});
                    }
                }];
            } else {
                NSLog(@"无法打开 App Store URL: %@", appStoreUrl);
                responseCallback(@{@"success": @NO, @"message": @"无法打开 App Store"});
            }
        });
    }];

    [self.bridge registerHandler:@"toggleTabbarMask" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"toggleTabbarMask called with: %@", data);
        if ([data isKindOfClass:[NSDictionary class]]) {
            @strongobj(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dic = (NSDictionary *)data;

                // 获取 status 参数 (1=显示, 0=隐藏)
                NSNumber *statusNum = [dic objectForKey:@"status"];
                NSInteger status = statusNum ? [statusNum integerValue] : 0;

                // 获取 tabBarController
                UITabBarController *tabBarController = self.tabBarController;
                if (!tabBarController || ![tabBarController respondsToSelector:@selector(showTabbarMaskWithColor:)]) {
                    NSLog(@"⚠️ tabBarController 不支持 mask 控制");
                    responseCallback(@{@"success": @NO, @"message": @"TabBar controller not available"});
                    return;
                }

                if (status == 1) {
                    // 显示遮罩
                    NSString *colorHex = [dic objectForKey:@"color"];
                    UIColor *maskColor = nil;

                    if (colorHex && [colorHex isKindOfClass:[NSString class]] && colorHex.length > 0) {
                        maskColor = [self colorFromHexString:colorHex];
                    }

                    // 如果没有提供颜色或解析失败，使用默认颜色（半透明黑色）
                    if (!maskColor) {
                        maskColor = [UIColor colorWithWhite:0 alpha:0.5];
                    }

                    // 调用 showTabbarMaskWithColor 方法
                    [tabBarController performSelector:@selector(showTabbarMaskWithColor:) withObject:maskColor];
                    responseCallback(@{@"success": @YES, @"message": @"Mask shown"});
                } else {
                    // 隐藏遮罩
                    [tabBarController performSelector:@selector(hideTabbarMask)];
                    responseCallback(@{@"success": @YES, @"message": @"Mask hidden"});
                }
            });
        } else {
            responseCallback(@{@"success": @NO, @"message": @"Invalid data format"});
        }
    }];
}
- (void)setupDefailUA{
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

- (void)ensureUAAndTokenIfNeeded {
    if (!self.isSetUA) {
        [self setupDefailUA];
    }
    NSString *token = [SLUser defaultUser].userEntity.token;
    if (stringIsEmpty(token)) {
        return;
    }
    NSURL *currentURL = self.wkwebView.URL ?: [NSURL URLWithString:self.requestUrl ?: @""];
    NSString *domain = currentURL.host;
    if (stringIsEmpty(domain)) {
        return;
    }
    WKHTTPCookieStore *store = self.wkwebView.configuration.websiteDataStore.httpCookieStore;
    [SLWebViewPreloaderManager injectBpTokenCookie:token forDomain:domain intoStore:store completion:nil];
}

// 将 hex 颜色字符串转换为 UIColor (支持 #RGB, #RRGGBB, #RRGGBBAA)
- (UIColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString || hexString.length == 0) {
        return nil;
    }

    // 移除 # 前缀
    NSString *colorString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];

    unsigned int hex = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    [scanner scanHexInt:&hex];

    CGFloat r, g, b, a = 1.0;

    if (colorString.length == 3) {
        // #RGB 格式
        r = ((hex & 0xF00) >> 8) / 15.0;
        g = ((hex & 0x0F0) >> 4) / 15.0;
        b = (hex & 0x00F) / 15.0;
    } else if (colorString.length == 6) {
        // #RRGGBB 格式
        r = ((hex & 0xFF0000) >> 16) / 255.0;
        g = ((hex & 0x00FF00) >> 8) / 255.0;
        b = (hex & 0x0000FF) / 255.0;
    } else if (colorString.length == 8) {
        // #RRGGBBAA 格式
        r = ((hex & 0xFF000000) >> 24) / 255.0;
        g = ((hex & 0x00FF0000) >> 16) / 255.0;
        b = ((hex & 0x0000FF00) >> 8) / 255.0;
        a = (hex & 0x000000FF) / 255.0;
    } else {
        return nil;
    }

    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

- (void)applyBouncesSettingFromURL:(NSString *)url {
    // 解析 URL 参数
    NSURL *nsurl = [NSURL URLWithString:url];
    if (!nsurl) {
        return;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:nsurl resolvingAgainstBaseURL:NO];
    if (!components.queryItems) {
        return;
    }

    // 查找 bounces 参数
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"bounces"]) {
            // 解析参数值：true/1/yes -> YES, false/0/no -> NO
            NSString *value = [item.value lowercaseString];
            BOOL bounces = YES; // 默认值

            if ([value isEqualToString:@"0"]) {
                bounces = NO;
            } else if ([value isEqualToString:@"1"]) {
                bounces = YES;
            }

            // 应用设置
            self.wkwebView.scrollView.bounces = bounces;
            NSLog(@"从 URL 参数设置 bounces = %@", bounces ? @"YES" : @"NO");
            break;
        }
    }
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
    self.requestUrl = url;
    NSLog(@"加载的url = %@",url);

    // 从 URL 参数中读取 bounces 设置并应用
    [self applyBouncesSettingFromURL:url];

    // 确保在加载 URL 之前设置 UA、bridge 和 token
    [self ensureUAAndTokenIfNeeded];

    NSURL *finalURL = [self addThemeToURL:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:finalURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
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

- (WKWebView *)wkwebView{
    if (!_wkwebView) {
        _wkwebView = [[SLWebViewPreloaderManager shared] dequeuePreheatedWebViewWithFrame:CGRectZero];
        _wkwebView.backgroundColor = [UIColor clearColor];
        [_wkwebView setOpaque:NO];
        _wkwebView.scrollView.bounces = YES; // 默认值
        _wkwebView.navigationDelegate = self;

        // 禁用自动调整内容边距，避免系统自动添加安全区域边距
        // if (@available(iOS 11.0, *)) {
        //     _wkwebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        // }

        // 禁用 WebView 内部的侧滑返回，防止与原生导航控制器的侧滑冲突或历史栈混乱
        _wkwebView.allowsBackForwardNavigationGestures = NO;
        [_wkwebView.scrollView.panGestureRecognizer setEnabled:YES];

        // 确保 Safari 调试器可用
        if (@available(iOS 16.4, *)) {
            _wkwebView.inspectable = YES;
        }

        // 在 WebView 创建后立即设置 UA 和 bridge
        [self setupDefailUA];
    }
    // 移除了 else 分支中的日志，减少日志噪音
    return _wkwebView;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"js bridge message =%@",message.name);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.isShowProgress) {
        if ([keyPath isEqualToString:@"estimatedProgress"]) {
            self.progressView.progress = self.wkwebView.estimatedProgress;
            if (self.wkwebView.estimatedProgress >= 1.0) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.progressView.alpha = 0.0;
                }];
            } else {
                self.progressView.alpha = 1.0;
            }
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

#pragma makr - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.isShowProgress) {
        @weakobj(self);
        [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError* _Nullable error) {
            if (!error && [title length] > 0) {
                @strongobj(self);
                self.title = title;
            }
        }];
    }
}

@end
