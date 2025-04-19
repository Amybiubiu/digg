//
//  NSObject+SLEmpty.h
//  digg
//
//  Created by Tim Bao on 2024/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SLEmpty)

/**
 * 判断对象是否为空
 * 如果是 nil 或 NSNull，返回 YES
 * 如果是 NSString，判断是否为空字符串或只包含空格
 * 如果是 NSArray，判断是否为空数组
 * 如果是 NSDictionary，判断是否为空字典
 * 如果是 NSNumber，判断是否为 0
 * 其他类型返回 NO
 *
 * @return 如果对象为空，返回 YES；否则返回 NO
 */
- (BOOL)sl_isEmpty;

@end

NS_ASSUME_NONNULL_END