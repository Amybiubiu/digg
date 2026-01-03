# Safe Area Insets 传递到 H5 页面方案

## 问题背景

需要将 iOS 的 safe area insets（安全区域边距）传递给 WebView 中的 H5 页面，让 H5 能够根据这些值调整布局，适配刘海屏、Home Indicator 等系统UI。

## 核心挑战

**闪烁问题**：如果在 H5 页面渲染后才传递 safe area 值，H5 会先用默认布局渲染，收到数据后再调整，导致视觉闪烁。

**关键**：需要在 H5 页面开始渲染**之前**就让它获取到 safe area 值。

## 解决方案演进

### 方案1：在 didFinishNavigation 中发送 ❌

```objc
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    UIEdgeInsets insets = self.view.safeAreaInsets;
    [self.bridge callHandler:@"setSafeAreaInsets" data:@{...}];
}
```

**问题**：页面已经加载完成，H5 已经开始渲染，会闪烁。

### 方案2：在 viewDidLayoutSubviews 中发送 ⚠️

```objc
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets insets = self.view.safeAreaInsets;
    [self injectSafeAreaToWeb:insets];
}

- (void)injectSafeAreaToWeb:(UIEdgeInsets)insets {
    if (!self.bridge) return;

    NSDictionary *safeAreaData = @{
        @"top": @(insets.top),
        @"left": @(insets.left),
        @"bottom": @(insets.bottom),
        @"right": @(insets.right)
    };

    [self.bridge callHandler:@"setSafeAreaInsets" data:safeAreaData responseCallback:^(id responseData) {
        NSLog(@"[Safe Area] 已发送到H5: top=%.2f, left=%.2f, bottom=%.2f, right=%.2f",
              insets.top, insets.left, insets.bottom, insets.right);
    }];
}
```

**优点**：
- Safe area 值最准确（布局已完成）
- 自动响应设备旋转等变化

**问题**：
- 仍然比 H5 渲染晚，可能有闪烁
- 依赖 WebView 的生命周期

### 方案3：从父控制器传递 + UserScript 注入 ✅ 推荐

#### 核心思路
在创建 `SLWebViewController` 时，从父控制器获取 safe area 值并传入，然后在加载 URL 前通过 `WKUserScript` 注入到页面全局变量中。

#### 实现步骤

**1. 在 SLWebViewController.h 中添加属性**

```objc
@interface SLWebViewController : CaocaoRootViewController

// 初始的 safe area insets（由父控制器传入）
@property (nonatomic, assign) UIEdgeInsets initialSafeAreaInsets;

@end
```

**2. 在父控制器中传递 safe area**

```objc
// 例如在 SLHomePageViewController 中
- (void)openWebPage:(NSString *)url {
    SLWebViewController *webVC = [[SLWebViewController alloc] init];

    // 从当前控制器获取 safe area 并传递
    webVC.initialSafeAreaInsets = self.view.safeAreaInsets;

    [webVC startLoadRequestWithUrl:url];
    [self.navigationController pushViewController:webVC animated:YES];
}
```

**3. 在 startLoadRequestWithUrl 中注入 UserScript**

```objc
- (void)startLoadRequestWithUrl:(NSString *)url {
    if (stringIsEmpty(url)) {
        // ... 错误处理
        return;
    }

    // 在加载 URL 前注入 safe area 值
    [self injectSafeAreaUserScript:self.initialSafeAreaInsets];

    self.requestUrl = url;
    self.loadStartTime = [[NSDate date] timeIntervalSince1970];

    [[self class] syncGlobalTokenCookie];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self addThemeToURL:url]
                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:30];
    [self.wkwebView loadRequest:request];
}
```

**4. 实现 UserScript 注入方法**

