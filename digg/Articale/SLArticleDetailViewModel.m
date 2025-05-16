//
//  SLArticleDetailViewModel.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleDetailViewModel.h"
#import <AFNetworking/AFNetworking.h>
#import "SLGeneralMacro.h"
#import "EnvConfigHeader.h"
#import <YYModel/YYModel.h>
#import "SLUser.h"

@interface SLArticleDetailViewModel()


@end

@implementation SLArticleDetailViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)loadArticleDetail:(NSString *)articleId resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (articleId.length == 0) {
        if (handler) {
            handler(NO, [NSError errorWithDomain:@"com.digg.error" code:400 userInfo:@{NSLocalizedDescriptionKey: @"文章ID不能为空"}]);
        }
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/article/%@", APPBaseUrl, articleId];
    
    @weakobj(self);
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongobj(self);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            
            // 解析文章详情
            if (dict[@"article"]) {
                self.articleEntity = [SLArticleDetailEntity yy_modelWithJSON:dict[@"article"]];
            }
            
            // 解析评论列表
            if (dict[@"comments"]) {
                self.commentList = [NSMutableArray arrayWithArray:[NSArray yy_modelArrayWithClass:[SLCommentEntity class] json:dict[@"comments"]]];
                NSMutableArray<SLCommentEntity *>* comments = [NSMutableArray new];
                for (SLCommentEntity* comment in self.commentList) {
                    if (comment.replyList.count > 0) {
                        comment.expandedRepliesCount = 1;
                    }
                    if (comment.expandedRepliesCount < comment.replyList.count) {
                        comment.hasMore = YES;
                    } else {
                        comment.hasMore = NO;
                    }
                    [comments addObject:comment];
                }
                self.commentList = comments;
            }
            
            // 解析用户信息
            if (dict[@"user"]) {
                self.userEntity = [SLUserDetailEntity yy_modelWithJSON:dict[@"user"]];
            }
            
            // 解析相关链接
            if (dict[@"referList"]) {
                self.referList = [NSArray yy_modelArrayWithClass:[SLReferEntity class] json:dict[@"referList"]];
            }
            
            if (handler) {
                handler(YES, nil);
            }
        } else {
            if (handler) {
                handler(NO, [NSError errorWithDomain:@"com.digg.error" code:500 userInfo:@{NSLocalizedDescriptionKey: @"数据格式错误"}]);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

#pragma mark - 评论相关方法

- (void)replyToArticle:(NSString *)articleId 
            replyUserId:(NSString *)replyUserId 
               content:(NSString *)content 
         resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler {
    
    // 构建请求参数
    NSDictionary *params = @{
        @"articleId": articleId,
        @"replyUserId": replyUserId,
        @"content": content
    };
    
    // 创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/comment/replyToArticle", APPBaseUrl];
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 解析返回的评论数据
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            SLCommentEntity *newComment = [SLCommentEntity yy_modelWithJSON:responseObject];
            
            // 将新评论添加到评论列表
            if (newComment) {
                if (!self.commentList) {
                    self.commentList = [NSMutableArray array];
                }
                [self.commentList insertObject:newComment atIndex:0];
                
                // 回调成功
                if (handler) {
                    handler(newComment, nil);
                }
                return;
            }
        }
        
        // 解析失败
        if (handler) {
            NSError *error = [NSError errorWithDomain:@"com.digg.commentError" 
                                                 code:1001 
                                             userInfo:@{NSLocalizedDescriptionKey: @"评论数据解析失败"}];
            handler(nil, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        // 请求失败
        if (handler) {
            handler(nil, error);
        }
    }];
}

- (void)replyToComment:(NSString *)articleId 
              commentId:(NSString *)commentId 
            replyUserId:(NSString *)replyUserId 
                content:(NSString *)content 
          resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler {
    
    // 构建请求参数
    NSDictionary *params = @{
        @"articleId": articleId,
        @"commentId": commentId,
        @"replyUserId": replyUserId,
        @"content": content
    };
    
    // 创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/comment/replyToComment", APPBaseUrl];
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 解析返回的评论数据
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            SLCommentEntity *newComment = [SLCommentEntity yy_modelWithJSON:responseObject];

            // 将新评论添加到对应的一级评论的回复列表中
            if (newComment) {
                // 查找对应的一级评论
                for (SLCommentEntity *comment in self.commentList) {
                    if ([comment.commentId isEqualToString:commentId]) {
                        // 初始化回复列表（如果为空）
                        if (!comment.replyList) {
                            comment.replyList = [NSMutableArray array];
                        } else if (![comment.replyList isKindOfClass:[NSMutableArray class]]) {
                            // 如果是不可变数组，转换为可变数组
                            comment.replyList = [NSMutableArray arrayWithArray:comment.replyList];
                        }
                        // 添加新回复
                        [(NSMutableArray *)comment.replyList insertObject:newComment atIndex:0];
                        break;
                    }
                }
                
                // 回调成功
                if (handler) {
                    handler(newComment, nil);
                }
                return;
            }
        }
        
        // 解析失败
        if (handler) {
            NSError *error = [NSError errorWithDomain:@"com.digg.commentError" 
                                                 code:1002 
                                             userInfo:@{NSLocalizedDescriptionKey: @"评论数据解析失败"}];
            handler(nil, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        // 请求失败
        if (handler) {
            handler(nil, error);
        }
    }];
}

