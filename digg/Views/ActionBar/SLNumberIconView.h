//
//  SLNumberIconView.h
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLNumberIconItem;
@class SLNumberIconView;

// 点击回调代理
@protocol SLNumberIconViewDelegate <NSObject>

@optional
/**
 * 点击事件回调
 * @param numberIconView 组件实例
 * @param index 被点击的项索引
 */
- (void)numberIconView:(SLNumberIconView *)numberIconView didClickAtIndex:(NSInteger)index;

@end

// 数字图标项配置
@interface SLNumberIconItem : NSObject

@property (nonatomic, assign) NSInteger number;                 // 显示的数字，为0则不显示
@property (nonatomic, strong) UIImage *normalImage;              // 正常状态图标
@property (nonatomic, strong, nullable) UIImage *selectedImage;    // 选中状态图标
@property (nonatomic, strong) UIColor *numberColor;              // 数字颜色
@property (nonatomic, strong) UIColor *iconColor;                // 图标颜色
@property (nonatomic, assign) BOOL isSelected;                   // 是否选中状态
@property (nonatomic, copy, nullable) NSString *customText;      // 自定义文本，用于"查看"等没有图标的项                 // 是否选中状态
@property (nonatomic, assign) BOOL hidden;

/**
 * 创建数字图标项
 * @param number 显示的数字
 * @param normalImage 正常状态图标
 * @param selectedImage 选中状态图标
 * @return 数字图标项实例
 */
+ (instancetype)itemWithNumber:(NSInteger)number 
                   normalImage:(UIImage *)normalImage 
                 selectedImage:(nullable UIImage *)selectedImage;

@end

// 主视图
@interface SLNumberIconView : UIView

@property (nonatomic, weak) id<SLNumberIconViewDelegate> delegate;
@property (nonatomic, strong) NSArray<SLNumberIconItem *> *items;  // 数据项数组
@property (nonatomic, assign) CGFloat spacing;                     // 每组之间的间距
@property (nonatomic, assign) CGFloat itemSpacing;                 // 数字和图标之间的间距
@property (nonatomic, assign) CGFloat fontSize;                    // 数字字体大小
@property (nonatomic, assign) CGFloat iconSize;                    // 图标大小
@property (nonatomic, assign) CGFloat touchAreaExtension;          // 点击区域扩展大小

/**
 * 创建数字图标视图
 * @param frame 视图尺寸
 * @param items 数据项数组
 * @return 数字图标视图实例
 */
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray<SLNumberIconItem *> *)items;

/**
 * 更新指定索引的数字
 * @param number 新的数字
 * @param index 索引
 */
- (void)updateNumber:(NSInteger)number atIndex:(NSInteger)index;

/**
 * 更新指定索引的选中状态
 * @param selected 是否选中
 * @param index 索引
 */
- (void)setSelected:(BOOL)selected atIndex:(NSInteger)index;

/**
 * 获取指定索引的选中状态
 * @param index 索引
 * @return 是否选中
 */
- (BOOL)isSelectedAtIndex:(NSInteger)index;

- (void)setItemHidden:(BOOL)hidden atIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
