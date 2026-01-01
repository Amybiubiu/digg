//
//  NSString+UXing.h
//  GreenBusiness
//
//  Created by luminary on 2016/11/29.
//  Copyright © 2016年 UXing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (UXing)


/// 字符串拼接的safe版
/// @param aString aString description
- (NSString *)stringBySafeAppendingString:(NSString *)aString;

/**
 md5加密

 @return 加密之后的字符串
 */
- (NSString *)uxing_md5hashString;

/**
 base64加密

 @return 加密之后的字符串
 */
- (NSString *)uxing_base64encode;

/**
 urlencode

 @return encode之后的字符串
 */
- (NSString *)uxing_urlencode;

/**
 urldecode
 
 @return decode之后的字符串
 */
- (NSString *)uxing_urldecode;

/**
 UUID

 @return UUID string
 */
+ (NSString *)uxing_UUID;

/**
 拼接URL

 @param baseURL 原始URL
 @param parameters 参数
 @return 拼接的URL
 */
+ (NSString *)combineURLWithBaseURL:(NSString *)baseURL parameters:(NSDictionary *)parameters;

/**
 String 转JSON

 @return json object
 */
- (id)jsonObject;

/**
 jsonFragment

 @return jsonFragment
 */
- (id)jsonFragment;

/**
 计算文字对应的宽度

 @param font 字体大小
 @return 宽度
 */
- (CGFloat)widthForFont:(UIFont *)font;

/**
 计算文字对应的高度

 @param font 字体大小
 @param width 最大宽度
 @return 高度
 */
- (CGFloat)heightForFont:(UIFont *)font width:(CGFloat)width;

+ (NSString *)timeStmpWith:(NSTimeInterval)gmtCreate;

- (NSAttributedString *)attributedStringFromHTML;

+ (NSString *)smartTimeFormatWith:(NSTimeInterval)gmtCreate;

@end
