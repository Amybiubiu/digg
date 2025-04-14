//
//  UIFont+PingFang.h
//  digg
//
//  Created by Tim Bao on 2025/4/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PingFangFontWeight) {
    PingFangFontWeightThin,       // 极细体
    PingFangFontWeightLight,      // 细体
    PingFangFontWeightRegular,    // 常规体
    PingFangFontWeightMedium,     // 中黑体
    PingFangFontWeightSemibold,   // 中粗体
    PingFangFontWeightBold        // 粗体
};

@interface UIFont (PingFang)

/**
 * 创建苹方字体
 * @param size 字体大小
 * @param weight 字体粗细
 * @return 苹方字体
 */
+ (UIFont *)pingFangFontWithSize:(CGFloat)size weight:(PingFangFontWeight)weight;

/**
 * 创建苹方极细体
 * @param size 字体大小
 * @return 苹方极细体
 */
+ (UIFont *)pingFangThinWithSize:(CGFloat)size;

/**
 * 创建苹方细体
 * @param size 字体大小
 * @return 苹方细体
 */
+ (UIFont *)pingFangLightWithSize:(CGFloat)size;

/**
 * 创建苹方常规体
 * @param size 字体大小
 * @return 苹方常规体
 */
+ (UIFont *)pingFangRegularWithSize:(CGFloat)size;

/**
 * 创建苹方中黑体
 * @param size 字体大小
 * @return 苹方中黑体
 */
+ (UIFont *)pingFangMediumWithSize:(CGFloat)size;

/**
 * 创建苹方中粗体
 * @param size 字体大小
 * @return 苹方中粗体
 */
+ (UIFont *)pingFangSemiboldWithSize:(CGFloat)size;

/**
 * 创建苹方粗体
 * @param size 字体大小
 * @return 苹方粗体
 */
+ (UIFont *)pingFangBoldWithSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END