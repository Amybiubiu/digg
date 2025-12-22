//
//  SLUser.h
//  digg
//
//  Created by hey on 2024/11/24.
//

#import <Foundation/Foundation.h>
#import "SLUserEntity.h"

extern NSString * _Nullable const NEUserDidLogoutNotification; //用户登出成功的通知
extern NSString * _Nullable const NEUserDidLoginNotification;  //用户登录成功的通知
extern NSString * _Nullable const NEUserInfoDidUpdateNotification;  //用户信息更新的通知

NS_ASSUME_NONNULL_BEGIN

@interface SLUser : NSObject

@property (nonatomic, strong) SLUserEntity *userEntity;

/**
 用户是否处于登录状态
 */
@property (nonatomic, assign, readonly) BOOL isLogin;

+ (SLUser *)defaultUser;

/**
 从本地加载用户信息
 */
- (void)loadUserInfoFromLocal;

/**
 保存用户信息
 */
- (void)saveUserInfo:(SLUserEntity *)userEntity;

/**
 清楚保存的用户信息
 */
- (void)clearUserInfo;

@end

NS_ASSUME_NONNULL_END
