//
//  SLHomePageViewModel.h
//  digg
//
//  Created by hey on 2024/10/17.
//

#import <Foundation/Foundation.h>
#import "EnvConfigHeader.h"
#import "SLGeneralMacro.h"

typedef NS_ENUM(NSUInteger, HomePageStyle) {
    HomePageStyleToday = 0, //今天
    HomePageStyleDiscover = 1, //发现
    HomePageStyleForyou = 2
};


@interface SLHomePageViewModel : NSObject

//首页“为你”未读消息数量
- (void)getForYouRedPoint:(void(^)(NSInteger number, NSError *error))handler;

@end

