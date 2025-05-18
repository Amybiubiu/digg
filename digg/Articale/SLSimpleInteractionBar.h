//
//  SLSimpleInteractionBar.h
//  digg
//
//  Created by Tim Bao on 2025/5/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLSimpleInteractionBar;

@protocol SLSimpleInteractionBarDelegate <NSObject>

@optional
/**
 * 点赞按钮点击回调
 * @param interactionBar 交互栏实例
 * @param selected 是否选中状态
 */
- (void)interactionBar:(SLSimpleInteractionBar *)interactionBar didTapLikeWithSelected:(BOOL)selected;

/**
 * 不喜欢按钮点击回调
 * @param interactionBar 交互栏实例
 * @param selected 是否选中状态
 */
- (void)interactionBar:(SLSimpleInteractionBar *)interactionBar didTapDislikeWithSelected:(BOOL)selected;

/**
 * 回复按钮点击回调
 * @param interactionBar 交互栏实例
 */
- (void)interactionBarDidTapReply:(SLSimpleInteractionBar *)interactionBar;

@end

@interface SLSimpleInteractionBar : UIView

@property (nonatomic, weak) id<SLSimpleInteractionBarDelegate> delegate;

/**
 * 初始化交互栏
 * @param frame 视图尺寸
 * @return 交互栏实例
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * 更新点赞数量
 * @param number 新的数字
 */
- (void)updateLikeNumber:(NSInteger)number;

/**
 * 更新不喜欢数量
 * @param number 新的数字
 */
- (void)updateDislikeNumber:(NSInteger)number;

/**
 * 设置点赞选中状态
 * @param selected 是否选中
 */
- (void)setLikeSelected:(BOOL)selected;

/**
 * 设置不喜欢选中状态
 * @param selected 是否选中
 */
- (void)setDislikeSelected:(BOOL)selected;

/**
 * 获取点赞选中状态
 * @return 是否选中
 */
- (BOOL)isLikeSelected;

/**
 * 获取不喜欢选中状态
 * @return 是否选中
 */
- (BOOL)isDislikeSelected;

@end

NS_ASSUME_NONNULL_END