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
#import "SLWebViewPool.h"


@interface SLWebViewController ()<UIWebViewDelegate,WKScriptMessageHandler,WKNavigationDelegate>
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
@property (nonatomic, strong) WKWebView *wkwebView;
@property (nonatomic, assign) BOOL isSetUA;
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) UIProgressView* progressView;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;

// 性能监控
@property (nonatomic, assign) NSTimeInterval loadStartTime;
@property (nonatomic, assign) NSTimeInterval requestStartTime;

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

// 同步全局 Token Cookie
+ (void)syncGlobalTokenCookie {
    static NSString *_lastSyncedToken = nil;

    NSString *token = [SLUser defaultUser].userEntity.token;

    // 如果没有 token 或 token 没变化，不需要重新注入
    if (stringIsEmpty(token) || [token isEqualToString:_lastSyncedToken]) {
        return;
    }

    // 注入 Cookie 到全局 store (异步，但不阻塞后续操作)
    WKHTTPCookieStore *cookieStore = [WKWebsiteDataStore defaultDataStore].httpCookieStore;

    // 为常用域名注入 Cookie
    NSArray *domains = @[
        @"39.106.147.0",  // H5 域名
        @"47.96.25.87"    // API 域名
    ];

    for (NSString *domain in domains) {
        NSMutableDictionary *cookieProps = [NSMutableDictionary dictionary];
        cookieProps[NSHTTPCookieName] = @"bp-token";
        cookieProps[NSHTTPCookieValue] = token;
        cookieProps[NSHTTPCookieDomain] = domain;
        cookieProps[NSHTTPCookiePath] = @"/";
        cookieProps[NSHTTPCookieExpires] = [[NSDate date] dateByAddingTimeInterval:31536000];

        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProps];

        [cookieStore setCookie:cookie completionHandler:^{
            NSLog(@"[SLWebViewController] 全局 Cookie 已同步到域名: %@", domain);
        }];
    }

    _lastSyncedToken = token;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认允许复用 WebView（可被子类覆盖）
        _shouldReuseWebView = YES;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 默认允许复用 WebView（可被子类覆盖）
        _shouldReuseWebView = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSLog(@"🔵 [DEBUG] viewDidLoad - URL: %@, shouldReuseWebView: %d, WebView exists: %d",
          self.requestUrl ?: @"nil", self.shouldReuseWebView, self.wkwebView != nil);

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
            make.edges.equalTo(self.view);
        }];
    }

    // 移除这里的 Bridge 初始化，改为延迟初始化（在真正需要时才初始化）
    // [self setupDefailUA];

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSLog(@"🟢🟢 [DEBUG] viewDidAppear - WebView: %@, isLoading: %d",
          self.wkwebView ? @"exists" : @"nil",
          self.wkwebView.isLoading);

    // 检查是否需要刷新，如果需要则调用刷新逻辑
    if (self.needsRefresh) {
        [self sendRefreshPageDataMessage];
        self.needsRefresh = NO;
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
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    BOOL isInStack = [self.navigationController.viewControllers containsObject:self];
    NSLog(@"🟡🟡 [DEBUG] viewDidDisappear - URL: %@, WebView: %@, shouldReuse: %d, inStack: %d",
          self.requestUrl ?: @"nil",
          self.wkwebView ? @"exists" : @"nil",
          self.shouldReuseWebView,
          isInStack);

    // 对于使用池的页面，延迟回收（既避免转场动画问题，又能及时回收）
    if (self.shouldReuseWebView && !isInStack && self.wkwebView) {
        NSLog(@"⏳ [DEBUG] 页面已移除，0.5秒后回收 WebView");

        // 延迟 0.5 秒回收，确保转场动画完全结束
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            // 再次检查是否还不在栈中（防止被重新加入）
            BOOL stillNotInStack = ![strongSelf.navigationController.viewControllers containsObject:strongSelf];
            if (stillNotInStack && strongSelf.wkwebView) {
                NSLog(@"♻️ [DEBUG] 延迟回收：归还 WebView 到池中");
                [[SLWebViewPool sharedPool] enqueueWebView:strongSelf.wkwebView];
                strongSelf->_wkwebView = nil;
            } else {
                NSLog(@"🔄 [DEBUG] 延迟回收：页面重新进入栈或 WebView 已回收，跳过");
            }
        });
    } else {
        NSLog(@"🔒 [DEBUG] 保留 WebView (shouldReuse: %d, inStack: %d)", self.shouldReuseWebView, isInStack);
    }
}

// 内存警告时释放不可见页面的 WebView
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // 更保守的策略：只有页面已从导航栈移除时才回收，避免手势返回白屏
    // 如果页面还在栈中（用户可能返回），保留 WebView
    BOOL isInNavigationStack = [self.navigationController.viewControllers containsObject:self];

    if (self.shouldReuseWebView && !isInNavigationStack && self.wkwebView) {
        NSLog(@"[SLWebViewController] 收到内存警告且页面已移除，释放 WebView");
        [[SLWebViewPool sharedPool] enqueueWebView:self.wkwebView];
        _wkwebView = nil;
    } else if (self.wkwebView) {
        NSLog(@"[SLWebViewController] 收到内存警告但页面仍在导航栈中，保留 WebView");
    }
}