- (void)replyToSecondComment:(NSString *)articleId 
                rootCommentId:(NSString *)rootCommentId 
                   commentId:(NSString *)commentId 
                 replyUserId:(NSString *)replyUserId 
                     content:(NSString *)content 
               resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler {
    
    // 构建请求参数
    NSDictionary *params = @{
        @"articleId": articleId,
        @"rootCommentId": rootCommentId,
        @"commentId": commentId,
        @"replyUserId": replyUserId,
        @"content": content
    };
    
    // 创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/comment/replyToSecondComment", APPBaseUrl];
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 解析返回的评论数据
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            SLCommentEntity *newComment = [SLCommentEntity yy_modelWithJSON:responseObject];
            
            // 将新评论添加到对应的一级评论的回复列表中
            if (newComment) {
                // 设置回复标志
                newComment.replyToSecondComment = YES;
                
                // 查找对应的一级评论
                for (SLCommentEntity *comment in self.commentList) {
                    if ([comment.commentId isEqualToString:rootCommentId]) {
                        // 初始化回复列表（如果为空）
                        if (!comment.replyList) {
                            comment.replyList = [NSMutableArray array];
                        } else if (![comment.replyList isKindOfClass:[NSMutableArray class]]) {
                            // 如果是不可变数组，转换为可变数组
                            comment.replyList = [NSMutableArray arrayWithArray:comment.replyList];
                        }
                        
                        // 查找二级评论在回复列表中的位置
                        NSInteger insertIndex = 0;
                        for (NSInteger i = 0; i < comment.replyList.count; i++) {
                            SLCommentEntity *reply = comment.replyList[i];
                            if ([reply.commentId isEqualToString:commentId]) {
                                insertIndex = i; // 在找到的二级评论后面插入
                                break;
                            }
                        }
                        
                        // 在指定位置插入新回复
                        [(NSMutableArray *)comment.replyList insertObject:newComment atIndex:insertIndex];
                        break;
                    }
                }
                
                // 回调成功
                if (handler) {
                    handler(newComment, nil);
                }
                return;
            }
        }
        
        // 解析失败
        if (handler) {
            NSError *error = [NSError errorWithDomain:@"com.digg.commentError" 
                                                 code:1003 
                                             userInfo:@{NSLocalizedDescriptionKey: @"评论数据解析失败"}];
            handler(nil, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        // 请求失败
        if (handler) {
            handler(nil, error);
        }
    }];
}

#pragma mark - 评论点赞相关方法

// 对评论点赞
- (void)likeComment:(NSString *)commentId
      resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/likeComment", ApiBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
    NSDictionary *params = @{@"commentId": commentId};
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSData* data = (NSData*)responseObject;
            NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            BOOL result = [resultStr isEqualToString:@"true"] || [resultStr isEqualToString:@"1"];
            handler(result, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"点赞评论失败: %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

// 对评论点踩
- (void)dislikeComment:(NSString *)commentId
         resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/dislikeComment", ApiBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
    NSDictionary *params = @{@"commentId": commentId};
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSData* data = (NSData*)responseObject;
            NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            BOOL result = [resultStr isEqualToString:@"true"] || [resultStr isEqualToString:@"1"];
            handler(result, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"点踩评论失败: %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

// 取消对评论的点赞或点踩
- (void)cancelCommentLike:(NSString *)commentId
            resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *urlString = [NSString stringWithFormat:@"%@/cancelForComment", APPBaseUrl];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
    NSDictionary *params = @{@"commentId": commentId};
    
    [manager POST:urlString parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSData* data = (NSData*)responseObject;
            NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            BOOL result = [resultStr isEqualToString:@"true"] || [resultStr isEqualToString:@"1"];
            handler(result, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"取消评论点赞/点踩失败: %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

@end
