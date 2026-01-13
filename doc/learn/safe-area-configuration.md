# iOS WebView 安全区域配置详解

## 概述

本文档记录了影响 WebView 安全区域（Safe Area）的所有关键代码，以及如何正确配置以避免内容被刘海屏、状态栏、Home Indicator 等系统 UI 遮挡。

## 什么是安全区域（Safe Area）

安全区域是 iOS 11 引入的概念，用于标识屏幕上不会被系统 UI 遮挡的区域：

```
┌─────────────────────────────┐
│ 状态栏/刘海/动态岛 (不安全)    │ ← 顶部不安全区域
├─────────────────────────────┤
│                             │
│    Safe Area (安全区域)      │ ← 内容应该显示在这里
│                             │
├─────────────────────────────┤
│ Home Indicator (不安全)      │ ← 底部不安全区域
└─────────────────────────────┘
```

## 关键配置点

### 1. WebView 约束设置

**文件位置**: `digg/Common/SLWebViewController.m:74-90`

```objc
} else {
    self.navigationController.navigationBar.hidden = YES;
    [self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);

        // 判断是否是Tab页面
        if (!self.hidesBottomBarWhenPushed) {
            // Tab页面：使用安全区域底部，自动适配 TabBar
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            // 非Tab页面：使用安全区域底部，避免被 Home Indicator 遮挡
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        }
    }];
}
```


### 2. contentInsetAdjustmentBehavior 设置

**文件位置**: `digg/Common/SLWebViewController.m:638-641`

```objc
// 禁用自动调整内容边距，避免系统自动添加安全区域边距
// if (@available(iOS 11.0, *)) {
//     _wkwebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
// }
```

**属性说明**：

| 值 | 说明 | 效果 |
|---|---|---|
| `UIScrollViewContentInsetAdjustmentAutomatic` | 系统自动调整（默认） | 系统会自动为安全区域添加内边距 |
| `UIScrollViewContentInsetAdjustmentScrollableAxes` | 只在可滚动方向调整 | 部分调整 |
| `UIScrollViewContentInsetAdjustmentNever` | 永不调整 | ⚠️ 内容可能被遮挡 |
| `UIScrollViewContentInsetAdjustmentAlways` | 总是调整 | 强制调整 |

**当前状态**：
- 代码已被注释，使用默认值 `Automatic`
- 这意味着系统会自动处理安全区域的内边距

**注意事项**：
- 如果设置为 `Never`，必须在 Native 层通过约束正确处理安全区域
- 如果使用默认值，系统会自动添加内边距，但前提是 WebView 的约束要正确

### 3. WebView 预加载配置

**文件位置**: `digg/Common/SLWebViewPreloaderManager.m:96-136`

预加载的 WebView 使用相同的配置：

```objc
- (WKWebViewConfiguration *)createDefaultConfiguration {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.processPool = [SLWebViewController sharedProcessPool];
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;

    // 允许内联播放
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    // 移动端内容模式
    if (@available(iOS 13.0, *)) {
        WKWebpagePreferences *pagePrefs = [[WKWebpagePreferences alloc] init];
        pagePrefs.preferredContentMode = WKContentModeMobile;
        configuration.defaultWebpagePreferences = pagePrefs;
    }

    return configuration;
}
```

## H5 端配置

### viewport-fit 属性

H5 端可以通过 `viewport-fit` 控制内容是否延伸到安全区域外：

```html
<!-- 包含安全区域（默认） -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=contain">

<!-- 覆盖整个屏幕（包括不安全区域） -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
```

### CSS 安全区域变量

```css
/* 使用 CSS 环境变量适配安全区域 */
.header {
    padding-top: env(safe-area-inset-top);
}

.footer {
    padding-bottom: env(safe-area-inset-bottom);
}

.sidebar {
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
}
```

## 完整的安全区域处理方案
（以下有些东西写的不太对；不用太关注）

### 方案 A：Native 层处理（推荐）

**优点**：
- 所有 H5 页面自动适配
- 不需要 H5 端做任何修改
- 统一管理，维护简单

**实现**：
```objc
// SLWebViewController.m
[self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    make.left.right.equalTo(self.view);
    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
}];

// 使用默认的 contentInsetAdjustmentBehavior
// 不设置或设置为 Automatic
```

### 方案 B：H5 层处理

**优点**：
- H5 可以精确控制每个页面的布局
- 可以实现沉浸式效果（如全屏视频）

**缺点**：
- 每个 H5 页面都需要适配
- 维护成本高

**实现**：
```objc
// Native 层：WebView 铺满整个屏幕
[self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
}];

// 禁用自动调整
_wkwebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
```

```html
<!-- H5 层：使用 viewport-fit 和 CSS 变量 -->
<meta name="viewport" content="viewport-fit=cover">
<style>
.page {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
}
</style>
```

### 方案 C：混合方案

**适用场景**：
- 大部分页面使用 Native 层处理
- 特殊页面（如全屏视频）使用 H5 层处理

**实现**：
- 默认使用方案 A
- 特殊页面通过 URL 参数或 JS Bridge 通知 Native 切换到方案 B

## 常见问题

### Q1: 为什么设置了 viewport-fit=contain 还是被遮挡？

**A**: 因为 Native 层的约束设置错误。`viewport-fit` 只在 WebView 本身有安全区域边距时才生效。如果 Native 层就把 WebView 铺满了整个屏幕，H5 的设置无法生效。

### Q2: contentInsetAdjustmentBehavior 应该设置为什么？

**A**:
- 如果使用方案 A（Native 层处理），使用默认值 `Automatic` 或不设置
- 如果使用方案 B（H5 层处理），设置为 `Never`

### Q3: Tab 页面和二级页面的安全区域处理有什么区别？

**A**:
- **Tab 页面**：底部需要为 TabBar 预留空间，使用 `mas_safeAreaLayoutGuideBottom`
- **二级页面**：底部需要为 Home Indicator 预留空间，也使用 `mas_safeAreaLayoutGuideBottom`
- 两者都应该使用安全区域，区别在于 TabBar 会自动占用安全区域的一部分

### Q4: 如何调试安全区域问题？

**方法**：
1. 在模拟器中选择有刘海的设备（iPhone 14 Pro 等）
2. 给 WebView 设置背景色，观察是否被遮挡
3. 使用 Safari 开发者工具查看 H5 的 `env(safe-area-inset-*)` 值
4. 打印约束信息：
```objc
NSLog(@"Safe Area Insets: %@", NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
```

## 推荐配置

基于当前项目，推荐使用**方案 A（Native 层处理）**：

```objc
// SLWebViewController.m
[self.wkwebView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    make.left.right.equalTo(self.view);
    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
}];

// 使用默认的 contentInsetAdjustmentBehavior（不设置）
```

这样所有 H5 页面都会自动适配安全区域，无需修改 H5 代码。

## 相关文件

- `digg/Common/SLWebViewController.m` - WebView 主控制器
- `digg/Common/SLWebViewPreloaderManager.m` - WebView 预加载管理
- `digg/Common/SLWebViewPool.m` - WebView 池管理

## 更新记录

- 2026-01-13: 初始文档，记录安全区域配置相关代码
