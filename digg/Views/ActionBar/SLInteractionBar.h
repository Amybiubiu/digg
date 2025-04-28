//
//  SLInteractionBar.h
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import <UIKit/UIKit.h>
#import "SLNumberIconView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SLInteractionType) {
    SLInteractionTypeLike,       // 点赞
    SLInteractionTypeDislike,    // 不喜欢
    SLInteractionTypeComment,    // 评论
    SLInteractionTypeCustom      // 自定义
};

@class SLInteractionBar;

@protocol SLInteractionBarDelegate <NSObject>

@optional
/**
 * 交互事件回调
 * @param interactionBar 交互栏实例
 * @param type 交互类型
 * @param selected 是否选中状态
 */
- (void)interactionBar:(SLInteractionBar *)interactionBar 
       didTapItemWithType:(SLInteractionType)type 
                 selected:(BOOL)selected;

@end

@interface SLInteractionBar : UIView <SLNumberIconViewDelegate>

@property (nonatomic, weak) id<SLInteractionBarDelegate> delegate;
@property (nonatomic, strong, readonly) SLNumberIconView *numberIconView;
@property (nonatomic, assign) CGFloat spacing;           // 组件间距
@property (nonatomic, assign) CGFloat itemSpacing;       // 数字和图标间距
@property (nonatomic, assign) CGFloat touchAreaExtension; // 点击区域扩展

/**
 * 初始化交互栏
 * @param frame 视图尺寸
 * @param types 需要显示的交互类型数组
 * @return 交互栏实例
 */
- (instancetype)initWithFrame:(CGRect)frame interactionTypes:(NSArray<NSNumber *> *)types;

/**
 * 更新指定类型的数字
 * @param number 新的数字
 * @param type 交互类型
 */
- (void)updateNumber:(NSInteger)number forType:(SLInteractionType)type;

/**
 * 更新指定类型的选中状态
 * @param selected 是否选中
 * @param type 交互类型
 */
- (void)setSelected:(BOOL)selected forType:(SLInteractionType)type;

/**
 * 获取指定类型的选中状态
 * @param type 交互类型
 * @return 是否选中
 */
- (BOOL)isSelectedForType:(SLInteractionType)type;

/**
 * 添加自定义交互项
 * @param item 数字图标项
 * @param type 交互类型，应使用SLInteractionTypeCustom
 */
- (void)addCustomItem:(SLNumberIconItem *)item forType:(SLInteractionType)type;

- (void)hideItemForType:(SLInteractionType)type;
- (void)showItemForType:(SLInteractionType)type;

@end

NS_ASSUME_NONNULL_END
