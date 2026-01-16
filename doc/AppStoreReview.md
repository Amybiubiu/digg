# App Store 评分功能

## 功能说明

该功能提供两种方式让 H5 页面引导用户为应用评分：

1. **应用内评分弹窗**（推荐）：使用 Apple 官方 API，在应用内显示评分弹窗
2. **跳转 App Store**：直接打开 App Store 的评分页面

## 技术实现

### iOS 原生端

**方案 1：应用内评分弹窗**
- 使用 Apple 官方的 `SKStoreReviewController` API
- **iOS 14+**: 使用 `requestReviewInScene:` 方法
- **iOS 10.3 - iOS 13**: 使用 `requestReview` 方法

**方案 2：跳转 App Store**
- 使用 `UIApplication openURL:` 打开 App Store 评分页面
- URL 格式：`https://apps.apple.com/app/id{appId}?action=write-review`

### 实现位置

文件：`digg/Common/SLWebViewController.m`

Bridge Handler 名称：
- `requestAppStoreReview` - 应用内评分弹窗
- `openAppStoreReviewPage` - 跳转 App Store

## JavaScript 调用方式

### 方案 1：应用内评分弹窗（推荐）

```javascript
// 调用应用内评分弹窗
window.WebViewJavascriptBridge.callHandler(
  'requestAppStoreReview',
  {},
  function(response) {
    console.log('评分请求结果:', response);
    // response 格式: { success: true/false, message: "..." }
  }
);
```

**特点：**
- ✅ 用户体验好，不离开应用
- ✅ Apple 推荐的方式
- ❌ 有频率限制（一年最多 3 次）
- ❌ 系统可能不显示弹窗

### 方案 2：跳转 App Store

```javascript
// 跳转到 App Store 评分页面
window.WebViewJavascriptBridge.callHandler(
  'openAppStoreReviewPage',
  {
    appId: '6738596193'  // 可选，不传则使用默认值
  },
  function(response) {
    console.log('跳转结果:', response);
    // response 格式: { success: true/false, message: "..." }
  }
);
```

**特点：**
- ✅ 没有频率限制
- ✅ 保证能打开评分页面
- ❌ 用户会离开应用
- ❌ 体验相对较差

### 完整示例

```javascript
// 确保 Bridge 已初始化
function setupWebViewJavascriptBridge(callback) {
  if (window.WebViewJavascriptBridge) {
    return callback(WebViewJavascriptBridge);
  }
  if (window.WVJBCallbacks) {
    return window.WVJBCallbacks.push(callback);
  }
  window.WVJBCallbacks = [callback];
  var WVJBIframe = document.createElement('iframe');
  WVJBIframe.style.display = 'none';
  WVJBIframe.src = 'https://__bridge_loaded__';
  document.documentElement.appendChild(WVJBIframe);
  setTimeout(function() {
    document.documentElement.removeChild(WVJBIframe);
  }, 0);
}

// 使用示例
setupWebViewJavascriptBridge(function(bridge) {
  // 方案 1：应用内评分弹窗
  document.getElementById('rateInAppButton').addEventListener('click', function() {
    bridge.callHandler('requestAppStoreReview', {}, function(response) {
      if (response.success) {
        console.log('评分弹窗已显示');
      } else {
        console.error('评分请求失败:', response.message);
      }
    });
  });

  // 方案 2：跳转 App Store
  document.getElementById('rateInStoreButton').addEventListener('click', function() {
    bridge.callHandler('openAppStoreReviewPage', { appId: '6738596193' }, function(response) {
      if (response.success) {
        console.log('已跳转到 App Store');
      } else {
        console.error('跳转失败:', response.message);
      }
    });
  });
});
```

### 推荐使用策略

