# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## vide coding rules
1. 我是一个前端工程师，对于ios还没有入门，所以当我在描述一些样式或者交互时，可能会用前端技术栈描述给你，去实现ios代码。
2. 对于我发送给你的rgba色值，你需要帮我转成hex色值，因为hex色值在ios上语法更简单。
3. 对于我发送 cli:record 时，你需要把上次回话总结到 doc/learn/[title].md 下
## Project Overview

This is an iOS native application built with Objective-C (primary) and Swift (secondary), using UIKit framework. It's a content consumption and social platform featuring news/articles, user profiles, and content creation capabilities.

## Key Commands

### Setup and Dependencies
```bash
# Install CocoaPods dependencies (required before first build)
pod install

# Update dependencies
pod update
```

### Build Commands
```bash
# Build for Debug
xcodebuild -workspace digg.xcworkspace -scheme digg -configuration Debug build

# Build for Release
xcodebuild -workspace digg.xcworkspace -scheme digg -configuration Release build

# Build for iPhone Simulator
xcodebuild -workspace digg.xcworkspace -scheme digg -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Testing
```bash
# Run all tests
xcodebuild -workspace digg.xcworkspace -scheme digg -destination 'platform=iOS Simulator,name=iPhone 15' test

# Run unit tests only
xcodebuild -workspace digg.xcworkspace -scheme digg -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:diggTests

# Run UI tests only
xcodebuild -workspace digg.xcworkspace -scheme digg -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:diggUITests
```

### Distribution
```bash
# Create archive for App Store
xcodebuild -workspace digg.xcworkspace -scheme digg -configuration Release archive -archivePath build/digg.xcarchive
```

## Architecture Overview

### Navigation Structure
The app uses a tab-based navigation with 4 main sections managed by `SLTabbarController`:

#### Main Tab Bar Controllers
1. **首页 (Home)**: `SLHomePageViewController` - Content feed with segmented tabs (今天/发现/为你)
   - Contains: `SLHomePageNewsViewController` (今天/发现 tabs), `SLHomeWebViewController` (为你 tab)
2. **关注 (Following)**: `SLConcernedViewController` - User's followed content (requires login)
3. **记录 (Record)**: `SLRecordViewController` - Content creation (requires login)
4. **我的 (Profile)**: `SLProfileViewController` - User profile and settings
   - Contains: `SLEditProfileViewController` (profile editing)

#### All View Controllers by Category

**Home & Content**
- `SLHomePageViewController` - Main home page with tab segments
- `SLHomePageNewsViewController` - News list for 今天/发现 tabs
- `SLHomeWebViewController` - Web-based content for 为你 tab
- `SLArticleDetailViewControllerV2` - Article detail page

**User & Profile**
- `SLProfileViewController` - User profile page
- `SLEditProfileViewController` - Profile editing page
- `SLConcernedViewController` - Following/followers content

**Content Creation**
- `SLRecordViewController` - Content creation/record page

**Tag Management**
- `SLTagListContainerViewController` - Tag list management

**Common & Shared**
- `SLWebViewController` - Base web view controller
- `SLCommentInputViewController` - Comment input modal
- `SLAddLinkViewController` - Add link dialog
- `CaocaoRootViewController` - Base controller with loading states
- `SLNavigationController` - Custom navigation controller

**Third Party Integrations**
- `TZImagePickerController` - Image picker (from TZImagePickerController library)
- `TZPhotoPickerController` - Photo selection
- `TZPhotoPreviewController` - Photo preview
- `TZVideoPlayerController` - Video player
- `TZVideoCropController` - Video cropping
- `TZGifPhotoPreviewController` - GIF preview

### Key Design Patterns
- **MVVM**: ViewModels handle business logic (see `SLHomePageViewModel`)
- **Singleton**: User state via `SLUser.defaultUser`
- **Observer**: Authentication events through `NSNotificationCenter`
- **Base Controller**: `CaocaoRootViewController` provides standardized loading states

### Data Flow
- **User Management**: Token-based authentication with local persistence
- **Content Loading**: Mix of native API calls and web-based content
- **State Management**: View controller caching to prevent unnecessary recreation

### Environment Configuration
API endpoints are configured in `EnvConfigHeader.h`:
- H5 content: `http://39.106.147.0`
- API services: `http://39.106.147.0`
- App services: `http://47.96.25.87:9000`

