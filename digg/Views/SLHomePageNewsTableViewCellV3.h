//
//  SLHomePageNewsTableViewCellV2.h
//  digg
//
//  Created by Tim Bao on 2025/4/14.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import "SLArticleTodayEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLHomePageNewsTableViewCellV3 : UITableViewCell

@property (nonatomic, assign) NSInteger pageStyle; // 0:今天, 1:发现, 2:为你
- (void)updateWithEntity:(SLArticleTodayEntity *)entiy;

@property (nonatomic, copy) void(^likeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^dislikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^cancelLikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^cancelDisLikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^checkDetailClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^showDetailClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^labelClick)(SLArticleTodayEntity *entity);

@end

NS_ASSUME_NONNULL_END
