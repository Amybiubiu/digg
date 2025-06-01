//
//  SLZoomTransitionDelegate.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLZoomTransitionDelegate.h"
#import "SLZoomTransitionAnimator.h"

@implementation SLZoomTransitionDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    SLZoomTransitionAnimator *animator = [[SLZoomTransitionAnimator alloc] init];
    animator.isPresenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SLZoomTransitionAnimator *animator = [[SLZoomTransitionAnimator alloc] init];
    animator.isPresenting = NO;
    return animator;
}

@end