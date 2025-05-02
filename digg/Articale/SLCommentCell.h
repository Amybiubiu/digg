//
//  SLCommentCell.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLCommentEntity;

@interface SLCommentCell : UITableViewCell

@property (nonatomic, copy) void (^replyHandler)(SLCommentEntity *comment);
@property (nonatomic, copy) void (^likeHandler)(SLCommentEntity *comment);

- (void)updateWithComment:(SLCommentEntity *)comment;

@end

NS_ASSUME_NONNULL_END