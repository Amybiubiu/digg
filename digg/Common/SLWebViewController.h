//
//  SLWebViewController.h
//  digg
//
//  Created by hey on 2024/10/10.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

// 页面刷新策略
typedef NS_ENUM(NSInteger, SLWebViewRefreshPolicy) {
    SLWebViewRefreshPolicyNone = 0,           // 不自动刷新
    SLWebViewRefreshPolicyAlways,             // 每次进入都刷新
    SLWebViewRefreshPolicyInterval            // 间隔时间刷新（默认5分钟）
};

@interface SLWebViewController : UIViewController

@property (nonatomic, copy) NSString *uxTitle;
@property (nonatomic, assign) BOOL isShowProgress;
@property (nonatomic, assign) BOOL isLoginPage;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL shouldReuseWebView; // 是否应该复用 WebView（默认 YES）
@property (nonatomic, copy) void(^loginSucessCallback) ();
@property (nonatomic, assign) SLWebViewRefreshPolicy refreshPolicy; // 刷新策略（默认 None）
@property (nonatomic, assign) NSTimeInterval refreshInterval;       // 刷新间隔（秒），默认 300（5分钟）

- (void)startLoadRequestWithUrl:(NSString *)url;

- (void)reload;
- (void)smartRefresh;
- (void)sendRefreshPageDataMessage;
- (void)clearCacheAndReload;
- (void)ensureUAAndTokenIfNeeded;

+ (WKProcessPool *)sharedProcessPool;

@end

NS_ASSUME_NONNULL_END
