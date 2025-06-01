//
//  SLRecordViewModel.m
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import "SLRecordViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import "EnvConfigHeader.h"
#import <YYModel/YYModel.h>
#import "SLProfileEntity.h"
#import "SLUser.h"

@implementation SLRecordViewModel

- (void)subimtRecord:(NSString *)title link:(NSString *)url content:(NSString *)content htmlContent:(NSString *)htmlContent labels:(NSArray *)labels resultHandler:(void(^)(BOOL isSuccess, NSString *articleId))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *urlString = [NSString stringWithFormat:@"%@/article/submit", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    NSMutableDictionary* parameters = [NSMutableDictionary new];
    parameters[@"title"] = title;
    parameters[@"url"] = url;
    NSString *trimmedContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    parameters[@"content"] = trimmedContent;
    parameters[@"htmlContent"] = htmlContent;
    parameters[@"labels"] = labels;
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSData* data = (NSData*)responseObject;
            NSString *articleId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            handler(YES, articleId);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            BOOL needLogin = NO;
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                needLogin = response.statusCode == 401;
                if (needLogin) {
                    handler(NO, error.description);
                }
            }
        }
    }];
}

- (void)updateRecord:(NSString *)title link:(NSString *)url content:(NSString *)content htmlContent:(NSString *)htmlContent labels:(NSArray *)labels articleId:(NSString *)articleId resultHandler:(void(^)(BOOL isSuccess, NSString* articleId))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *urlString = [NSString stringWithFormat:@"%@/article/update", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    NSMutableDictionary* parameters = [NSMutableDictionary new];
    parameters[@"articleId"] = articleId;
    parameters[@"title"] = title;
    parameters[@"url"] = url;
     NSString *trimmedContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    parameters[@"content"] = trimmedContent;
    parameters[@"htmlContent"] = htmlContent;
    parameters[@"labels"] = labels;
    parameters[@"userId"] = [SLUser defaultUser].userEntity.userId;
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSData* data = (NSData*)responseObject;
            NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            BOOL result = [resultStr isEqualToString:@"true"] || [resultStr isEqualToString:@"1"];
            handler(result, articleId);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            BOOL needLogin = NO;
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                needLogin = response.statusCode == 401;
                if (needLogin) {
                    handler(NO, error.description);
                }
            }
        }
    }];
}

- (void)updateImage:(NSData *)imageData progress:(void(^)(CGFloat total, CGFloat current))progressHandler resultHandler:(void(^)(BOOL isSuccess, NSString *url))handler {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = [NSString stringWithFormat:@"%@/upImg", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];

    [manager POST:urlString parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            // 添加 bg 文件
            if (imageData) {
                [formData appendPartWithFileData:imageData
                                            name:@"file"
                                        fileName:@"richTextImage.jpg"
                                        mimeType:@"image/jpeg"];
            }
        } progress:^(NSProgress *uploadProgress) {
            // 监听上传进度
            NSLog(@"Upload Progress: %@", uploadProgress);
            if (progressHandler) {
                progressHandler(uploadProgress.totalUnitCount, uploadProgress.completedUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (handler) {
                NSData* data = (NSData*)responseObject;
                NSString *url = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                handler(YES, url);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (handler) {
                handler(NO, @"");
            }
    }];
}

@end
