# WebView 池复用导致侧滑返回白屏问题

## 问题背景

在实现 WebView 池（WebView Pool）优化页面加载性能后，出现了侧滑返回时的白屏问题。这个问题只在手势侧滑返回时出现，而在调用代码关闭页面（如 `popViewControllerAnimated:`）时不会出现。

## 问题现象

1. **侧滑返回时白屏**：从页面 A 侧滑返回到页面 B 时，转场动画过程中页面 A 显示白屏
2. **页面内容错误**：从 WebView 池获取的 WebView 显示了之前其他页面的内容
3. **加载被取消**：页面加载过程中出现错误码 -999（`NSURLErrorCancelled`）

## 根本原因分析

### 1. iOS 转场动画机制

iOS 的侧滑返回使用快照（Snapshot）机制：

```
用户开始侧滑
    ↓
viewWillDisappear/viewWillAppear 被调用
    ↓
📸 UIKit 对两个页面进行快照
    ↓
使用快照执行动画（两个快照同时在屏幕上滑动）
    ↓
viewDidDisappear/viewDidAppear 被调用
    ↓
移除快照，显示真实页面
```

**关键点**：快照后，页面内容不能变化，否则快照失效 → 白屏

### 2. WebView 池回收时机问题

#### 初始实现（问题版本）

```objc
- (void)viewDidDisappear:(BOOL)animated {
    if (self.shouldReuseWebView && !isInStack) {
        [[SLWebViewPool sharedPool] enqueueWebView:self.wkwebView];
        _wkwebView = nil;  // 💥 立即置空
    }
}
```

**问题**：
- `viewDidDisappear` 在转场动画**进行中**就被调用（不是动画完成后）
- WebView 被立即清空（`loadHTMLString:@"<html></html>"`）
- 但快照还在屏幕上滑动 → 快照失效 → **白屏**

#### 尝试使用转场协调器（仍有问题）

```objc
- (void)viewDidDisappear:(BOOL)animated {
    [self.transitionCoordinator animateAlongsideTransition:nil completion:^(context) {
        if (!context.isCancelled) {
            [[SLWebViewPool sharedPool] enqueueWebView:webViewToRecycle];
        }
    }];
    _wkwebView = nil;  // 💥 仍然立即置空
}
```

**问题**：
- 虽然回收延迟到 completion，但 `_wkwebView` 仍然立即置空
- 如果手势取消，WebView 引用丢失 → 白屏
- 时序仍然微妙，可能影响快照

### 3. WebView 池清空内容的异步问题

```objc
- (void)enqueueWebView:(WKWebView *)webView {
    dispatch_async(self.poolQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [webView loadHTMLString:@"<html></html>" baseURL:nil];  // 异步清空
            dispatch_async(self.poolQueue, ^{
                [self.availableWebViews addObject:webView];  // 更晚才加入池
            });
        });
    });
}
```

**问题**：
- 多层异步嵌套，清空操作可能还没完成，WebView 就被取出使用
- 导致新页面显示旧内容

## 解决方案演进

### 方案 1：只在 dealloc 中回收（最保守）

```objc
- (void)viewDidDisappear:(BOOL)animated {
    // 什么都不做，完全避开转场动画
}

- (void)dealloc {
    if (self.shouldReuseWebView && self.wkwebView) {
        [[SLWebViewPool sharedPool] enqueueWebView:self.wkwebView];
    }
}
```

**优点**：
- ✅ 完全避开转场动画期间的所有问题
- ✅ 代码简单可靠
- ✅ 符合 iOS 资源管理最佳实践

**缺点**：
- ❌ WebView 回收延迟（从 viewDidDisappear 到 dealloc 可能几百毫秒）
- ❌ 池子利用率不高（新页面打开时，旧页面 WebView 可能还没回收）

### 方案 2：延迟回收（最终方案）⭐️

```objc
- (void)viewDidDisappear:(BOOL)animated {
    if (self.shouldReuseWebView && !isInStack && self.wkwebView) {
        // 延迟 0.5 秒回收，确保转场动画完全结束
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            // 再次检查是否还不在栈中（防止被重新加入）
            BOOL stillNotInStack = ![strongSelf.navigationController.viewControllers containsObject:strongSelf];
            if (stillNotInStack && strongSelf.wkwebView) {
                [[SLWebViewPool sharedPool] enqueueWebView:strongSelf.wkwebView];
                strongSelf->_wkwebView = nil;
            }
        });
    }
}
```

