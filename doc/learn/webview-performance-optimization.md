# WebView 性能优化指南

## 问题背景

每次用 WebView 打开 H5 页面，会比 H5 直接在浏览器打开慢很多。

## 性能瓶颈分析

通过分析 `SLWebViewController.m` 的实现，发现以下主要性能问题：

### 1. 缓存策略过于激进

**位置**: `SLWebViewController.m`

- **第560行**: 有 token 时使用 `NSURLRequestReloadIgnoringLocalCacheData`
- **第566行**: 无 token 时使用 `NSURLRequestUseProtocolCachePolicy`
- **第162-164行**: 刷新时使用 `NSURLRequestReloadIgnoringLocalAndRemoteCacheData`

**影响**: 有 token 的情况下每次都忽略本地缓存，导致所有资源（HTML/CSS/JS/图片）都需要重新下载。

### 2. Cookie 异步注入延迟

**位置**: `SLWebViewController.m:557-563`

```objc
[cookieStore setCookie:cookie completionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[SLWebViewController] Token Cookie已注入，开始加载页面");
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self addThemeToURL:url]
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                   timeoutInterval:30];
        [self.wkwebView loadRequest:request];
    });
}];
```

**影响**: 增加 100-300ms 的额外延迟。

### 3. 过度清除缓存

**位置**: `SLWebViewController.m:242-262 (forceSyncCookieAndReload方法)`

```objc
NSSet *websiteDataTypes = [NSSet setWithArray:@[
    WKWebsiteDataTypeDiskCache,
    WKWebsiteDataTypeMemoryCache,
    WKWebsiteDataTypeCookies
]];
[[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes ...];
```

**影响**: 登录后刷新会清除**所有**缓存（内存+磁盘+Cookie），导致登录后第一次加载非常慢。

### 4. WebView 冷启动

每次都创建新的 WebView 实例，需要初始化：
- WebView 本身
- JavaScript 引擎
- WebViewJavascriptBridge
- 10+ 个 JS Bridge Handler

### 5. DNS 查询延迟

没有实现 DNS 预解析，第一次请求需要 DNS 解析时间（100-500ms）。

## 优化方案

### 优先级1: 立即见效（实施难度低）

#### 1. 优化缓存策略

**改进建议**:
- 改用 `NSURLRequestReturnCacheDataElseLoad` (优先使用缓存)
- 或使用 `NSURLRequestUseProtocolCachePolicy` (遵循 HTTP 缓存头)
- 只在必要时才忽略缓存（如用户主动下拉刷新）

**预计提升**: 30-50%

#### 2. DNS 预解析

在 App 启动时预解析 H5 域名：

```objc
WKWebView *dummyWebView = [[WKWebView alloc] init];
[dummyWebView loadHTMLString:@"<html></html>"
                     baseURL:[NSURL URLWithString:H5BaseUrl]];
```

**预计提升**: 5-15%

### 优先级2: 中等改进

#### 3. Cookie 预注入优化

在 WebView 创建时就注入 cookie，而不是每次加载前：
- 在 `wkwebView` getter 中注入
- 监听登录状态变化时更新

**预计提升**: 10-20%

#### 4. 精细化缓存清理

登录后只清理必要的 cookie，不清理资源缓存：

```objc
// 只清理 Cookie，保留资源缓存
NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeCookies]];
```

**预计提升**: 20-40%（登录后场景）

#### 5. WebView 预热

App 启动时预创建 WebView 实例：
- 初始化 WebView
- 预注册 Bridge Handler
- 设置 UA

**预计提升**: 15-30%

### 优先级3: 高级优化（实施难度高）

#### 6. WebView 池复用

维护 2-3 个 WebView 实例池，复用而不是每次创建。

**预计提升**: 40-60%

#### 7. 离线缓存/预加载

- 使用 Service Worker 或本地缓存常用资源
- 在 App 空闲时预加载常访问的页面

#### 8. 资源优化（需要后端配合）

- 关键 CSS/JS 内联到 HTML
- 启用 HTTP/2 或 HTTP/3
- 资源压缩（gzip/brotli）

## 建议实施顺序

1. **第一步**: 修改缓存策略（第560、566、163行）
2. **第二步**: 优化登录后的缓存清理逻辑
3. **第三步**: 实现 Cookie 预注入
4. **第四步**: 添加 DNS 预解析
5. **第五步**: 考虑 WebView 预热或复用

## 性能提升预期总结

| 优化项 | 预计提升 | 实施难度 |
|--------|----------|----------|
| 优化缓存策略 | 30-50% | 低 |
| Cookie 预注入 | 10-20% | 低 |
| 精细化缓存清理 | 20-40% | 中 |
| WebView 预热 | 15-30% | 中 |
| DNS 预解析 | 5-15% | 低 |
| WebView 池复用 | 40-60% | 高 |

## 关键代码位置

- **主加载方法**: `SLWebViewController.m:523-569 (startLoadRequestWithUrl)`
- **刷新方法**: `SLWebViewController.m:156-194 (refreshCurrentURL)`
- **登录后刷新**: `SLWebViewController.m:196-273 (reloadAfterLogin, forceSyncCookieAndReload)`
- **WebView 初始化**: `SLWebViewController.m:614-642 (wkwebView getter)`
- **Bridge 设置**: `SLWebViewController.m:502-521 (setupDefailUA)`

## 注意事项

1. 修改缓存策略后需要确保登录状态更新时能正确刷新
2. Cookie 预注入要注意多 WebView 实例的同步问题
3. WebView 池复用需要处理好内存管理和状态清理
4. 所有异步操作要确保在主线程更新 UI
