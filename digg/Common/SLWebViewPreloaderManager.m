#import "SLWebViewPreloaderManager.h"
#import "SLWebViewController.h"

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
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
        [webView loadRequest:req];
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
    return configuration;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([webView.URL.absoluteString isEqualToString:@"about:blank"]) {
        self.preloadCompleted = YES;
        self.isPreloading = NO;
    }
}

@end