**优点**：
- ✅ 避免转场动画问题（0.5 秒足够动画完成）
- ✅ 及时回收（比 dealloc 快）
- ✅ 池子利用率高
- ✅ 处理边缘情况（页面重新进入栈、手势取消等）

**为什么 0.5 秒？**
- iOS 转场动画通常 0.3-0.35 秒
- 0.5 秒留有余地，确保动画完全结束
- 足够短，用户感觉不到延迟

### 方案 3：隐藏 WebView 避免旧内容闪现

```objc
// 回收时隐藏
- (void)enqueueWebView:(WKWebView *)webView {
    webView.hidden = YES;  // 隐藏
    [webView loadHTMLString:@"<html></html>" baseURL:nil];  // 清空
}

// 取出时显示
- (WKWebView *)dequeueWebView {
    WKWebView *webView = [从池中获取];
    webView.hidden = NO;  // 显示
    return webView;
}

// 加载新 URL 时，如果有旧内容先隐藏
- (void)startLoadRequestWithUrl:(NSString *)url {
    if (self.wkwebView.URL && ![self.wkwebView.URL.absoluteString isEqualToString:@"about:blank"]) {
        self.wkwebView.hidden = YES;  // 先隐藏
    }
    [self.wkwebView loadRequest:request];
}

// 加载完成后显示
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.hidden) {
        webView.hidden = NO;  // 显示
    }
}
```

**解决的问题**：
- 避免用户在新内容加载前看到旧内容
- 减少视觉闪烁

## 最终实现方案

综合以上方案，最终实现包括：

### 1. 延迟回收策略

- `viewDidDisappear` 中延迟 0.5 秒回收
- 再次检查页面状态，防止错误回收
- `dealloc` 作为后备方案（如果延迟回收没执行）

### 2. 隐藏/显示机制

- 回收时隐藏 WebView
- 取出时显示 WebView
- 加载新 URL 前，如果有旧内容先隐藏
- 加载完成后显示

### 3. 详细的性能日志

```objc
[性能] ========== 开始加载页面 ==========
[性能] ⏱ 获取 WebView 耗时: Xms
[性能] ⏱ Cookie 同步耗时: Xms
[性能] ⏱ 构建请求耗时: Xms
[性能] ⏱ 调用 loadRequest 耗时: Xms
[性能] ⏱ 总准备时间: Xms
[性能] 开始请求网络 (+Xms)
[性能] 收到服务器响应 (+Xms，总计Xms)
[性能] ========== 页面加载完成 ==========
[性能] ✅ 渲染耗时: Xms
[性能] ✅ 总计耗时: Xms
```

### 4. 清晰的 WebView 池日志

```objc
[WebViewPool] ✅ 从池中复用 WebView，剩余: 2    // 真正复用
[WebViewPool] 🆕 池中无可用 WebView，创建新实例  // 创建新的
[WebViewPool] ♻️ WebView 已归还到池
```

## 关键代码变更

### SLWebViewController.m

#### viewDidDisappear 延迟回收
```objc
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    BOOL isInStack = [self.navigationController.viewControllers containsObject:self];

    if (self.shouldReuseWebView && !isInStack && self.wkwebView) {
        // 延迟 0.5 秒回收
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            BOOL stillNotInStack = ![strongSelf.navigationController.viewControllers containsObject:strongSelf];
            if (stillNotInStack && strongSelf.wkwebView) {
                [[SLWebViewPool sharedPool] enqueueWebView:strongSelf.wkwebView];
                strongSelf->_wkwebView = nil;
            }
        });
    }
}
```

#### startLoadRequestWithUrl 隐藏旧内容
```objc
- (void)startLoadRequestWithUrl:(NSString *)url {
    // 如果使用 WebView 池，可能有旧内容，先隐藏避免闪现
    if (self.shouldReuseWebView && webView.URL &&
        ![webView.URL.absoluteString isEqualToString:@"about:blank"]) {
        webView.hidden = YES;
    }

    [webView loadRequest:request];
}
```

