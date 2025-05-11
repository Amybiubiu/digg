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

@property (nonatomic, strong) NSMutableSet *expandedCommentIds; // 存储已展开的评论ID

@end

@implementation SLArticleDetailViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.expandedCommentIds = [NSMutableSet set];
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

- (void)likeArticle:(NSString *)articleId isLike:(BOOL)isLike resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
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
    
    NSString *urlString = [NSString stringWithFormat:@"%@/article/like", APPBaseUrl];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"articleId"] = articleId;
    parameters[@"isLike"] = @(isLike);
    
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

- (void)addComment:(NSString *)articleId content:(NSString *)content replyId:(nullable NSString *)replyId replyType:(NSInteger)replyType resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (articleId.length == 0) {
        if (handler) {
            handler(NO, [NSError errorWithDomain:@"com.digg.error" code:400 userInfo:@{NSLocalizedDescriptionKey: @"文章ID不能为空"}]);
        }
        return;
    }
    
    if (content.length == 0) {
        if (handler) {
            handler(NO, [NSError errorWithDomain:@"com.digg.error" code:400 userInfo:@{NSLocalizedDescriptionKey: @"评论内容不能为空"}]);
        }
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/comment/add", APPBaseUrl];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"articleId"] = articleId;
    parameters[@"content"] = content;
    
    if (replyType == 0) {
        parameters[@"replyToArticle"] = @YES;
        parameters[@"replyToComment"] = @NO;
        parameters[@"replyToSecondComment"] = @NO;
    } else if (replyType == 1) {
        parameters[@"replyToArticle"] = @NO;
        parameters[@"replyToComment"] = @YES;
        parameters[@"replyToSecondComment"] = @NO;
    } else if (replyType == 2) {
        parameters[@"replyToArticle"] = @NO;
        parameters[@"replyToComment"] = @NO;
        parameters[@"replyToSecondComment"] = @YES;
    }
    
    if (replyId.length > 0) {
        parameters[@"replyId"] = replyId;
    }
    
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

- (void)likeComment:(NSString *)commentId isLike:(BOOL)isLike resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler {
    if (commentId.length == 0) {
        if (handler) {
            handler(NO, [NSError errorWithDomain:@"com.digg.error" code:400 userInfo:@{NSLocalizedDescriptionKey: @"评论ID不能为空"}]);
        }
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString *cookieStr = [NSString stringWithFormat:@"bp-token=%@", [SLUser defaultUser].userEntity.token];
    [manager.requestSerializer setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/comment/like", APPBaseUrl];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"commentId"] = commentId;
    parameters[@"isLike"] = @(isLike);
    
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"req error = %@", error);
        if (handler) {
            handler(NO, error);
        }
    }];
}

- (BOOL)isCommentExpanded:(NSString *)commentId {
    return [self.expandedCommentIds containsObject:commentId];
}

- (void)setCommentExpanded:(NSString *)commentId expanded:(BOOL)expanded {
    if (expanded) {
        [self.expandedCommentIds addObject:commentId];
    } else {
        [self.expandedCommentIds removeObject:commentId];
    }
}

@end
