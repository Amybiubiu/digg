//
//  SLUserEntity.m
//  digg
//
//  Created by hey on 2024/11/24.
//

#import "SLUserEntity.h"

@interface SLUserEntity ()<NSCoding>

@end

@implementation SLUserEntity



- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.userId forKey:@"userId"];
    [coder encodeObject:self.token forKey:@"token"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        NSString *userId = [coder decodeObjectForKey:@"userId"];
        NSString *token = [coder decodeObjectForKey:@"token"];
        self.userId = userId;
        self.token = token;
    }
    return self;
}

@end