```objc
- (void)injectSafeAreaUserScript:(UIEdgeInsets)insets {
    // 构造 JavaScript 代码，创建全局变量
    NSString *js = [NSString stringWithFormat:
        @"window.__SAFE_AREA__ = {top:%.2f, left:%.2f, bottom:%.2f, right:%.2f};",
        insets.top, insets.left, insets.bottom, insets.right];

    // 创建 UserScript，在文档开始加载时立即执行
    WKUserScript *script = [[WKUserScript alloc]
        initWithSource:js
        injectionTime:WKUserScriptInjectionTimeAtDocumentStart
        forMainFrameOnly:YES];

    // 注入到 WebView
    [self.wkwebView.configuration.userContentController addUserScript:script];
}
```

**5. 保留 viewDidLayoutSubviews 用于动态更新**

```objc
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // 通过 bridge 发送更新（应对旋转等运行时变化）
    UIEdgeInsets insets = self.view.safeAreaInsets;
    [self injectSafeAreaToWeb:insets];
}
```

#### H5 端使用方式

```javascript
// 页面加载时同步读取（无需等待 bridge 初始化）
const safeArea = window.__SAFE_AREA__ || {top: 0, left: 0, bottom: 0, right: 0};

// 使用这些值设置 CSS
document.documentElement.style.setProperty('--safe-area-top', safeArea.top + 'px');
document.documentElement.style.setProperty('--safe-area-bottom', safeArea.bottom + 'px');

// 或者直接在 CSS 中使用
// padding-top: var(--safe-area-top);

// 监听后续更新（通过 bridge）
bridge.registerHandler('setSafeAreaInsets', function(data) {
    // 处理动态变化（如设备旋转）
    console.log('Safe area updated:', data);
});
```

## 方案对比

| 方案 | 时机 | 准确性 | 闪烁 | 响应变化 |
|------|------|--------|------|----------|
| didFinishNavigation | 页面加载完成后 | ✅ 准确 | ❌ 严重闪烁 | ✅ 可以 |
| viewDidLayoutSubviews | 布局完成后 | ✅ 最准确 | ⚠️ 轻微闪烁 | ✅ 自动 |
| viewWillAppear | 视图即将显示 | ⚠️ 可能不准 | ⚠️ 可能闪烁 | ❌ 需手动 |
| **父控制器传递 + UserScript** | **页面加载前** | ✅ 准确 | ✅ **无闪烁** | ✅ 结合 bridge |

## 最佳实践

### 推荐组合方案：UserScript + Bridge 更新

1. **初始加载**：通过 UserScript 注入，H5 同步读取，无闪烁
2. **动态更新**：通过 Bridge 在 viewDidLayoutSubviews 中发送，响应旋转等变化

### 其他替代方案

#### 方案：使用 CSS env() 函数（更简单）

iOS 11+ 的 WebView 支持 CSS 环境变量：

```css
.content {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
}
```

需要在 WebView 配置中启用：

```objc
// viewport meta 标签需要设置
<meta name="viewport" content="viewport-fit=cover">
```

**优点**：
- 无需 JS 交互
- 自动响应变化
- 最简单

**缺点**：
- 只能在 CSS 中使用，JS 无法获取数值

## 实现位置

- **SLWebViewController.h**: 添加 `initialSafeAreaInsets` 属性
- **SLWebViewController.m**:
  - `startLoadRequestWithUrl:` 方法中调用注入
  - 新增 `injectSafeAreaUserScript:` 方法
  - 保留 `viewDidLayoutSubviews` 和 `injectSafeAreaToWeb:` 用于动态更新
- **调用方**（各个父控制器）：创建 WebViewController 时传入 safe area 值

## 注意事项

1. **WebView 复用**：如果使用 WebView 池，需要在每次 dequeue 后重新设置 UserScript
2. **不同页面**：不同页面的 safe area 可能不同（导航栏隐藏状态），需要传递对应值
3. **性能**：UserScript 注入开销很小，不影响性能
4. **兼容性**：UserScript 在 iOS 8+ 可用，本项目最低支持 iOS 14，完全兼容

## 总结

对于"需要尽早传递 safe area 给 H5 避免闪烁"的需求，最佳方案是：

**从父控制器获取 → 通过 UserScript 注入 → H5 同步读取 + Bridge 动态更新**

这种方案完全解决了闪烁问题，同时保持了动态响应能力。
