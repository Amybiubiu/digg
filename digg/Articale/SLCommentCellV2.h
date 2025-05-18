//
//  SLCommentCell.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>
#import "SLHomeTagViewV2.h"
#import "SLSimpleInteractionBar.h"

NS_ASSUME_NONNULL_BEGIN

@class SLCommentEntity;

@interface SLCommentCellV2 : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UITextView *contentLabel;
@property (nonatomic, strong) SLSimpleInteractionBar *interactionBar;
@property (nonatomic, strong) SLHomeTagViewV2 *tagView;
@property (nonatomic, strong) SLCommentEntity *comment;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger row;

@property (nonatomic, copy) void (^replyHandler)(SLCommentEntity *comment, NSInteger section);
@property (nonatomic, copy) void (^likeHandler)(SLCommentEntity *comment, NSInteger section, NSInteger row, BOOL selected);
@property (nonatomic, copy) void (^dislikeHandler)(SLCommentEntity *comment, NSInteger section, NSInteger row, BOOL selected);
@property (nonatomic, copy) void (^linkTapHandler)(NSURL *url);

- (void)setupUI;

/**
 * 更新评论单元格
 * @param comment 评论实体
 */
- (void)updateWithComment:(SLCommentEntity *)comment authorId:(NSString *)authorId contentWidth:(CGFloat)width;

/**
 * 更新点赞/点踩单元格
 * @param comment 评论实体
 */
- (void)updateLikeStatus:(SLCommentEntity *)comment;
 

@end

NS_ASSUME_NONNULL_END
