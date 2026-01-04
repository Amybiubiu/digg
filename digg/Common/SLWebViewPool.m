//
//  SLWebViewPool.m
//  digg
//

#import "SLWebViewPool.h"
#import "SLWebViewController.h"

@interface SLWebViewPool ()
@property (nonatomic, strong) NSMutableArray<WKWebView *> *availableWebViews;
@property (nonatomic, strong) dispatch_queue_t poolQueue;
@property (nonatomic, assign) NSInteger maxPoolSize;
@end

@implementation SLWebViewPool

+ (instancetype)sharedPool {
    static SLWebViewPool *_sharedPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPool = [[SLWebViewPool alloc] init];
    });
    return _sharedPool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _availableWebViews = [NSMutableArray array];
        _poolQueue = dispatch_queue_create("com.digg.webview.pool", DISPATCH_QUEUE_SERIAL);
        _maxPoolSize = 3; // 最多保留 3 个 WebView
    }
    return self;
}

- (WKWebView *)dequeueWebView {
    __block WKWebView *webView = nil;
    __block BOOL fromPool = NO;

    dispatch_sync(self.poolQueue, ^{
        if (self.availableWebViews.count > 0) {
            webView = [self.availableWebViews firstObject];
            [self.availableWebViews removeObjectAtIndex:0];
            fromPool = YES;
            NSLog(@"[WebViewPool] ✅ 从池中复用 WebView，剩余: %lu", (unsigned long)self.availableWebViews.count);
        }
    });

    if (!webView) {
        // 池中没有，创建新的
        NSLog(@"[WebViewPool] 🆕 池中无可用 WebView，创建新实例");
        webView = [self createNewWebView];
    } else {
        // 从池中获取的 WebView，重新显示
        webView.hidden = NO;
    }

    return webView;
}

- (void)enqueueWebView:(WKWebView *)webView {
    if (!webView) return;

    dispatch_async(self.poolQueue, ^{
        // 检查池是否已满
        if (self.availableWebViews.count >= self.maxPoolSize) {
            NSLog(@"[WebViewPool] 池已满，丢弃 WebView");
            return;
        }

        // 清理 WebView 状态（但保留 UA 和 Bridge）
        dispatch_async(dispatch_get_main_queue(), ^{
            [webView stopLoading];

            // 隐藏 WebView，避免在清空时显示内容
            webView.hidden = YES;

            // 清空内容
            [webView loadHTMLString:@"<html></html>" baseURL:nil];

            // 只清理 delegate，不清理 customUserAgent 和 bridge
            webView.navigationDelegate = nil;
            webView.UIDelegate = nil;

            dispatch_async(self.poolQueue, ^{
                [self.availableWebViews addObject:webView];
                NSLog(@"[WebViewPool] WebView 已归还到池（保留 UA 和配置），当前数量: %lu", (unsigned long)self.availableWebViews.count);
            });
        });
    });
}

- (void)preloadWebViews:(NSInteger)count {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[WebViewPool] 预热：创建 %ld 个 WebView", (long)count);
        for (NSInteger i = 0; i < count; i++) {
            WKWebView *webView = [self createNewWebView];
            [self enqueueWebView:webView];
        }
    });
}

- (WKWebView *)createNewWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];

    // 共享进程池和数据存储
    configuration.processPool = [SLWebViewController sharedProcessPool];
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    configuration.allowsInlineMediaPlayback = YES;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webView.backgroundColor = [UIColor clearColor];
    [webView setOpaque:NO];
    webView.scrollView.bounces = NO;
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

    NSLog(@"[WebViewPool] 创建 WebView，已设置 UA: %@", modifiedUserAgent);
    return webView;
}

@end
