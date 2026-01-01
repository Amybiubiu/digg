//
//  UIView+Associated.m
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import "UIView+Associated.h"
#import <objc/runtime.h>

@implementation UIView (Associated)

- (void)setAssociatedObject:(id)object forKey:(NSString *)key {
    objc_setAssociatedObject(self, (__bridge const void *)(key), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObjectForKey:(NSString *)key {
    return objc_getAssociatedObject(self, (__bridge const void *)(key));
}

@end