#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleDetailEntity : NSObject

@property (nonatomic, strong) NSString *articleId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *richContent;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSNumber *gmtCreate;
@property (nonatomic, strong) NSNumber *gmtModified;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, assign) BOOL disliked;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, assign) NSInteger likeCnt;
@property (nonatomic, assign) NSInteger dislikeCnt;
@property (nonatomic, assign) NSInteger commentsCnt;
@property (nonatomic, assign) NSInteger share;

@end


@interface SLCommentEntity : NSObject

@property (nonatomic, strong) NSString *commentId;
@property (nonatomic, strong) NSString *articleId;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *gmtCreate;
@property (nonatomic, strong) NSString *gmtModified;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, assign) BOOL replyToArticle;
@property (nonatomic, assign) BOOL replyToComment;
@property (nonatomic, assign) BOOL replyToSecondComment;
@property (nonatomic, strong) NSString *replyId;
@property (nonatomic, strong) NSString *replyUsername;
@property (nonatomic, strong) NSString *replyUserId;
@property (nonatomic, strong) NSString *disliked;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger dislikeCount;
@property (nonatomic, strong) NSArray<SLCommentEntity *> *replyList;
@property (nonatomic, assign) NSInteger expandedRepliesCount; // 存储展开的回复数量

@end


@interface SLUserDetailEntity : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) NSInteger followCnt;
@property (nonatomic, assign) NSInteger beFollowedCnt;
@property (nonatomic, strong) NSArray *submitList;
@property (nonatomic, strong) NSArray *likeList;
@property (nonatomic, assign) BOOL isSelf;
@property (nonatomic, assign) BOOL hasFollow;

@end


@interface SLReferEntity : NSObject

@property (nonatomic, strong) NSString *referId;
@property (nonatomic, strong) NSString *gmtCreate;
@property (nonatomic, strong) NSString *gmtModified;
@property (nonatomic, strong) NSString *articleId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;

@end

NS_ASSUME_NONNULL_END
