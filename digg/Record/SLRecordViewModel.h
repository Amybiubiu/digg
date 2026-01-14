//
//  SLRecordViewModel.h
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRecordViewModel : NSObject

- (void)subimtRecord:(NSString *)title link:(NSString *)url content:(NSString *)content imageUrls:(NSArray *)imageUrls labels:(NSArray *)labels htmlContent:(NSString *)htmlContent resultHandler:(void(^)(BOOL isSuccess, NSString* articleId))handler;

- (void)updateRecord:(NSString *)title link:(NSString *)url content:(NSString *)content imageUrls:(NSArray *)imageUrls labels:(NSArray *)labels htmlContent:(NSString *)htmlContent articleId:(NSString *)articleId resultHandler:(void(^)(BOOL isSuccess, NSString* articleId))handler;

- (void)updateImage:(NSData *)imageData progress:(void(^)(CGFloat total, CGFloat current))progressHandler resultHandler:(void(^)(BOOL isSuccess, NSString *url))handler;

@end

NS_ASSUME_NONNULL_END