#### didFinishNavigation 显示内容
```objc
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 显示 WebView（可能之前被隐藏了）
    if (webView.hidden) {
        webView.hidden = NO;
    }
}
```

### SLWebViewPool.m

#### enqueueWebView 隐藏并清空
```objc
- (void)enqueueWebView:(WKWebView *)webView {
    if (!webView) return;

    dispatch_async(self.poolQueue, ^{
        if (self.availableWebViews.count >= self.maxPoolSize) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [webView stopLoading];
            webView.hidden = YES;  // 隐藏
            [webView loadHTMLString:@"<html></html>" baseURL:nil];
            webView.navigationDelegate = nil;
            webView.UIDelegate = nil;

            dispatch_async(self.poolQueue, ^{
                [self.availableWebViews addObject:webView];
            });
        });
    });
}
```

#### dequeueWebView 显示
```objc
- (WKWebView *)dequeueWebView {
    __block WKWebView *webView = nil;

    dispatch_sync(self.poolQueue, ^{
        if (self.availableWebViews.count > 0) {
            webView = [self.availableWebViews firstObject];
            [self.availableWebViews removeObjectAtIndex:0];
        }
    });

    if (!webView) {
        webView = [self createNewWebView];
    } else {
        webView.hidden = NO;  // 显示
    }

    return webView;
}
```

## 为什么侧滑返回特殊？

### 侧滑返回 vs 调用关闭的区别

| 特性 | 侧滑返回 | 调用关闭 (popViewController) |
|------|----------|------------------------------|
| 可交互性 | ✅ 用户可中途取消 | ❌ 不可取消 |
| 页面可见性 | 两个页面同时可见 | 快速切换 |
| 用户注意力 | 盯着正在移动的页面 | 关注目标页面 |
| 时序敏感度 | 高（动画期间不能修改内容） | 低 |

**核心差异**：
- **侧滑**：页面在你眼前慢慢移动，任何闪烁、白屏都很明显
- **调用关闭**：快速切换，用户根本不看被关闭的页面

## 经验总结

### 1. 尊重 iOS 的生命周期设计

- `viewDidLoad`/`viewWillAppear`/`viewDidAppear`: 初始化和准备显示
- `viewWillDisappear`/`viewDidDisappear`: 准备隐藏和清理轻量资源
- **`dealloc`: 释放重量级资源** ← 苹果推荐的做法

### 2. 转场动画期间不要修改页面内容

- iOS 使用快照机制优化动画性能
- 快照后修改内容会导致快照失效
- 使用延迟或 `dealloc` 避免在动画期间修改

### 3. 异步操作要小心时序

- WebView 池的清空操作是异步的
- 可能在清空完成前就被取出使用
- 使用隐藏/显示机制缓解问题

### 4. 延迟是一个有效的工具

- 0.5 秒的延迟既避免了动画问题，又及时回收资源
- 用户感觉不到这个延迟
- 比复杂的转场协调器逻辑更可靠

### 5. 日志是调试的关键

- 详细的性能日志帮助定位问题
- 清晰的状态日志避免误导
- 时间戳记录帮助理解时序问题

## 性能对比

### 优化前
- 页面加载时间：快（但有白屏问题）
- WebView 复用率：低（回收太晚）
- 用户体验：差（白屏、闪烁）

### 优化后
- 页面加载时间：快（详细日志可监控）
- WebView 复用率：高（0.5 秒后回收）
- 用户体验：好（无白屏、无闪烁）

## 相关文件

- `digg/Common/SLWebViewController.m` - 主要的 WebView 控制器
- `digg/Common/SLWebViewPool.h/m` - WebView 池实现
- `digg/SLHomeWebViewController.m` - 首页 tab 子页面（不使用池）
- `digg/SLHomePageViewController.m` - 首页容器

## 参考资料

- [iOS View Controller Programming Guide - View Controller Transitions](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html)
- [UIViewControllerTransitionCoordinator 文档](https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinator)
- [WKWebView 最佳实践](https://developer.apple.com/documentation/webkit/wkwebview)

---

**日期**: 2026-01-04
**问题**: WebView 池导致侧滑返回白屏
**解决方案**: 延迟回收 + 隐藏/显示机制
**状态**: ✅ 已解决
