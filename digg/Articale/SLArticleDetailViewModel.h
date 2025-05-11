//
//  SLArticleDetailViewModel.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <Foundation/Foundation.h>
#import "SLArticleEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleDetailViewModel : NSObject

@property (nonatomic, strong) SLArticleDetailEntity *articleEntity;
@property (nonatomic, strong) NSMutableArray<SLCommentEntity *> *commentList;
@property (nonatomic, strong) SLUserDetailEntity *userEntity;
@property (nonatomic, strong) NSArray<SLReferEntity *> *referList;

/**
 * 加载文章详情
 * @param articleId 文章ID
 * @param handler 结果回调
 */
- (void)loadArticleDetail:(NSString *)articleId resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

/**
 * 点赞/取消点赞文章
 * @param articleId 文章ID
 * @param isLike 是否点赞
 * @param handler 结果回调
 */
- (void)likeArticle:(NSString *)articleId isLike:(BOOL)isLike resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

/**
 * 添加评论
 * @param articleId 文章ID
 * @param content 评论内容
 * @param replyId 回复ID（如果是回复评论）
 * @param replyType 回复类型（0:回复文章, 1:回复评论, 2:回复二级评论）
 * @param handler 结果回调
 */
- (void)addComment:(NSString *)articleId content:(NSString *)content replyId:(nullable NSString *)replyId replyType:(NSInteger)replyType resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

/**
 * 点赞/取消点赞评论
 * @param commentId 评论ID
 * @param isLike 是否点赞
 * @param handler 结果回调
 */
- (void)likeComment:(NSString *)commentId isLike:(BOOL)isLike resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

// 检查评论是否处于展开状态
- (BOOL)isCommentExpanded:(NSString *)commentId;

// 设置评论的展开状态
- (void)setCommentExpanded:(NSString *)commentId expanded:(BOOL)expanded;

@end

NS_ASSUME_NONNULL_END
