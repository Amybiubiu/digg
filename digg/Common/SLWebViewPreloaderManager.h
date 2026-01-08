#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface SLWebViewPreloaderManager : NSObject

+ (instancetype)shared;
- (WKWebView *)dequeuePreheatedWebViewWithFrame:(CGRect)frame;
- (BOOL)isPreloadReady;

// Token Cookie 工具
+ (NSHTTPCookie *)bpTokenCookieForDomain:(NSString *)domain token:(NSString *)token;
+ (void)injectBpTokenCookie:(NSString *)token
                  forDomain:(NSString *)domain
                  intoStore:(WKHTTPCookieStore *)store
                 completion:(void (^)(void))completion;
+ (void)attachBpTokenHeaderToRequest:(NSMutableURLRequest *)request token:(NSString *)token;

@end
