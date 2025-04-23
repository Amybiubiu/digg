//
//  UIFont+PingFang.m
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import "UIFont+PingFang.h"

@implementation UIFont (PingFang)

+ (UIFont *)pingFangFontWithSize:(CGFloat)size weight:(PingFangFontWeight)weight {
    NSString *fontName;
    
    switch (weight) {
        case PingFangFontWeightThin:
            fontName = @"PingFangSC-Thin";
            break;
        case PingFangFontWeightLight:
            fontName = @"PingFangSC-Light";
            break;
        case PingFangFontWeightRegular:
            fontName = @"PingFangSC-Regular";
            break;
        case PingFangFontWeightMedium:
            fontName = @"PingFangSC-Medium";
            break;
        case PingFangFontWeightSemibold:
            fontName = @"PingFangSC-Semibold";
            break;
        case PingFangFontWeightBold:
            fontName = @"PingFangSC-Semibold"; // 苹方没有Bold，使用Semibold代替
            break;
        default:
            fontName = @"PingFangSC-Regular";
            break;
    }
    
    UIFont *font = nil;//[UIFont fontWithName:fontName size:size];
    
    // 如果指定字体不可用，则回退到系统字体
    if (!font) {
        switch (weight) {
            case PingFangFontWeightThin:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightThin];
                break;
            case PingFangFontWeightLight:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightLight];
                break;
            case PingFangFontWeightRegular:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
                break;
            case PingFangFontWeightMedium:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
                break;
            case PingFangFontWeightSemibold:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
                break;
            case PingFangFontWeightBold:
                font = [UIFont systemFontOfSize:size weight:UIFontWeightBold];
                break;
            default:
                font = [UIFont systemFontOfSize:size];
                break;
        }
    }
    
    return font;
}

+ (UIFont *)pingFangThinWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightThin];
}

+ (UIFont *)pingFangLightWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightLight];
}

+ (UIFont *)pingFangRegularWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightRegular];
}

+ (UIFont *)pingFangMediumWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightMedium];
}

+ (UIFont *)pingFangSemiboldWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightSemibold];
}

+ (UIFont *)pingFangBoldWithSize:(CGFloat)size {
    return [self pingFangFontWithSize:size weight:PingFangFontWeightBold];
}

@end
