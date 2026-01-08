#import "SLWebViewPreloaderManager.h"
#import "SLWebViewController.h"
#import "EnvConfigHeader.h"
#import "SLUser.h"

@interface SLWebViewPreloaderManager () <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *preloadedWebView;
@property (nonatomic, assign) BOOL isPreloading;
@property (nonatomic, assign) BOOL preloadCompleted;
@end

@implementation SLWebViewPreloaderManager

+ (instancetype)shared {
    static SLWebViewPreloaderManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[SLWebViewPreloaderManager alloc] init];
        [mgr startPreloadingIfNeeded];
    });
    return mgr;
}

- (WKWebView *)dequeuePreheatedWebViewWithFrame:(CGRect)frame {
    if (self.preloadedWebView && self.preloadCompleted) {
        WKWebView *webView = self.preloadedWebView;
        self.preloadedWebView = nil;
        self.preloadCompleted = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startPreloadingIfNeeded];
        });
        webView.frame = frame;
        return webView;
    } else {
        WKWebViewConfiguration *configuration = [self createDefaultConfiguration];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
        return webView;
    }
}

- (BOOL)isPreloadReady {
    return self.preloadCompleted && self.preloadedWebView != nil;
}

- (void)startPreloadingIfNeeded {
    if (self.isPreloading || self.preloadCompleted || self.preloadedWebView != nil) {
        return;
    }
    self.isPreloading = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        WKWebViewConfiguration *configuration = [self createDefaultConfiguration];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        webView.navigationDelegate = self;
        
        NSString *token = [SLUser defaultUser].userEntity.token;
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
        if (token.length > 0) {
            WKHTTPCookieStore *cookieStore = webView.configuration.websiteDataStore.httpCookieStore;
            NSString *domain = [NSURL URLWithString:H5BaseUrl].host;
            NSMutableDictionary *cookieProps = [NSMutableDictionary dictionary];
            cookieProps[NSHTTPCookieName] = @"bp-token";
            cookieProps[NSHTTPCookieValue] = token;
            cookieProps[NSHTTPCookieDomain] = domain ?: @"";
            cookieProps[NSHTTPCookiePath] = @"/";
            cookieProps[NSHTTPCookieExpires] = [[NSDate date] dateByAddingTimeInterval:31536000];
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProps];
            [cookieStore setCookie:cookie completionHandler:^{
                [webView loadRequest:req];
            }];
        } else {
            [webView loadRequest:req];
        }
        self.preloadedWebView = webView;
    });
}

- (WKWebViewConfiguration *)createDefaultConfiguration {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.processPool = [SLWebViewController sharedProcessPool];
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    if (@available(iOS 13.0, *)) {
        WKWebpagePreferences *pagePrefs = [[WKWebpagePreferences alloc] init];
        pagePrefs.preferredContentMode = WKContentModeMobile;
        configuration.defaultWebpagePreferences = pagePrefs;
    }
    return configuration;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([webView.URL.absoluteString isEqualToString:@"about:blank"]) {
        self.preloadCompleted = YES;
        self.isPreloading = NO;
    }
}

@end
