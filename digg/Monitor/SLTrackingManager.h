//
//  SLTrackingManager.h
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 埋点事件类型
typedef NS_ENUM(NSInteger, SLTrackingEventType) {
    SLTrackingEventTypeClick,       // 点击事件
    SLTrackingEventTypePageView,    // 页面浏览
    SLTrackingEventTypeExposure     // 视图曝光
};

@interface SLTrackingManager : NSObject

+ (instancetype)sharedInstance;

#pragma mark - 事件埋点
/**
 * 记录点击事件
 * @param eventName 事件名称
 * @param parameters 事件参数
 */
- (void)trackEvent:(NSString *)eventName parameters:(nullable NSDictionary *)parameters;

#pragma mark - 页面浏览埋点
/**
 * 记录页面浏览开始
 * @param viewController 页面控制器
 */
- (void)trackPageViewBegin:(UIViewController *)viewController;

/**
 * 记录页面浏览结束
 * @param viewController 页面控制器
 * @param parameters 附加参数
 */
- (void)trackPageViewEnd:(UIViewController *)viewController parameters:(nullable NSDictionary *)parameters;

/**
 * 记录页面浏览开始
 * @param viewController 页面控制器
 * @param uniqueIdentifier 页面唯一标识符（可选，用于区分同一类型不同数据的页面）
 */
- (void)trackPageViewBegin:(UIViewController *)viewController uniqueIdentifier:(nullable NSString *)uniqueIdentifier;

/**
 * 记录页面浏览结束
 * @param viewController 页面控制器
 * @param uniqueIdentifier 页面唯一标识符（可选，用于区分同一类型不同数据的页面）
 * @param parameters 附加参数
 */
- (void)trackPageViewEnd:(UIViewController *)viewController uniqueIdentifier:(nullable NSString *)uniqueIdentifier parameters:(nullable NSDictionary *)parameters;

#pragma mark - 视图曝光埋点
// 修改视图曝光埋点接口
/**
 * 记录视图曝光（单一接口）
 * @param identifier 视图标识符
 * @param duration 曝光时长（秒）
 * @param parameters 附加参数
 */
- (void)trackViewExposure:(NSString *)identifier
                 duration:(NSUInteger)duration
               parameters:(nullable NSDictionary *)parameters;

#pragma mark - 配置
/**
 * 设置用户ID
 */
- (void)setUserId:(NSString *)userId;

/**
 * 设置公共参数，所有事件都会附加这些参数
 */
- (void)setCommonParameters:(NSDictionary *)parameters;

/**
 * 手动触发数据上传
 */
- (void)flush;

@end

NS_ASSUME_NONNULL_END
