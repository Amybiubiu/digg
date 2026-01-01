//
//  UIView+SLToast.h
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SLToast)

/**
 * 在视图上显示一个简单的 Toast 消息
 * @param message 要显示的消息
 * @param duration 显示持续时间（秒）
 */
- (void)sl_showToast:(NSString *)message duration:(NSTimeInterval)duration;

/**
 * 在视图上显示一个简单的 Toast 消息，使用默认持续时间（2秒）
 * @param message 要显示的消息
 */
- (void)sl_showToast:(NSString *)message;

@end

NS_ASSUME_NONNULL_END