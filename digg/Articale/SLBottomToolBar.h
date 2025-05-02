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

@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *aiButton;
@property (nonatomic, strong) UIButton *shareButton;

- (void)updateLikeStatus:(BOOL)isLiked count:(NSInteger)count;
- (void)updateCommentCount:(NSInteger)count;
- (void)updateShareCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END