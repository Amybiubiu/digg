//
//  SLShowMoreCell.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

@class SLCommentEntity;

NS_ASSUME_NONNULL_BEGIN

@interface SLShowMoreCell : UITableViewCell

@property (nonatomic, strong) SLCommentEntity *comment;
@property (nonatomic, copy) void (^showMoreButtonTappedHandler)(SLCommentEntity *comment);

- (void)updateWithHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
