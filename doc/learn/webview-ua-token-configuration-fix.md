# WebView UA 和 Token 配置时序问题修复

## 概述

todo 这里面有很多冗余的代码，后面可以修复一下
本文档记录了修复 `SLWebViewController` 中 H5 页面 UA（User Agent）和 Token 配置时序问题的完整过程。

## 问题背景

在通过 `dismiss` 后 `push` WebViewController 的方式打开 H5 页面时（例如从 Record 页面跳转到详情页），发现 H5 页面的 UA 和其他配置对象设置不正确。

### 问题代码位置

**SLRecordViewController.m:480-512**
```objc
- (void)gotoH5Page:(NSString *)articleId {
    NSString *url = [NSString stringWithFormat:@"%@%@", ARTICAL_PAGE_DETAIL_URL, articleId];
    SLWebViewController *webVC = [[SLWebViewController alloc] init];
    [webVC startLoadRequestWithUrl:url];  // ❌ 此时 UA 还没设置
    webVC.hidesBottomBarWhenPushed = YES;

    // ... push 逻辑
}
```

## 问题分析

### 原始执行流程

```
init → startLoadRequestWithUrl → 访问 wkwebView getter
  ↓
从预热池获取 WebView（没有 UA）
  ↓
loadRequest 开始加载 URL ❌ 使用系统默认 UA
  ↓
viewDidLoad → setupDefailUA ⏰ 太晚了
```

### 核心问题

**时序问题导致配置失效：**

1. `startLoadRequestWithUrl` 在 `viewDidLoad` 之前被调用
2. WebView 从预热池获取时没有设置 UA
3. URL 加载时使用的是系统默认 UA，不是自定义的 "infoflow" UA
4. `setupDefailUA` 在 `viewDidLoad` 中才执行，但此时 URL 已经开始加载

### 预热机制分析

**SLWebViewPreloaderManager 预热时的配置：**

✅ 设置了 processPool（共享进程池）
✅ 设置了 websiteDataStore（数据存储）
✅ 注入了 bp-token cookie（如果用户已登录）
❌ **没有设置 customUserAgent**
❌ **没有初始化 bridge**

**为什么预热时不设置 UA？**
- UA 设置依赖于 `SLWebViewController` 的实例方法
- bridge 初始化需要注册 H5 ↔ Native 通信 handlers
- 预热管理器是独立的单例，只负责通用配置

## 解决方案演进

### 方案1：在 startLoadRequestWithUrl 中调用 setupDefailUA

**修改：** 在 `loadRequest` 之前调用 `setupDefailUA`

```objc
- (void)startLoadRequestWithUrl:(NSString *)url {
    self.requestUrl = url;
    [self setupDefailUA];  // 确保在加载前设置 UA
    [self.wkwebView loadRequest:request];
}
```

**问题：** 只设置了 UA 和 bridge，没有注入 token

### 方案2：改用 ensureUAAndTokenIfNeeded

**改进：** 使用 `ensureUAAndTokenIfNeeded` 同时处理 UA、bridge 和 token

```objc
- (void)startLoadRequestWithUrl:(NSString *)url {
    self.requestUrl = url;
    [self ensureUAAndTokenIfNeeded];  // 确保 UA、bridge 和 token
    [self.wkwebView loadRequest:request];
}
```

**优势：**
- ✅ 设置 UA 和 bridge
- ✅ 注入 token cookie
- ✅ 避免重复设置（有 `isSetUA` 检查）

### 方案3：在 wkwebView getter 中也调用配置

**问题发现：** 如果有其他地方直接操作 `wkwebView` 而不通过 `startLoadRequestWithUrl`，可能会遗漏配置

**改进：** 在 getter 中自动配置

```objc
- (WKWebView *)wkwebView {
    if (!_wkwebView) {
        _wkwebView = [[SLWebViewPreloaderManager shared] dequeuePreheatedWebViewWithFrame:CGRectZero];
        // ... 其他设置
        [self ensureUAAndTokenIfNeeded];  // 自动配置
    }
    return _wkwebView;
}
```

**问题：** 导致嵌套调用和重复的 token 注入

### 方案4：发现嵌套调用问题

**执行流程分析：**

```
startLoadRequestWithUrl
  ↓
[self ensureUAAndTokenIfNeeded] ← 第1次调用
  ↓
内部访问 self.wkwebView
  ↓
触发 getter
  ↓
[self ensureUAAndTokenIfNeeded] ← 第2次调用（嵌套！）
```

**问题：**
- ❌ 嵌套调用，逻辑混乱
- ❌ token 注入执行两次（浪费性能）
- ❌ 难以理解和维护

