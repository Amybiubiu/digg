//
//  SLConcernedViewModel.m
//  digg
//
//  Created by Tim Bao on 2025/1/23.
//

#import "SLConcernedViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import <YYModel/YYModel.h>
#import "SLUser.h"
#import "SLArticleTodayEntity.h"

@implementation SLConcernedViewModel

- (instancetype)init{
    self = [super init];
    if (self) {
        self.curPage = 1;
        self.pageSize = 30;
    }
    return self;
}

//拉取消息列表
- (void)loadMessageListWithRefreshType:(CaocaoCarMessageListRefreshType)refreshType
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (refreshType == CaocaoCarMessageListRefreshTypeRefresh) {
        self.curPage = 1;
    } else {
        self.curPage++;
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/feeds?pageNo=%ld&pageSize=%ld", APPBaseUrl, self.curPage, self.pageSize];
    @weakobj(self);
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSArray class]]) {
                [self handleRes:responseObject
                withRefreshType:refreshType];
            }
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@",error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

- (void)handleRes:(NSArray *)resArray
  withRefreshType:(CaocaoCarMessageListRefreshType)refreshType{
    NSArray *list = [NSArray yy_modelArrayWithClass:[SLArticleTodayEntity class] json:resArray];
    if (refreshType == CaocaoCarMessageListRefreshTypeRefresh) {
        self.dataArray = [NSMutableArray arrayWithArray:list];
    } else {
        [self.dataArray addObjectsFromArray:list];
    }
    
    if (resArray.count < self.pageSize) {
        self.hasToEnd = YES;
    } else {
        self.hasToEnd = NO;
    }
}

@end
