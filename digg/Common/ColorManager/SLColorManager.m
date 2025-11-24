//
//  SLColorManager.m
//  digg
//
//  Created by Tim Bao on 2025/2/7.
//

#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@implementation SLColorManager

// 主题色 - rgb(73, 119, 73) = #497749
+ (UIColor *)themeColor {
    return Color16(0x497749);
}

// 适配暗黑模式的通用方法
+ (UIColor *)colorForLightMode:(UIColor *)lightColor darkMode:(UIColor *)darkColor {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return darkColor;
        } else {
            return lightColor;
        }
    }];
}

// 示例颜色：主背景颜色 - 已去除暗黑模式适配，固定为 #F3F1EE
+ (UIColor *)primaryBackgroundColor {
    return Color16(0xF3F1EE);
}

/* 原来的暗黑模式适配代码 - 已注释
// 示例颜色：主背景颜色
+ (UIColor *)primaryBackgroundColor {
    UIColor *lightColor = [UIColor whiteColor];
    UIColor *darkColor = Color16(0x131313);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}
*/

//dark:0xFFFFFF & 0x333333
+ (UIColor *)primaryTextColor {
    UIColor *lightColor = Color16(0x333333);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.4);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

// 示例颜色：次要文字颜色
+ (UIColor *)secondaryTextColor {
    UIColor *lightColor = Color16(0x999999);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.3);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

// Tabbar背景色 - 已去除暗黑模式适配，固定为 #F3F1EE
+ (UIColor *)tabbarBackgroundColor {
    return Color16(0xF3F1EE);
}

/* 原来的暗黑模式适配代码 - 已注释
+ (UIColor *)tabbarBackgroundColor {
    UIColor *lightColor = [UIColor whiteColor];
    UIColor *darkColor = Color16(0x282828);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}
*/

// Tabbar普通文字颜色 - 已去除暗黑模式适配，固定为 #999999
+ (UIColor *)tabbarNormalTextColor {
    return Color16(0x999999);
}

/* 原来的暗黑模式适配代码 - 已注释
+ (UIColor *)tabbarNormalTextColor {
    UIColor *lightColor = Color16(0x5B5B5B);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.4);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}
*/

// Tabbar选中文字颜色 - 已去除暗黑模式适配，固定为主题色 #497749
+ (UIColor *)tabbarSelectedTextColor {
    return [SLColorManager themeColor];
}

/* 原来的暗黑模式适配代码 - 已注释
+ (UIColor *)tabbarSelectedTextColor {
    UIColor *lightColor = Color16(0x000000);
    UIColor *darkColor = Color16(0xFFFFFF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}
*/

+ (UIColor *)categoryNormalTextColor {
    UIColor *lightColor = Color16(0x999999);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.5);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)categorySelectedTextColor {
    UIColor *lightColor = Color16(0x000000);
    UIColor *darkColor = Color16(0xFFFFFF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagBackgroundTextColor {
    UIColor *lightColor = Color16A(0x14932A, 0.1);
    UIColor *darkColor = Color16A(0x14932A, 0.1);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagV2BackgroundTextColor {
    UIColor *lightColor = Color16A(0x14932A, 0.1);
    UIColor *darkColor = Color16A(0x14932A, 0.1);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagTextColor {
    UIColor *lightColor = Color16(0x14932A);
    UIColor *darkColor = Color16(0x14932A);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagV2TextColor {
    UIColor *lightColor = Color16(0x14932A);
    UIColor *darkColor = Color16(0x14932A);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)cellTitleColor {
    UIColor *lightColor = Color16(0x222222);
    UIColor *darkColor = Color16(0xFFFFFF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)cellContentColor {
    UIColor *lightColor = Color16(0x313131);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.8);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)cellDivideLineColor {
    UIColor *lightColor = Color16(0xEEEEEE);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.1);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)cellNickNameColor {
    UIColor *lightColor = Color16(0x666666);
    UIColor *darkColor = Color16(0xFFFFFF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)cellTimeColor {
    UIColor *lightColor = Color16(0xB6B6B6);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.3);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)caocaoButtonTextColor {
    UIColor *lightColor = Color16(0x999999);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.5);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)lineTextColor {
    UIColor *lightColor = Color16(0x307bf6);
    UIColor *darkColor = Color16(0x0B85FF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)headerBorderColor {
    UIColor *lightColor = Color16(0xFFFFFF);
    UIColor *darkColor = Color16(0x000000);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)recorderTextColor {
    UIColor *lightColor = Color16(0x313131);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.8);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)recorderTextPlaceholderColor {
    UIColor *lightColor = Color16(0xbfbfbf);
    UIColor *darkColor = Color16(0x535353);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)recorderTagBgColor {
    UIColor *lightColor = Color16(0xF4F4F4);
    UIColor *darkColor = Color16(0x454545);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)recorderTagTextColor {
    UIColor *lightColor = Color16(0x363636);
    UIColor *darkColor = Color16(0xeeeeee);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)recorderTagBorderColor {
    UIColor *lightColor = Color16A(0x000000, 0.26);
    UIColor *darkColor = Color16A(0xffffff, 0.26);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

//textview输入框相关颜色
+ (UIColor *)textViewBgColor {
    UIColor *lightColor = Color16(0xF4F4F6);
    UIColor *darkColor = Color16(0x232228);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)textViewPlaceholderColor {
    UIColor *lightColor = Color16(0xC3C3C3);
    UIColor *darkColor = Color16(0x5d5e66);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)textViewTextColor {
    UIColor *lightColor = Color16(0x333333);
    UIColor *darkColor = Color16(0xd5d7dc);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagBackgroundColor {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
            } else {
                return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            }
        }];
}

@end
