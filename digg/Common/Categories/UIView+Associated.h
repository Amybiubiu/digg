//
//  UIView+Associated.h
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Associated)

- (void)setAssociatedObject:(id)object forKey:(NSString *)key;
- (id)associatedObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END