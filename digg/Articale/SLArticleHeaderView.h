//
//  SLArticleHeaderView.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleHeaderView : UIView

/**
 * 设置文章头部信息
 * @param title 文章标题
 * @param source 文章来源
 * @param avatarImage 作者头像
 * @param authorName 作者名称
 * @param publishTime 发布时间
 * @param url 原文url
 */
- (void)setupWithTitle:(NSString *)title
                source:(NSString *)source
           avatarImage:(NSString *)avatarImage
            authorName:(NSString *)authorName
           publishTime:(NSString *)publishTime
                   url:(NSString *)url;

/**
 * 阅读原文点击回调
 */
@property (nonatomic, copy) void (^readOriginalHandler)(void);

/**
 * 头像点击回调
 */
 @property (nonatomic, copy) void (^avatarClickHandler)(void);

/**
 * 获取内容高度
 */
 - (CGFloat)getContentHeight;

@end

NS_ASSUME_NONNULL_END
