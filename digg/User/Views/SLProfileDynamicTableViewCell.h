//
//  SLProfileDynamicTableViewCell.h
//  digg
//
//  Created by Tim Bao on 2025/1/8.
//

#import <UIKit/UIKit.h>
#import "SLArticleTodayEntity.h"


NS_ASSUME_NONNULL_BEGIN

@interface SLProfileDynamicTableViewCell : UITableViewCell

- (void)updateWithEntity:(SLArticleTodayEntity *)entiy;
- (void)resetCount;

@property (nonatomic, copy) void(^likeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^dislikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^cancelLikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^cancelDisLikeClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^checkDetailClick)(SLArticleTodayEntity *entity);

@property (nonatomic, copy) void(^showDetailClick)(SLArticleTodayEntity *entity);

@end

NS_ASSUME_NONNULL_END
