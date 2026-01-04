#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface SLWebViewPreloaderManager : NSObject

+ (instancetype)shared;
- (WKWebView *)dequeuePreheatedWebViewWithFrame:(CGRect)frame;
- (BOOL)isPreloadReady;

@end
