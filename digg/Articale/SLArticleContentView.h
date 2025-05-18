//
//  SLArticleContentView.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleContentView : UIView

- (CGFloat)getContentHeight;

/**
 * 设置富文本内容
 * @param richContent 富文本内容
 */
- (void)setupWithRichContent:(NSString *)richContent;

/**
 * 内容高度变化回调
 */
@property (nonatomic, copy) void (^heightChangedHandler)(CGFloat height);

@end

NS_ASSUME_NONNULL_END
