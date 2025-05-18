//
//  NSString+UXing.m
//  GreenBusiness
//
//  Created by luminary on 2016/11/29.
//  Copyright © 2016年 UXing. All rights reserved.
//

#import "NSString+UXing.h"
#import <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSString (UXing)

- (NSString *)stringBySafeAppendingString:(NSString *)aString {
    if ((![aString isKindOfClass:[NSString class]]
         || [aString isKindOfClass:[NSNull class]]
         || aString == nil
         || [aString length] < 1)) {
        return self;
    }
    return [self stringByAppendingString:aString];
}

- (NSString *)uxing_urldecode
{
    return[self stringByRemovingPercentEncoding];
}

- (NSString *)uxing_urlencode
{
    static NSString * const kUXAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kUXAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kUXAFCharactersGeneralDelimitersToEncode stringByAppendingString:kUXAFCharactersSubDelimitersToEncode]];
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < self.length) {
        NSUInteger length = MIN(self.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [self rangeOfComposedCharacterSequencesForRange:range];
        NSString *substring = [self substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    return escaped;
}

- (NSString *)uxing_base64encode
{
    if ([self length] == 0)
        return @"";
    
    const char *source = [self UTF8String];
    long strlength  = strlen(source);
    
    char *characters = malloc(((strlength + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    
    NSUInteger length = 0;
    NSUInteger i = 0;
    
    while (i < strlength) {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        while (bufferLength < 3 && i < strlength)
            buffer[bufferLength++] = source[i++];
        characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
        characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        if (bufferLength > 1)
            characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        else characters[length++] = '=';
        if (bufferLength > 2)
            characters[length++] = encodingTable[buffer[2] & 0x3F];
        else characters[length++] = '=';
    }
    
    return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

- (NSString *)uxing_md5hashString
{
    // Create pointer to the string as UTF8
    const char* ptr = [self UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (int)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    
    return output;
}

+ (NSString *)uxing_UUID
{
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}


+ (NSString *)combineURLWithBaseURL:(NSString *)baseURL parameters:(NSDictionary *)parameters
{
    NSMutableString *combinedURL = [[NSMutableString alloc] initWithString:@""];
    if (baseURL) {
        combinedURL = [baseURL mutableCopy];
        
        if (parameters.count > 0) {
            
            NSMutableString *queryString = [[NSMutableString alloc] init];
            
            NSArray *sortedKeys =[parameters.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                return [obj1 compare:obj2];
            }];
            
            
            NSUInteger questionMarkLocation = [combinedURL rangeOfString:@"?"].location;
            if (questionMarkLocation != NSNotFound) {
                if (questionMarkLocation < (baseURL.length-1)) {
                    [queryString appendString:@"&"];
                }
            }
            else
            {
                [queryString appendString:@"?"];
            }
            
            for (id key in sortedKeys) {
                [queryString appendFormat:@"%@=%@&", [key description], [[parameters[key] description] uxing_urlencode]];
            }
            
            if ([queryString hasSuffix:@"&"]) {
                [queryString deleteCharactersInRange:NSMakeRange(queryString.length - 1, 1)];
            }
            
            //处理前端 URL 中的 hash
            NSInteger insertPosition = [combinedURL rangeOfString:@"#"].location;
            if (insertPosition == NSNotFound) {
                insertPosition = combinedURL.length;
            }
            else {
                // 存在问号，并且问号在 hash 之后时，直接把 URL 拼到最后
                if (questionMarkLocation != NSNotFound && questionMarkLocation > insertPosition) {
                    insertPosition = combinedURL.length;
                }
            }
            
            [combinedURL insertString:queryString atIndex:insertPosition];
        }
    }
    return combinedURL;
    
}



- (id)jsonObject
{
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
    
    return object;
}

- (id)jsonFragment
{
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                options:NSJSONReadingAllowFragments
                                                  error:&error];
    return object;
}

- (CGFloat)widthForFont:(UIFont *)font
{
    CGSize size = [self sizeForFont:font size:CGSizeMake(HUGE, HUGE) mode:NSLineBreakByWordWrapping];
    return size.width;
}

- (CGFloat)heightForFont:(UIFont *)font width:(CGFloat)width
{
    CGSize size = [self sizeForFont:font size:CGSizeMake(width, HUGE) mode:NSLineBreakByWordWrapping];
    return size.height;
}


- (CGSize)sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode {
    CGSize result;
    if (!font) font = [UIFont pingFangRegularWithSize:12];
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableDictionary *attr = [NSMutableDictionary new];
        attr[NSFontAttributeName] = font;
        if (lineBreakMode != NSLineBreakByWordWrapping) {
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineBreakMode = lineBreakMode;
            attr[NSParagraphStyleAttributeName] = paragraphStyle;
        }
        CGRect rect = [self boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attr context:nil];
        result = rect.size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [self sizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    return result;
}

+ (NSString *)timeStmpWith:(NSTimeInterval)gmtCreate{
    NSDate *currentDate = [NSDate date];
    NSDate *targetDate = [NSDate dateWithTimeIntervalSince1970:gmtCreate/1000];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:targetDate toDate:currentDate options:0];
    
    if (components.day == 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"今天 HH:mm"];
        return [formatter stringFromDate:targetDate];
    }
    else if ( components.day == 1) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"昨天 HH:mm"];
        return [formatter stringFromDate:targetDate];
    }else {
        NSDateFormatter *fullFormatter = [[NSDateFormatter alloc] init];
        [fullFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        return [fullFormatter stringFromDate:targetDate];
    }
}

- (NSAttributedString *)attributedStringFromHTML {
    if (!self) return nil;
    
    NSData *htmlData = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *options = @{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding)
    };
    
    NSError *error = nil;
    NSAttributedString *attributedString = [[NSAttributedString alloc]
        initWithData: htmlData
            options: options
            documentAttributes: nil
            error: &error];
    
    if (error) {
        NSLog(@"HTML 转换错误: %@", error.localizedDescription);
        return nil;
    }
    
    // 增加行间距处理
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:4.0];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    
    [mutableAttributedString addAttribute:NSParagraphStyleAttributeName 
                                    value:paragraphStyle 
                                    range:NSMakeRange(0, mutableAttributedString.length)];
    
    return mutableAttributedString;
}

@end
