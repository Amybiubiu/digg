//
//  SLArticleTodayEntity.h
//  digg
//
//  Created by hey on 2024/10/14.
//

#import <Foundation/Foundation.h>

@interface SLArticleTodayEntity : NSObject

@property (nonatomic, copy) NSString *articleId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) NSTimeInterval gmtCreate;
@property (nonatomic, assign) NSTimeInterval gmtModified;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *userDescription;
@property (nonatomic, copy) NSString *userAvatar;
@property (nonatomic, copy) NSString *avatar; //feedlist
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, assign) BOOL disliked;
@property (nonatomic, assign) NSInteger likeCnt;
@property (nonatomic, assign) NSInteger commentsCnt;
@property (nonatomic, assign) NSInteger dislikeCnt;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *actionName;
@property (nonatomic, copy) NSString *mainPicUrl; //图片链接
@property (nonatomic, assign) NSInteger picSize;  //0 small | 1 large

@end