## 最终方案：职责分离

### 设计原则

**分工明确，避免嵌套调用：**

1. **getter** - 只负责设置 UA 和 bridge（不依赖 requestUrl）
2. **startLoadRequestWithUrl** - 确保所有配置（包括 token）

### 实现代码

**1. wkwebView getter (SLWebViewController.m:656)**

```objc
- (WKWebView *)wkwebView {
    if (!_wkwebView) {
        _wkwebView = [[SLWebViewPreloaderManager shared] dequeuePreheatedWebViewWithFrame:CGRectZero];
        _wkwebView.backgroundColor = [UIColor clearColor];
        [_wkwebView setOpaque:NO];
        _wkwebView.scrollView.bounces = YES;
        _wkwebView.navigationDelegate = self;
        _wkwebView.allowsBackForwardNavigationGestures = NO;

        if (@available(iOS 16.4, *)) {
            _wkwebView.inspectable = YES;
        }

        // 在 WebView 创建后立即设置 UA 和 bridge
        [self setupDefailUA];
    }
    return _wkwebView;
}
```

**2. startLoadRequestWithUrl (SLWebViewController.m:584)**

```objc
- (void)startLoadRequestWithUrl:(NSString *)url {
    if(stringIsEmpty(url)){
        // ... 错误处理
        return;
    }
    self.requestUrl = url;

    // 确保在加载 URL 之前设置 UA、bridge 和 token
    [self ensureUAAndTokenIfNeeded];

    NSURL *finalURL = [self addThemeToURL:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:finalURL
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:30];
    [self.wkwebView loadRequest:request];
}
```

### 优化后的执行流程

```
startLoadRequestWithUrl 被调用
  ↓
self.requestUrl = url (设置 requestUrl)
  ↓
[self ensureUAAndTokenIfNeeded]
  ↓
检查 isSetUA → NO
  ↓
调用 setupDefailUA
  ↓
内部访问 self.wkwebView → 触发 getter
  ↓
getter: [self setupDefailUA]
  ↓
设置 UA 和 bridge，isSetUA = YES
  ↓
返回到 ensureUAAndTokenIfNeeded
  ↓
setupDefailUA 被跳过（isSetUA 已为 YES）
  ↓
注入 token（只执行一次）✅
  ↓
loadRequest（使用正确的 UA 和 token）✅
```

## 关键方法说明

### setupDefailUA

**功能：** 设置 UA 和初始化 bridge

**关键逻辑：**
- 检查 `isSetUA` 标志，避免重复设置
- 初始化 WebViewJavascriptBridge
- 注册 H5 ↔ Native 通信 handlers
- 设置自定义 UA（添加 "infoflow" 后缀）

### ensureUAAndTokenIfNeeded

**功能：** 确保 UA、bridge 和 token 都配置好

**关键逻辑：**
```objc
- (void)ensureUAAndTokenIfNeeded {
    // 1. 确保 UA 和 bridge 已设置
    if (!self.isSetUA) {
        [self setupDefailUA];
    }

    // 2. 注入 token cookie
    NSString *token = [SLUser defaultUser].userEntity.token;
    if (stringIsEmpty(token)) {
        return;
    }

    // 3. 获取 domain（优先使用 wkwebView.URL，fallback 到 requestUrl）
    NSURL *currentURL = self.wkwebView.URL ?: [NSURL URLWithString:self.requestUrl ?: @""];
    NSString *domain = currentURL.host;
    if (stringIsEmpty(domain)) {
        return;
    }

    // 4. 注入 bp-token cookie
    WKHTTPCookieStore *store = self.wkwebView.configuration.websiteDataStore.httpCookieStore;
    [SLWebViewPreloaderManager injectBpTokenCookie:token forDomain:domain intoStore:store completion:nil];
}
```

## Token 注入机制

### 预热时的 Token 注入

**位置：** `SLWebViewPreloaderManager.m:105-112`

```objc
NSString *token = [SLUser defaultUser].userEntity.token;
if (token.length > 0) {
    WKHTTPCookieStore *cookieStore = webView.configuration.websiteDataStore.httpCookieStore;
    NSString *domain = [NSURL URLWithString:H5BaseUrl].host;
    [SLWebViewPreloaderManager injectBpTokenCookie:token forDomain:domain intoStore:cookieStore completion:^{
        [webView loadRequest:req];
    }];
}
```

**特点：**
- 注入到 `H5BaseUrl` 的 domain（固定域名）
- 在预热时就注入，提升首次加载速度
- 适用于大部分从 `H5BaseUrl` 加载的页面