### H5 Content Loading Pattern
The app uses a standard pattern for loading H5 content through `SLWebViewController`:
```objc
[userVC startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/my",H5BaseUrl]];
```
This pattern constructs URLs by appending the specific path (e.g., `/my`, `/login`) to the `H5BaseUrl` macro defined in `EnvConfigHeader.h`.

### Important Technical Details
- **Workspace**: Always use `digg.xcworkspace` (not `.xcodeproj`) after `pod install`
- **Minimum iOS**: 14.0+ (deployment target)
- **Mixed Language**: Objective-C primary, Swift components in Quickly framework
- **Localization**: English (Base) and Chinese Simplified (zh-Hans)
- **Analytics**: Umeng SDK integrated for tracking and performance monitoring

### Key Dependencies
- **UI**: JXCategoryView, Masonry/SnapKit, DZNEmptyDataSet
- **Networking**: AFNetworking
- **Images**: SDWebImage, Kingfisher, YYImage
- **Text**: YYText, MPITextKit
- **Animation**: Facebook's pop library
- **Keyboard**: IQKeyboardManager

## Native iOS to H5 Communication Protocol

This application implements bidirectional communication between native iOS and H5 content using **WebViewJavascriptBridge** library.

### Communication Architecture

**Primary Bridge Implementation**: `SLWebViewController.m` lines 272-494
- Uses WebViewJavascriptBridge for JavaScript ↔ Native communication
- Implements `WKScriptMessageHandler` protocol
- Supports both synchronous and asynchronous communication patterns

### Native → H5 Communication

**Method Calls from Native to JavaScript:**
```objc
[bridge callHandler:@"handlerName" data:params responseCallback:^(id responseData) {
    // Handle response from JavaScript
}];
```

**Key Native-to-H5 Handlers:**
- `onCommentInputClose`: Comment submission callback
- Document title extraction via `evaluateJavaScript`

### H5 → Native Communication

**Registered Message Handlers:**
```objc
[bridge registerHandler:@"openRecord" handler:^
(id data) {
    // Handle response from JavaScript
}]
```
1. **Navigation Handlers:**
   - `backToHomePage`: Navigate to home screen
   - `page_back`: Go back one page
   - `closeH5`: Close current H5 page
   - `jumpToH5`: Navigate to new H5 URL (supports internal/external URLs)

2. **User Authentication:**
   - `userLogin`: Handle user login with token/userId
   - `userLogout`: Handle user logout

3. **Content Navigation:**
   - `openUserPage`: Open user profile page
   - `openRecord`: Open content creation page
   - `openTagDetail`: Open tag detail page
   - `openArticlePage`: Open article detail page

4. **UI Interactions:**
   - `openCommentInput`: Show comment input modal with placeholder/lastInput

### Authentication Integration

**Token-Based Authentication via Cookies:**
```objc
// Cookie injection pattern in SLWebViewController.m
NSMutableDictionary *cookieProps = [NSMutableDictionary dictionary];
cookieProps[NSHTTPCookieName] = @"bp-token";
cookieProps[NSHTTPCookieValue] = token;
cookieProps[NSHTTPCookieDomain] = [NSURL URLWithString:url].host;
cookieProps[NSHTTPCookiePath] = @"/";
```

**Login Flow:**
1. H5 calls `userLogin` handler with userId and token
2. Native saves user info to `SLUser.defaultUser`
3. Posts `WebViewShouldReloadAfterLogin` notification
4. Other webviews refresh automatically

### WebView Configuration

**Shared Configuration:**
- Shared `WKProcessPool` for cookie persistence
- Default `WKWebsiteDataStore` for shared storage
- Custom User Agent: `infoflow` suffix
- JavaScript capabilities enabled
- Allows inline media playback

### Implementation Pattern

**Standard H5 Loading Pattern:**
```objc
[userVC startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/path", H5BaseUrl]];
```

**URL Construction:**
- H5BaseUrl: `http://39.106.147.0` (from EnvConfigHeader.h)
- Append specific paths: `/my`, `/login`, etc.

### Authentication Flow
Login is required for Following and Record tabs. Authentication state is managed through `SLUser` singleton with automatic restoration from local storage. Login flows use web-based authentication through `SLWebViewController`.