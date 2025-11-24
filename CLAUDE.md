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
1. **首页 (Home)**: `SLHomePageViewController` - Content feed with segmented tabs (今天/发现/为你)
2. **关注 (Following)**: `SLConcernedViewController` - User's followed content (requires login)
3. **记录 (Record)**: `SLRecordViewController` - Content creation (requires login)
4. **我的 (Profile)**: `SLProfileViewController` - User profile and settings

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

### Authentication Flow
Login is required for Following and Record tabs. Authentication state is managed through `SLUser` singleton with automatic restoration from local storage. Login flows use web-based authentication through `SLWebViewController`.