### 使用时的 Token 注入

**位置：** `ensureUAAndTokenIfNeeded` 方法

**特点：**
- 注入到实际 URL 的 domain（动态域名）
- 使用最新的 token（覆盖预热时的 token）
- 支持跨域场景（如果 URL 来自其他 domain）

### 为什么需要两次注入？

1. **Domain 可能不同** - 实际 URL 可能来自其他 domain
2. **Token 可能过期** - 用户可能重新登录，需要更新 token
3. **Cookie 注入是幂等的** - 重复注入不会有副作用

## 方案优势

### 1. 自动化配置

✅ **任何时候访问 webView 都会自动配置 UA 和 bridge**
- 不依赖外部调用
- 覆盖所有使用场景

### 2. 避免嵌套调用

✅ **职责分离，逻辑清晰**
- getter 只负责 UA 和 bridge
- startLoadRequestWithUrl 负责完整配置
- 避免了重复的 token 注入

### 3. 性能优化

✅ **Token 只注入一次**
- 避免浪费性能
- 提升加载速度

### 4. 健壮性

✅ **覆盖多种场景**
- 首次加载
- 刷新页面
- 登录后重新加载
- 直接操作 webView 的场景

## 覆盖的场景

### 1. startLoadRequestWithUrl - 首次加载

**代码位置：** `SLWebViewController.m:584`

```objc
[webVC startLoadRequestWithUrl:url];
```

**配置流程：**
- ✅ 设置 requestUrl
- ✅ 调用 ensureUAAndTokenIfNeeded
- ✅ 设置 UA 和 bridge（通过 getter）
- ✅ 注入 token
- ✅ 加载 URL

### 2. refreshCurrentURL - 刷新当前页面

**代码位置：** `SLWebViewController.m:221, 228`

```objc
[self.wkwebView loadRequest:request];
```

**配置流程：**
- ✅ 访问 wkwebView 时，UA 和 bridge 已经设置好（在 getter 中）
- ✅ Token 在首次加载时已注入

### 3. reloadAfterLogin - 登录后重新加载

**代码位置：** `SLWebViewController.m:284`

```objc
[self.wkwebView loadRequest:request];
```

**配置流程：**
- ✅ 访问 wkwebView 时，UA 和 bridge 已经设置好
- ✅ Token 在登录后被重新注入（通过 reloadAfterLogin 方法）

## 注意事项

### 1. isSetUA 标志的作用

`isSetUA` 标志用于避免重复设置 UA 和 bridge：

```objc
- (void)setupDefailUA {
    if (self.isSetUA) {
        return;  // 避免重复设置
    }
    // ... 设置逻辑
    self.isSetUA = YES;
}
```

**重要性：**
- 避免重复初始化 bridge
- 避免重复注册 H5 ↔ Native 通信 handlers
- 提升性能

### 2. Token 注入的时机

Token 注入需要知道目标 domain：

```objc
NSURL *currentURL = self.wkwebView.URL ?: [NSURL URLWithString:self.requestUrl ?: @""];
```

**Fallback 机制：**
1. 优先使用 `wkwebView.URL`（如果已经加载过 URL）
2. Fallback 到 `requestUrl`（如果还没有加载）
3. 如果都为空，跳过 token 注入

### 3. 预热池的限制

预热的 WebView 只设置了基础配置，不包括：
- ❌ customUserAgent
- ❌ WebViewJavascriptBridge

**因此必须在使用时设置这些配置。**

## 总结

### 问题根源

时序问题导致 WebView 在加载 URL 时还没有设置 UA 和 bridge。

### 解决方案

**职责分离，自动化配置：**

1. **wkwebView getter** - 在 WebView 创建时自动设置 UA 和 bridge
2. **startLoadRequestWithUrl** - 在加载 URL 前确保所有配置（包括 token）

### 关键改进

- ✅ 避免了时序问题
- ✅ 避免了嵌套调用
- ✅ 提升了性能（token 只注入一次）
- ✅ 提升了健壮性（覆盖所有场景）
- ✅ 提升了可维护性（逻辑清晰）

### 影响范围

所有通过 `SLWebViewController` 加载的 H5 页面，包括：
- 首页内容
- 文章详情
- 用户资料
- 记录页面
- 其他所有 H5 页面

现在所有 H5 页面都会使用正确的 UA（带 "infoflow" 后缀）和完整的 bridge 配置。

---

**文档创建时间：** 2026-01-15
**相关文件：**
- `digg/Common/SLWebViewController.m`
- `digg/Common/SLWebViewPreloaderManager.m`
- `digg/Record/SLRecordViewController.m`
