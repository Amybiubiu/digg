//
//  SLArticleDetailViewController.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleDetailViewControllerV2 : UIViewController

@property (nonatomic, strong) NSString *articleId;
// 添加转场代理属性
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> transitioningDelegate;

@end

NS_ASSUME_NONNULL_END
