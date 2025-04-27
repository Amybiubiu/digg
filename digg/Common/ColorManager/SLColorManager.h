//
//  SLColorManager.h
//  digg
//
//  Created by Tim Bao on 2025/2/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLColorManager : NSObject 

// 获取颜色方法
+ (UIColor *)colorForLightMode:(UIColor *)lightColor darkMode:(UIColor *)darkColor;

// 示例颜色 (可以添加更多颜色)
+ (UIColor *)primaryBackgroundColor;
//dark:0xFFFFFF & 0x333333
+ (UIColor *)primaryTextColor;
//dark:0xFFFFFF & 0x999999
+ (UIColor *)secondaryTextColor;

+ (UIColor *)tabbarBackgroundColor;
+ (UIColor *)tabbarNormalTextColor;
+ (UIColor *)tabbarSelectedTextColor;

//Category or Segment
+ (UIColor *)categoryNormalTextColor;
+ (UIColor *)categorySelectedTextColor;

//tag
+ (UIColor *)tagBackgroundTextColor;
+ (UIColor *)tagV2BackgroundTextColor;
+ (UIColor *)tagTextColor;
+ (UIColor *)tagV2TextColor;

//cell
+ (UIColor *)cellTitleColor;
+ (UIColor *)cellContentColor;
+ (UIColor *)cellDivideLineColor;
+ (UIColor *)cellNickNameColor;
+ (UIColor *)cellTimeColor;

//CaocaoButton
+ (UIColor *)caocaoButtonTextColor;

//link text
+ (UIColor *)lineTextColor;

//header border
+ (UIColor *)headerBorderColor;

//recorder
+ (UIColor *)recorderTextColor;
+ (UIColor *)recorderTextPlaceholderColor;
+ (UIColor *)recorderTagBgColor;
+ (UIColor *)recorderTagTextColor;
+ (UIColor *)recorderTagBorderColor;

//textview输入框相关颜色
+ (UIColor *)textViewBgColor;
+ (UIColor *)textViewPlaceholderColor;
+ (UIColor *)textViewTextColor;

@end

NS_ASSUME_NONNULL_END
