//
//  SLTagListContainerViewController.h
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import <UIKit/UIKit.h>
#import "CaocaoRootViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SLArticleTodayEntity;

@interface SLTagListContainerViewController : CaocaoRootViewController

@property (nonatomic, strong) NSString* label;
@property (nonatomic, strong) NSString* source; //self | today | news | forYou | article
@property (nonatomic, strong) NSString* articleId;
@property (nonatomic, strong) SLArticleTodayEntity *entity;

@end

NS_ASSUME_NONNULL_END
