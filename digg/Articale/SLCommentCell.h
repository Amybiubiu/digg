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

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, strong) SLCommentEntity *comment;
@property (nonatomic, strong, readwrite) NSMutableArray<UIView *> *replyViews;

@property (nonatomic, copy) void (^replyHandler)(SLCommentEntity *comment);
@property (nonatomic, copy) void (^likeHandler)(SLCommentEntity *comment);
@property (nonatomic, copy) void (^expandHandler)(void);

- (void)setupUI;

/**
 * 更新评论单元格
 * @param comment 评论实体
 */
 - (void)updateWithComment:(SLCommentEntity *)comment;
 
- (void)updateRepliesWithList:(NSArray<SLCommentEntity *> *)replyList isCollapsed:(BOOL)isCollapsed totalCount:(NSInteger)totalCount;

@end

NS_ASSUME_NONNULL_END
