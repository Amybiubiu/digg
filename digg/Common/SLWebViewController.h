//
//  SLWebViewController.h
//  digg
//
//  Created by hey on 2024/10/10.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLWebViewController : UIViewController

@property (nonatomic, copy) NSString *uxTitle;
@property (nonatomic, assign) BOOL isShowProgress;
@property (nonatomic, assign) BOOL isLoginPage;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL shouldReuseWebView; // 是否应该复用 WebView（默认 YES）
@property (nonatomic, copy) void(^loginSucessCallback) ();

- (void)startLoadRequestWithUrl:(NSString *)url;

- (void)reload;
- (void)smartRefresh;
- (void)sendRefreshPageDataMessage;
- (void)ensureUAAndTokenIfNeeded;

+ (WKProcessPool *)sharedProcessPool;

@end

NS_ASSUME_NONNULL_END
