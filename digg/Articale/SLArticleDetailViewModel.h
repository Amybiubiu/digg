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
@property (nonatomic, strong) NSMutableArray<SLReferEntity *> *referList;

/**
 * 加载文章详情
 * @param articleId 文章ID
 * @param handler 结果回调
 */
- (void)loadArticleDetail:(NSString *)articleId resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

/**
 * 添加一级评论（回复文章）
 * @param articleId 文章ID
 * @param replyUserId 要评论的用户ID
 * @param content 评论内容
 * @param handler 结果回调，成功时返回新创建的评论实体
 */
 - (void)replyToArticle:(NSString *)articleId 
 replyUserId:(NSString *)replyUserId 
    content:(NSString *)content 
resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler;

/**
* 添加二级评论（回复评论）
* @param articleId 文章ID
* @param commentId 要回复的评论ID
* @param replyUserId 要回复的用户ID
* @param content 评论内容
* @param handler 结果回调，成功时返回新创建的评论实体
*/
- (void)replyToComment:(NSString *)articleId 
   commentId:(NSString *)commentId 
 replyUserId:(NSString *)replyUserId 
     content:(NSString *)content 
resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler;

/**
* 添加三级评论（回复二级评论）
* @param articleId 文章ID
* @param rootCommentId 当前评论里的根评论ID
* @param commentId 要回复的评论ID
* @param replyUserId 要回复的用户ID
* @param content 评论内容
* @param handler 结果回调，成功时返回新创建的评论实体
*/
- (void)replyToSecondComment:(NSString *)articleId 
     rootCommentId:(NSString *)rootCommentId 
        commentId:(NSString *)commentId 
      replyUserId:(NSString *)replyUserId 
          content:(NSString *)content 
    resultHandler:(void(^)(SLCommentEntity * _Nullable comment, NSError * _Nullable error))handler;

// 对评论点赞
- (void)likeComment:(NSString *)commentId
resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

// 对评论点踩
- (void)dislikeComment:(NSString *)commentId
   resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

// 取消对评论的点赞或点踩
- (void)cancelCommentLike:(NSString *)commentId
      resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

@end

NS_ASSUME_NONNULL_END
