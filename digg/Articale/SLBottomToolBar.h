//
//  SLBottomToolBar.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLBottomToolBar;

@protocol SLBottomToolBarDelegate <NSObject>

@optional
- (void)toolBar:(SLBottomToolBar *)toolBar didClickLikeButton:(UIButton *)button;
- (void)toolBar:(SLBottomToolBar *)toolBar didClickCommentButton:(UIButton *)button;
- (void)toolBar:(SLBottomToolBar *)toolBar didClickAIButton:(UIButton *)button;
- (void)toolBar:(SLBottomToolBar *)toolBar didClickShareButton:(UIButton *)button;

@end

@interface SLBottomToolBar : UIView

@property (nonatomic, weak) id<SLBottomToolBarDelegate> delegate;

// 更新点赞状态和数量
- (void)updateLikeStatus:(BOOL)isLiked count:(NSInteger)count;

// 更新评论数量
- (void)updateCommentCount:(NSInteger)count;

// 更新分享数量
- (void)updateShareCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END