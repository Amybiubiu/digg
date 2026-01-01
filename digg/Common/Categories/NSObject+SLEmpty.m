//
//  NSObject+SLEmpty.m
//  digg
//
//  Created by Tim Bao on 2024/10/10.
//

#import "NSObject+SLEmpty.h"

@implementation NSObject (SLEmpty)

- (BOOL)sl_isEmpty {
    // 如果对象为 nil 或 NSNull，返回 YES
    if (self == nil || [self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    
    // 如果是字符串，判断是否为空字符串或只包含空格
    if ([self isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)self;
        return string.length == 0 || [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
    }
    
    // 如果是数组，判断是否为空数组
    if ([self isKindOfClass:[NSArray class]]) {
        return [(NSArray *)self count] == 0;
    }
    
    // 如果是字典，判断是否为空字典
    if ([self isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)self count] == 0;
    }
    
    // 如果是数字，判断是否为0
    if ([self isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)self doubleValue] == 0;
    }
    
    // 其他类型默认不为空
    return NO;
}

@end