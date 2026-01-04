//
//  SLHomePageViewModel.m
//  digg
//
//  Created by hey on 2024/10/17.
//

#import "SLHomePageViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import <YYModel/YYModel.h>
#import "SLUser.h"

@implementation SLHomePageViewModel


- (instancetype)init{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)getForYouRedPoint:(void(^)(NSInteger number, NSError *error))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/redPoint", APPBaseUrl];

    @weakobj(self);
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                NSInteger count = [[dic objectForKey:@"forYou"] integerValue];
                handler(count, nil);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // NSLog(@"req error = %@",error);
        if (handler) {
            handler(0, error);
        }
    }];
}


@end
