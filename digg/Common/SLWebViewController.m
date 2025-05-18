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

@interface SLWebViewController ()<UIWebViewDelegate,WKScriptMessageHandler,WKNavigationDelegate>
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
@property (nonatomic, strong) WKWebView *wkwebView;
@property (nonatomic, assign) BOOL isSetUA;
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) UIProgressView* progressView;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;

@end

@implementation SLWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    [self setupDefailUA];
    
    if (self.navigationController.interactivePopGestureRecognizer != nil) {
        [self.wkwebView.scrollView.panGestureRecognizer shouldRequireFailureOfGestureRecognizer:self.navigationController.interactivePopGestureRecognizer];
    }
    
    self.commentVC = [[SLCommentInputViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isShowProgress) {
        self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
        self.navigationController.navigationBar.hidden = NO;
    }
    [[SLTrackingManager sharedInstance] trackPageViewBegin:self uniqueIdentifier:self.requestUrl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isShowProgress) {
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.hidden = YES;
    }
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
        _wkwebView.allowsBackForwardNavigationGestures = YES;
        [_wkwebView.scrollView.panGestureRecognizer setEnabled:YES];
    }
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
