//
//  SLZoomTransitionAnimator.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLZoomTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresenting;

@end

NS_ASSUME_NONNULL_END