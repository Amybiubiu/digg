//
//  EnvConfigHeader.h
//  digg
//
//  Created by hey on 2024/11/24.
//

#ifndef EnvConfigHeader_h
#define EnvConfigHeader_h

#import <UIKit/UIKit.h>

#define H5BaseUrl @"http://39.106.147.0"
#define APPBaseUrl @"http://115.159.103.82:8001"
// #define H5BaseUrl @"http://192.168.0.102:5173"

//首页H5 URL链接
static NSString * const HOME_TODAY_PAGE_URL = H5BaseUrl @"/home/today";
static NSString * const HOME_RECENT_PAGE_URL = H5BaseUrl @"/home/recent";
static NSString * const HOME_FORYOU_PAGE_URL = H5BaseUrl @"/home/forYou";

//关注
static NSString * const FOLLOW_PAGE_URL = H5BaseUrl @"/follow";

//我的
static NSString * const MY_PAGE_URL = H5BaseUrl @"/my";

//登陆
static NSString * const LOGIN_PAGE_URL = H5BaseUrl @"/login";

//文章详情
static NSString * const ARTICAL_PAGE_DETAIL_URL = H5BaseUrl @"/post/";

#endif /* EnvConfigHeader_h */
