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
        self.curPage = 1;
        self.pageSize = 30;
    }
    return self;
}

//拉取消息列表
- (void)loadMessageListWithRefreshType:(CaocaoCarMessageListRefreshType)refreshType
                         withPageStyle:(HomePageStyle)pageSyle
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [self handleReqApiPathWithRefreshType:refreshType pageStyle:pageSyle];
    @weakobj(self);
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSArray class]]) {
                [self handleRes:responseObject
                   withPageType:pageSyle
                withRefreshType:refreshType];
            }
            handler(YES,nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@",error);
        if (handler) {
            handler(NO,error);
        }
    }];
}

- (NSString *)handleReqApiPathWithRefreshType:(CaocaoCarMessageListRefreshType)refreshType pageStyle:(HomePageStyle)pageStyle {
    NSString *urlString;
    NSString *baseUrl = ApiBaseUrl;
    
    if (refreshType == CaocaoCarMessageListRefreshTypeRefresh) {
        self.curPage = 1;
    } else {
        self.curPage++;
    }
    
    if (pageStyle == HomePageStyleToday) {
        urlString = [NSString stringWithFormat:@"%@/api/article/today?pageNo=%ld&pageSize=%ld", baseUrl, self.curPage, self.pageSize];
    } else if (pageStyle == HomePageStyleDiscover) {
        urlString = [NSString stringWithFormat:@"%@/api/article/news?pageNo=%ld&pageSize=%ld", baseUrl, self.curPage, self.pageSize];
    }

    return urlString;
}

- (void)handleRes:(NSArray *)resArray
     withPageType:(HomePageStyle)pageStyle
  withRefreshType:(CaocaoCarMessageListRefreshType)refreshType {
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

- (void)likeWith:(NSString *)articleId
   resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/like",APPBaseUrl];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    [mutDic setObject:articleId forKey:@"articleId"];
    [manager POST:urlString parameters:mutDic.copy headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            //判断是否点赞成功
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            BOOL needLogin = NO;
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                needLogin = response.statusCode == 401;
                if (needLogin) {
                    handler(NO, error);
                }
            }
        }
    }];
}

- (void)dislikeWith:(NSString *)articleId
   resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/dislike",APPBaseUrl];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    [mutDic setObject:articleId forKey:@"articleId"];
    [manager POST:urlString parameters:mutDic.copy headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            //判断是否点赞成功
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            BOOL needLogin = NO;
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                needLogin = response.statusCode == 401;
                if (needLogin) {
                    handler(NO, error);
                }
            }
        }
    }];
}

- (void)cancelLikeWith:(NSString *)articleId resultHandler:(void (^)(BOOL, NSError *))handler{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/cancel",APPBaseUrl];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    [mutDic setObject:articleId forKey:@"articleId"];
    [manager POST:urlString parameters:mutDic.copy headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            //判断是否点赞成功
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            BOOL needLogin = NO;
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                needLogin = response.statusCode == 401;
                if (needLogin) {
                    handler(NO, error);
                }
            }
        }
    }];
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
        NSLog(@"req error = %@",error);
        if (handler) {
            handler(0, error);
        }
    }];
}

- (NSMutableArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}


@end
