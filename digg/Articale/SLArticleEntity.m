#import "SLArticleEntity.h"
#import "SLArticleTodayEntity.h"

@implementation SLArticleDetailEntity

@end


@implementation SLCommentEntity

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"replyList" : [SLCommentEntity class]};
}

@end

@implementation SLUserDetailEntity

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
                @"isSelf" : @"self"
            };
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
                @"likeList" : [SLArticleTodayEntity class]
            };
}

@end


@implementation SLReferEntity

@end
