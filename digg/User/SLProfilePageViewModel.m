//
//  SLProfilePageViewModel.m
//  digg
//
//  Created by Tim Bao on 2025/1/6.
//

#import "SLProfilePageViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import "EnvConfigHeader.h"
#import <YYModel/YYModel.h>
#import "SLProfileEntity.h"
#import "SLUser.h"

@implementation SLProfilePageViewModel

- (void)loadUserProfileWithProfileID:(NSString *)profileId
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (profileId.length == 0) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/profile", APPBaseUrl];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    @weakobj(self);
    [manager GET:urlString parameters:@{@"userId": profileId} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self);
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                self.entity = [SLProfileEntity yy_modelWithJSON:responseObject];
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

- (void)isUserLogin:(void(^)(BOOL isLogin, NSError *error))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/auth/currentUser", APPBaseUrl];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
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

- (void)logout:(void(^)(BOOL success, NSError *error))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/auth/logout", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            [[SLUser defaultUser] clearUserInfo];
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(NO, error);
        }
    }];
}

- (void)followWithUserID:(NSString *)userId cancel:(BOOL)cancel resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (userId.length == 0) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = @"";
    if (cancel) {
        urlString = [NSString stringWithFormat:@"%@/cancelFollow", APPBaseUrl];
    } else {
        urlString = [NSString stringWithFormat:@"%@/follow", APPBaseUrl];
    }
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    @weakobj(self);
    [manager POST:urlString parameters:@{@"followUserId": userId} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            @strongobj(self); //统一返回true or false
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                handler(YES, nil);
            }
//            else {
//                handler(NO, nil);
//            }
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

- (void)updateProfileWithUserID:(NSString *)userId nickName:(NSString *)nickName desc:(NSString *)description avatar:(NSData *)avatar bg:(NSData *)bg resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (userId.length == 0) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/updateProfile", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    [manager POST:urlString parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            // 添加 userId
            if (userId) {
                [formData appendPartWithFormData:[userId dataUsingEncoding:NSUTF8StringEncoding] name:@"userId"];
            }
            
            // 添加 nickName
            if (nickName) {
                [formData appendPartWithFormData:[nickName dataUsingEncoding:NSUTF8StringEncoding] name:@"username"];
            }
            
            // 添加 description
            if (description) {
                [formData appendPartWithFormData:[description dataUsingEncoding:NSUTF8StringEncoding] name:@"description"];
            }
            
            // 添加 avatar 文件
            if (avatar) {
                [formData appendPartWithFileData:avatar
                                            name:@"avatar"
                                        fileName:@"avatar.jpg"
                                        mimeType:@"image/jpeg"];
            }
            
            // 添加 bg 文件
            if (bg) {
                [formData appendPartWithFileData:bg
                                            name:@"bgImage"
                                        fileName:@"bgImage.jpg"
                                        mimeType:@"image/jpeg"];
            }
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (handler) {
                handler(YES, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (handler) {
                handler(NO, error);
            }
    }];
    
}

@end