```javascript
// 智能评分策略：先尝试应用内评分，如果用户多次未响应，再提供跳转选项
function requestRating() {
  const ratingAttempts = localStorage.getItem('ratingAttempts') || 0;

  if (ratingAttempts < 3) {
    // 前 3 次使用应用内评分
    window.WebViewJavascriptBridge.callHandler('requestAppStoreReview', {}, function(response) {
      localStorage.setItem('ratingAttempts', parseInt(ratingAttempts) + 1);
    });
  } else {
    // 3 次后提供跳转选项
    if (confirm('感谢您的支持！是否前往 App Store 为我们评分？')) {
      window.WebViewJavascriptBridge.callHandler('openAppStoreReviewPage', {}, function(response) {
        console.log('跳转结果:', response);
      });
    }
  }
}
```

### React/Vue 示例

```javascript
// React 示例
const RatingComponent = () => {
  const handleInAppRating = () => {
    if (window.WebViewJavascriptBridge) {
      window.WebViewJavascriptBridge.callHandler(
        'requestAppStoreReview',
        {},
        (response) => {
          if (response.success) {
            console.log('评分弹窗已显示');
          }
        }
      );
    }
  };

  const handleStoreRating = () => {
    if (window.WebViewJavascriptBridge) {
      window.WebViewJavascriptBridge.callHandler(
        'openAppStoreReviewPage',
        { appId: '6738596193' },
        (response) => {
          if (response.success) {
            console.log('已跳转到 App Store');
          }
        }
      );
    }
  };

  return (
    <div>
      <button onClick={handleInAppRating}>应用内评分</button>
      <button onClick={handleStoreRating}>前往 App Store 评分</button>
    </div>
  );
};

// Vue 示例
export default {
  methods: {
    rateInApp() {
      if (window.WebViewJavascriptBridge) {
        window.WebViewJavascriptBridge.callHandler(
          'requestAppStoreReview',
          {},
          (response) => {
            if (response.success) {
              this.$message.success('感谢您的支持！');
            }
          }
        );
      }
    },
    rateInStore() {
      if (window.WebViewJavascriptBridge) {
        window.WebViewJavascriptBridge.callHandler(
          'openAppStoreReviewPage',
          { appId: '6738596193' },
          (response) => {
            if (response.success) {
              this.$message.success('正在跳转到 App Store...');
            }
          }
        );
      }
    }
  }
}
```

## 重要说明

### 方案 1 限制（应用内评分）

1. **频率限制**：Apple 对评分弹窗有严格的频率限制，一年内最多显示 3 次
2. **用户控制**：用户可以在系统设置中关闭应用内评分请求
3. **不保证显示**：即使调用成功，系统也可能不显示弹窗（基于用户行为和频率限制）

### 方案 2 说明（跳转 App Store）

1. **无频率限制**：可以随时调用，不受系统限制
2. **需要 App ID**：默认使用 `6738596193`，可以通过参数自定义
3. **用户体验**：会离开应用跳转到 App Store，体验相对较差

### 最佳实践

1. **优先使用方案 1**：在用户完成重要操作或体验良好时请求评分
2. **方案 2 作为补充**：当方案 1 多次未显示时，可以提供方案 2 作为备选
3. **不要频繁调用**：避免在短时间内多次调用
4. **不要强制**：不要在用户拒绝后立即再次请求
5. **智能策略**：结合用户行为和应用使用情况，选择合适的时机

## 响应格式

```javascript
{
  success: true,  // 布尔值，表示是否成功调用
  message: "评分请求已发送"  // 字符串，描述信息
}
```

## 测试建议

1. 在开发环境中，评分弹窗可能不会显示（这是正常的）
2. 在 TestFlight 或正式版本中测试效果更准确
3. 可以通过日志查看调用是否成功：查看 Xcode 控制台的 "requestAppStoreReview called" 日志

## 相关文档

- [Apple 官方文档 - SKStoreReviewController](https://developer.apple.com/documentation/storekit/skstorereviewcontroller)
- [App Store 评分和评论指南](https://developer.apple.com/app-store/ratings-and-reviews/)
