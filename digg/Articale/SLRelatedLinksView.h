//
//  SLRelatedLinksView.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>
#import "SLArticleEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLRelatedLinksView : UIView

/**
 * 设置相关链接数据
 * @param referList 相关链接列表
 */
- (void)setupWithReferList:(NSArray<SLReferEntity *> *)referList;

/**
 * 链接点击回调
 */
@property (nonatomic, copy) void (^linkClickHandler)(SLReferEntity *refer);

/**
 * 获取内容高度
 */
- (CGFloat)getContentHeight;

@end

NS_ASSUME_NONNULL_END
