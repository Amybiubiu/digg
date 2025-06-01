//
//  SLZoomTransitionAnimator.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLZoomTransitionAnimator.h"

@implementation SLZoomTransitionAnimator

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    
    if (self.isPresenting) {
        // 从小到大放大的动画
        [containerView addSubview:toView];
        
        // 设置初始状态 - 从屏幕中心开始，尺寸很小
        toView.alpha = 0.0;
        toView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        toView.center = containerView.center;
        
        // 执行动画
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             toView.alpha = 1.0;
                             toView.transform = CGAffineTransformIdentity;
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                         }];
    } else {
        // 从大到小缩小的动画
        [containerView insertSubview:toView belowSubview:fromView];
        
        // 执行动画
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             fromView.alpha = 0.0;
                             fromView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                             fromView.center = containerView.center;
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                         }];
    }
}

@end