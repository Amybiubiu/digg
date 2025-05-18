//
//  SLTagListView.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTagListView : UIView

/**
 * 设置标签数据
 * @param tags 标签数组
 */
- (void)setTags:(NSArray<NSString *> *)tags;

/**
 * 标签点击回调
 */
@property (nonatomic, copy) void (^tagClickHandler)(NSString *tag);

/**
 * 获取标签列表的实际高度
 * @return 标签列表的高度
 */
 - (CGFloat)getContentHeight;

@end

NS_ASSUME_NONNULL_END