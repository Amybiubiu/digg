//
//  SLWebViewPool.h
//  digg
//
//  WebView 池管理器 - 预创建和复用 WebView 实例以提升性能
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLWebViewPool : NSObject

+ (instancetype)sharedPool;

// 获取一个可用的 WebView（如果池中没有则创建新的）
- (WKWebView *)dequeueWebView;

// 归还 WebView 到池中（清理状态后复用）
- (void)enqueueWebView:(WKWebView *)webView;

// 预热：在 App 启动时预创建 WebView
- (void)preloadWebViews:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
