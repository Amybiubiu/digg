//
//  SLTagListContainerViewModel.m
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import "SLTagListContainerViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import "EnvConfigHeader.h"
#import <YYModel/YYModel.h>
#import "SLUser.h"
#import "SLArticleTodayEntity.h"

@implementation SLTagListContainerViewModel

- (instancetype)init{
    self = [super init];
    if (self) {
        self.curPage = 1;
        self.pageSize = 10;
    }
    return self;
}

- (void)loadLabelInfoWithLabelId:(NSString *)labelId
                   resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (labelId.length == 0) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/labels/content", APPBaseUrl];
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    @weakobj(self);
    [manager GET:urlString parameters:@{@"label": labelId} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                self.content = responseObject[@"content"];
                handler(YES, nil);
            } else {
                handler(NO, nil);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(NO, error);
        }
    }];
}

//拉取消息列表
- (void)loadMessageListWithRefreshType:(CaocaoCarMessageListRefreshType)refreshType
                         withPageStyle:(NSInteger)index
                             withLabel:(NSString *)label
                                 souce:(NSString *)source
                              articleId:(NSString *)articleId
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [self handleReqApiPath:index];
    if (refreshType == CaocaoCarMessageListRefreshTypeRefresh) {
        self.curPage = 1;
    } else {
        self.curPage++;
    }
    @weakobj(self);
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"label"] = label;
    params[@"pageNo"] = @(self.curPage);
    params[@"pageSize"] = @(self.pageSize);
    params[@"source"] = source;
    if (articleId.length > 0) {
        params[@"articleId"] = articleId;
    }
    
    [manager GET:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSArray class]]) {
                [self handleRes:responseObject
                   withPageType:index
                withRefreshType:refreshType];
            }
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(NO,error);
        }
    }];
}

- (NSString *)handleReqApiPath:(NSInteger)index {
    NSString *urlString;
    NSString *baseUrl = APPBaseUrl;
    if (index == 0) {
        urlString = [NSString stringWithFormat:@"%@/labels/rec",baseUrl];
    } else if (index == 1) {
        urlString = [NSString stringWithFormat:@"%@/labels/new",baseUrl];
    } else if (index == 2) {
        urlString = [NSString stringWithFormat:@"%@/labels/hot",baseUrl];
    }

    return urlString;
}

- (void)handleRes:(NSArray *)resArray
     withPageType:(NSInteger)index
  withRefreshType:(CaocaoCarMessageListRefreshType)refreshType {
    NSArray *list = [NSArray yy_modelArrayWithClass: [SLArticleTodayEntity class] json:resArray];
    if (refreshType == CaocaoCarMessageListRefreshTypeRefresh) {
        self.dataArray = [NSMutableArray arrayWithArray:list];
    } else {
        [self.dataArray addObjectsFromArray:list];
    }
    
    if (refreshType == CaocaoCarMessageListRefreshTypeLoadMore) {
        if (resArray.count < self.pageSize) {
            self.hasToEnd = YES;
        } else {
            self.hasToEnd = NO;
        }
    }
}

@end
