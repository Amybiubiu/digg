//
//  SLGeneralMacro.h
//  digg
//
//  Created by hey on 2024/9/26.
//

#ifndef SLGeneralMacro_h
#define SLGeneralMacro_h

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CaocaoCarMessageListRefreshType) {
    CaocaoCarMessageListRefreshTypeRefresh = 0,
    CaocaoCarMessageListRefreshTypeLoadMore,
};

//是否是iphone
#define kIsiPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//判断是否是ipad
#define kISiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define iPhoneX    phoneIsX()

#define kiPhoneXBottomMargin (phoneIsX()?34.f:0.f)

// 状态栏高度
#define STATUSBAR_HEIGHT (phoneStatusBarHeight())
// 导航栏高度
#define NAVBAR_HEIGHT (44.f + STATUSBAR_HEIGHT)

//UIApplication
#define kApplication        [UIApplication sharedApplication]
//kKeyWindow
#define kKeyWindow          [UIApplication sharedApplication].keyWindow
//delegate
#define kAppDelegate        [UIApplication sharedApplication].delegate


#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// 屏幕宽度
#define FULL_WIDT  [UIScreen mainScreen].bounds.size.width

//16进制颜色
#define Color16(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//16进制颜色和透明度
#ifndef Color16A
    #define Color16A(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]
#endif

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define RGB(r,g,b) RGBA(r,g,b,1.0f)

#ifndef weakobj
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakobj(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakobj(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakobj(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakobj(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongobj
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongobj(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongobj(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongobj(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongobj(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

#define CELL_CONTENT_V_SPACE 10

static inline BOOL phoneIsX(void) {
    if (@available(iOS 11.0, *)) {
        if (kIsiPhone && ([kAppDelegate window].safeAreaInsets.bottom > 0.f)) {
            return YES;
        }
        return NO;
    }
    return NO;
}

static inline CGFloat phoneStatusBarHeight(void) {
    CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height;
    if (height <= 0.f) {
        if (iPhoneX) {
            return 44.f;
        }
        return 20.f;
    }
    return height;
}


#import <Foundation/Foundation.h>

static inline BOOL YX_IS_EMPTY(id thing) {
    return thing == nil ||
    ([thing isEqual:[NSNull null]]) ||
    ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) ||
    ([thing respondsToSelector:@selector(count)]  && [(NSArray *)thing count] == 0);
}

static inline bool stringIsEmpty(NSString *string) {
    return (![string isKindOfClass:[NSString class]] || [string isKindOfClass:[NSNull class]] || string == nil || [string length] < 1 ? YES : NO );
}
static inline bool arrayIsEmpty(NSArray *array) {
    return (![array isKindOfClass:[NSArray class]] || array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0);
}

static inline bool dictIsEmpty(NSDictionary *dic) {
    return (![dic isKindOfClass:[NSDictionary class]] || dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys.count == 0);
}

#endif /* SLGeneralMacro_h */