- (void)dealloc {
    NSLog(@"[SLWebViewController] dealloc 被调用，准备归还 WebView");

    [self.bridge setWebViewDelegate:nil];
    if ([self isViewLoaded] && self.isShowProgress) {
        @try {
            [self.wkwebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
        } @catch (NSException *exception) {
            NSLog(@"[SLWebViewController] 移除观察者异常: %@", exception);
        }
    }

    // 清理 delegate
    [self.wkwebView setNavigationDelegate:nil];
    [self.wkwebView setUIDelegate:nil];

    // 归还 WebView 到池中复用
    if (self.shouldReuseWebView && self.wkwebView) {
        NSLog(@"[SLWebViewController] 归还 WebView 到池中");
        [[SLWebViewPool sharedPool] enqueueWebView:self.wkwebView];
        _wkwebView = nil;
    }
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
    } else {
        // 如果视图还没准备好，标记为需要刷新，在viewDidAppear时再执行
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
        // 等待cookie注入完成后再加载
        WKHTTPCookieStore *cookieStore = self.wkwebView.configuration.websiteDataStore.httpCookieStore;

        NSMutableDictionary *cookieProps = [NSMutableDictionary dictionary];
        cookieProps[NSHTTPCookieName] = @"bp-token";
        cookieProps[NSHTTPCookieValue] = token;
        cookieProps[NSHTTPCookieDomain] = [NSURL URLWithString:self.requestUrl].host;
        cookieProps[NSHTTPCookiePath] = @"/";
        cookieProps[NSHTTPCookieExpires] = [[NSDate date] dateByAddingTimeInterval:31536000];

        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProps];

        [cookieStore setCookie:cookie completionHandler:^{
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

    // 构造 bp-token Cookie
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:@"bp-token" forKey:NSHTTPCookieName]; // 你的 Key
    [cookieProperties setObject:token forKey:NSHTTPCookieValue];      // 你的 Token 值
    [cookieProperties setObject:domain forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    // 设置过期时间为1年后，防止 Session 过期
    [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:31536000] forKey:NSHTTPCookieExpires];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    
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

        // 立即同步全局 Cookie
        [[self class] syncGlobalTokenCookie];

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
}
- (void)setupDefailUA{
    if (self.isSetUA) {
        return;
    }

    // 初始化 JS Bridge（耗时操作，但必需）
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.wkwebView];
    [self.bridge setWebViewDelegate:self];
    [self jsBridgeMethod];

    // UA 已在 WebView 创建时设置，无需重复设置
    // （从池中获取的 WebView 已经有正确的 UA）

    self.isSetUA = YES;
    NSLog(@"[SLWebViewController] Bridge 初始化完成");
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

    // 不在这里初始化 Bridge，避免阻塞页面加载
    // Bridge 将在页面加载完成后异步初始化

    self.requestUrl = url;

    // 记录加载开始时间
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    self.loadStartTime = startTime;
    NSLog(@"[性能] ========== 开始加载页面 ==========");
    NSLog(@"[性能] URL: %@", url);
    NSLog(@"[性能] shouldReuseWebView: %d", self.shouldReuseWebView);

    // 获取 WebView（可能从池中获取或创建新的）
    NSTimeInterval beforeWebView = [[NSDate date] timeIntervalSince1970];
    WKWebView *webView = self.wkwebView;
    NSTimeInterval afterWebView = [[NSDate date] timeIntervalSince1970];
    NSLog(@"[性能] ⏱ 获取 WebView 耗时: %.0fms", (afterWebView - beforeWebView) * 1000);

    // 同步全局 Cookie（异步但不阻塞）
    NSTimeInterval beforeCookie = [[NSDate date] timeIntervalSince1970];
    [[self class] syncGlobalTokenCookie];
    NSTimeInterval afterCookie = [[NSDate date] timeIntervalSince1970];
    NSLog(@"[性能] ⏱ Cookie 同步耗时: %.0fms", (afterCookie - beforeCookie) * 1000);

    // 如果使用 WebView 池，可能有旧内容，先隐藏避免闪现
    if (self.shouldReuseWebView && webView.URL && ![webView.URL.absoluteString isEqualToString:@"about:blank"]) {
        webView.hidden = YES;
        NSLog(@"[性能] ⚠️ WebView 有旧内容，先隐藏: %@", webView.URL);
    }

    // 构建请求
    NSTimeInterval beforeRequest = [[NSDate date] timeIntervalSince1970];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self addThemeToURL:url]
                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:30];
    NSTimeInterval afterRequest = [[NSDate date] timeIntervalSince1970];
    NSLog(@"[性能] ⏱ 构建请求耗时: %.0fms", (afterRequest - beforeRequest) * 1000);

    // 发起加载
    NSTimeInterval beforeLoad = [[NSDate date] timeIntervalSince1970];
    [webView loadRequest:request];
    NSTimeInterval afterLoad = [[NSDate date] timeIntervalSince1970];
    NSLog(@"[性能] ⏱ 调用 loadRequest 耗时: %.0fms", (afterLoad - beforeLoad) * 1000);

    NSTimeInterval totalPrep = afterLoad - startTime;
    NSLog(@"[性能] ⏱ 总准备时间: %.0fms", totalPrep * 1000);
    NSLog(@"[性能] ========================================");
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
        // 如果不允许复用（常驻页面），每次都创建新的 WebView
        if (!self.shouldReuseWebView) {
            _wkwebView = [self createNewWebView];
            NSLog(@"🆕 [DEBUG] 常驻页面，创建独立 WebView - URL: %@", self.requestUrl ?: @"nil");
        } else {
            // 从池中获取 WebView，大幅提升性能
            _wkwebView = [[SLWebViewPool sharedPool] dequeueWebView];
            NSLog(@"♻️ [DEBUG] 从池中获取 WebView - URL: %@, WebView URL: %@",
                  self.requestUrl ?: @"nil",
                  _wkwebView.URL ?: @"nil");
        }

        // 设置 delegate（每次使用时都需要设置）
        _wkwebView.navigationDelegate = self;
        [_wkwebView.scrollView.panGestureRecognizer setEnabled:YES];
    }
    // 移除了 else 分支中的日志，减少日志噪音
    return _wkwebView;
}

