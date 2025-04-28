//
//  SLTagListContainerViewModel.h
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import <Foundation/Foundation.h>
#import "EnvConfigHeader.h"
#import "SLGeneralMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLTagListContainerViewModel : NSObject

@property (nonatomic, strong) NSString* content;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) NSInteger curPage;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) BOOL hasToEnd;

- (void)loadLabelInfoWithLabelId:(NSString *)labelId
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

//拉取消息列表
- (void)loadMessageListWithRefreshType:(CaocaoCarMessageListRefreshType)refreshType
                         withPageStyle:(NSInteger)index
                             withLabel:(NSString *)label
                                souce:(NSString *)source
                             articleId:(NSString *)articleId
                        resultHandler:(void(^)(BOOL isSuccess, NSError *error))handler;

@end

NS_ASSUME_NONNULL_END
