//
//  SLHomePageNewsViewController.m
//  digg
//
//  Created by hey on 2024/9/26.
//

#import "SLHomePageNewsViewController.h"

#import <Masonry/Masonry.h>
#import "CaocaoRefresh.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import "SLHomePageNewsTableViewCellV3.h"
#import "SLTagListContainerViewController.h"
#import "SLWebViewController.h"
#import "SLUser.h"
#import "SLAlertManager.h"
#import "SLTrackingManager.h"
#import "TMViewTrackerSDK.h"
#import "UIView+TMViewTracker.h"

# define kSLHomePageNewsTableViewCellID @"SLHomePageNewsTableViewCell"

@interface SLHomePageNewsViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) SLHomePageViewModel *viewModel;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SLHomePageNewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self addRefresh];
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
    
    [TMViewTrackerManager setCurrentPageName:@"Home"];
}

- (void)changeBgColor{
    self.tableView.backgroundColor = [UIColor clearColor];

}

- (void)dataLoadActionCallback{
    //刷新
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

- (UIView *)listView {
    [self changeBgColor];
    return self.view;
}

- (void)addRefresh{
    @weakobj(self);
    self.tableView.mj_header = [CaocaoRefreshHeader headerWithRefreshingBlock:^{
        @strongobj(self);
        [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
    }];
    
    self.tableView.mj_footer = [CaocaoRefreshFooter footerWithRefreshingBlock:^{
        @strongobj(self);
        [self loadMessagesList:CaocaoCarMessageListRefreshTypeLoadMore];
    }];
}

- (void)setView:(UIView *)view{
    [super setView:view];
}

- (void)loadMessagesList:(CaocaoCarMessageListRefreshType)type{
    @weakobj(self);
    [self.viewModel loadMessageListWithRefreshType:type withPageStyle:self.pageStyle resultHandler:^(BOOL isSuccess, NSError *error) {
        @strongobj(self);
        if (isSuccess) {
            if ([self.viewModel.dataArray count] == 0) {
                self.dataState = CaocaoDataLoadStateEmpty;
            } else {
                self.dataState = CaocaoDataLoadStateNormal;
            }
        } else {
            self.dataState = CaocaoDataLoadStateError;
        }
        [self.tableView reloadData];
        [self endRefresh];
    }];
}

- (void)jumpToLogin {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login",H5BaseUrl]];
    dvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController presentViewController:dvc animated:YES completion:^{     
    }];
}

- (void)jumpToH5WithUrl:(NSString *)url andShowProgress:(BOOL)show {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    dvc.isShowProgress = show;
    [dvc startLoadRequestWithUrl:url];
    dvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:dvc animated:YES];
}

- (void)endRefresh
{
    if (self.viewModel.hasToEnd) {
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    } else {
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    SLArticleTodayEntity *entity = [self.viewModel.dataArray objectAtIndex:indexPath.row];
    NSString *url = [NSString stringWithFormat:@"%@/post/%@",H5BaseUrl,entity.articleId];
    [self jumpToH5WithUrl:url andShowProgress:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.viewModel.dataArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SLHomePageNewsTableViewCellV3 *cell = [tableView dequeueReusableCellWithIdentifier:kSLHomePageNewsTableViewCellID forIndexPath:indexPath];
    if (cell) {
        SLArticleTodayEntity *entity = [self.viewModel.dataArray objectAtIndex:indexPath.row];
        [cell updateWithEntity:entity];
        cell.controlName = @"HOME_LIST";
        cell.args = @{
            @"url": entity.url,
            @"title": entity.title,
            @"pageStyle": @(self.pageStyle)
        };
        @weakobj(self);
        cell.likeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self jumpToLogin];
                return;
            }
            [self.viewModel likeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        
        cell.dislikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self jumpToLogin];
                return;
            }
            [self.viewModel dislikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        
        cell.checkDetailClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                               message:nil
                                                                   url:[NSURL URLWithString:entity.url]
                                                               urlText:entity.url
                                                          confirmTitle:@"是"
                                                           cancelTitle:@"否"
                                                        confirmHandler:^{
                                                            NSDictionary* param = @{
                                                                @"url": entity.url,
                                                                @"index": @(self.pageStyle)
                                                            };
                                                            [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_HOME" parameters:param];
                                                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:entity.url] options:@{} completionHandler:nil];
                                                        }
                                                         cancelHandler:^{
                                                        }
                                                     fromViewController:nil];
            [alertView show];
        };
        
        cell.cancelLikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self jumpToLogin];
                return;
            }
            [self.viewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                            
            }];
        };
        cell.cancelDisLikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self jumpToLogin];
                return;
            }
            [self.viewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                            
            }];
        };
        cell.labelClick = ^(SLArticleTodayEntity *entity) {
            if (entity.label.length > 0) {
                @strongobj(self);
                SLTagListContainerViewController* vc = [SLTagListContainerViewController new];
                vc.label = entity.label;
                vc.entity = entity;
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        };
        cell.showDetailClick = ^(SLArticleTodayEntity * _Nonnull entity) {
            NSString *url = [NSString stringWithFormat:@"%@/post/%@",H5BaseUrl,entity.articleId];
            [self jumpToH5WithUrl:url andShowProgress:NO];
        };
    }
    return cell;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[SLHomePageNewsTableViewCellV3 class] forCellReuseIdentifier:kSLHomePageNewsTableViewCellID];
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        _tableView.estimatedRowHeight = 100;
    }
    return _tableView;
}


- (SLHomePageViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[SLHomePageViewModel alloc] init];
    }
    return _viewModel;
}


@end
