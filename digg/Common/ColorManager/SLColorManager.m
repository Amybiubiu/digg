//
//  SLColorManager.m
//  digg
//
//  Created by Tim Bao on 2025/2/7.
//

#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@implementation SLColorManager

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

// 示例颜色：主背景颜色
+ (UIColor *)primaryBackgroundColor {
    UIColor *lightColor = [UIColor whiteColor];
    UIColor *darkColor = Color16(0x131313);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

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

+ (UIColor *)tabbarBackgroundColor {
    UIColor *lightColor = [UIColor whiteColor];
    UIColor *darkColor = Color16(0x282828);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tabbarNormalTextColor {
    UIColor *lightColor = Color16(0x5B5B5B);
    UIColor *darkColor = Color16A(0xFFFFFF, 0.4);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tabbarSelectedTextColor {
    UIColor *lightColor = Color16(0x000000);
    UIColor *darkColor = Color16(0xFFFFFF);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

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
    UIColor *lightColor = Color16A(0xEA2A2A, 0.1);
    UIColor *darkColor = Color16A(0xFF3468, 0.1);
    return [self colorForLightMode:lightColor darkMode:darkColor];
}

+ (UIColor *)tagTextColor {
    UIColor *lightColor = Color16(0xEA2A2A);
    UIColor *darkColor = Color16(0xFF3468);
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

@end