- (WKWebView *)createNewWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];

    // 共享进程池和数据存储
    configuration.processPool = [[self class] sharedProcessPool];
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    configuration.allowsInlineMediaPlayback = YES;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webView.backgroundColor = [UIColor clearColor];
    [webView setOpaque:NO];
    webView.scrollView.bounces = YES;
    webView.allowsBackForwardNavigationGestures = YES;

    // 提前设置 UA（避免每次使用都设置）
    NSString *defaultUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"digg_default_userAgent"];
    if (!defaultUserAgent || defaultUserAgent.length == 0) {
        NSString *model = [UIDevice currentDevice].model;
        NSString *systemVersion = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        defaultUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B92", model, systemVersion];
    }
    NSString *modifiedUserAgent = [NSString stringWithFormat:@"%@ infoflow", defaultUserAgent];
    webView.customUserAgent = modifiedUserAgent;

    // Enable Web Inspector for iOS 16.4+
    if (@available(iOS 16.4, *)) {
        webView.inspectable = YES;
    }

    NSLog(@"[SLWebViewController] 创建独立 WebView，已设置 UA");
    return webView;
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

#pragma mark - WKNavigationDelegate
// 开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.requestStartTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLoad = self.requestStartTime - self.loadStartTime;
    NSLog(@"[性能] 开始请求网络 (+%.0fms)", timeSinceLoad * 1000);
}

// 接收到响应
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval requestTime = now - self.requestStartTime;
    NSTimeInterval totalTime = now - self.loadStartTime;
    NSLog(@"[性能] 收到服务器响应 (+%.0fms，总计%.0fms)", requestTime * 1000, totalTime * 1000);
}

// 加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval renderTime = now - self.requestStartTime;
    NSTimeInterval totalTime = now - self.loadStartTime;

    NSLog(@"[性能] ========== 页面加载完成 ==========");
    NSLog(@"[性能] ✅ 渲染耗时: %.0fms", renderTime * 1000);
    NSLog(@"[性能] ✅ 总计耗时: %.0fms", totalTime * 1000);
    NSLog(@"[性能] URL: %@", webView.URL);

    // 显示 WebView（可能之前被隐藏了）
    if (webView.hidden) {
        NSTimeInterval beforeShow = [[NSDate date] timeIntervalSince1970];
        webView.hidden = NO;
        NSTimeInterval afterShow = [[NSDate date] timeIntervalSince1970];
        NSLog(@"[性能] 👁 显示 WebView 耗时: %.0fms", (afterShow - beforeShow) * 1000);
    }

    NSLog(@"[性能] ========================================");

    if (self.isShowProgress) {
        @weakobj(self);
        [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError* _Nullable error) {
            if (!error && [title length] > 0) {
                @strongobj(self);
                self.title = title;
            }
        }];
    }

    // 页面加载完成后，异步初始化 Bridge（不阻塞主线程）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupDefailUA];
        });
    });
}

// 加载失败
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSTimeInterval totalTime = [[NSDate date] timeIntervalSince1970] - self.loadStartTime;
    NSLog(@"[性能] ❌ 页面加载失败 (总计%.0fms): %@", totalTime * 1000, error.localizedDescription);

    // 即使加载失败也显示 WebView
    if (webView.hidden) {
        webView.hidden = NO;
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSTimeInterval totalTime = [[NSDate date] timeIntervalSince1970] - self.loadStartTime;
    NSLog(@"[性能] ❌ 请求失败 (总计%.0fms): %@", totalTime * 1000, error.localizedDescription);
}

@end
