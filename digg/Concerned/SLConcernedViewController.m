//
//  SLConcernedViewController.m
//  digg
//
//  Created by Tim Bao on 2025/1/23.
//

#import "SLConcernedViewController.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"
#import "CaocaoRefresh.h"
#import "SLProfileDynamicTableViewCell.h"
#import "SLHomePageViewModel.h"
#import "SLConcernedViewModel.h"
#import "SLWebViewController.h"
#import "SLUser.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import "SLTrackingManager.h"
#import "TMViewTrackerSDK.h"
#import "UIView+TMViewTracker.h"


@interface SLConcernedViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) SLConcernedViewModel *viewModel;
@property (nonatomic, strong) SLHomePageViewModel *homeViewModel;

@end

@implementation SLConcernedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    [self setupUI];
    [self addRefresh];
    [self requestData];
    
    [TMViewTrackerManager setCurrentPageName:@"Concern"];
}

#pragma mark - Methods
- (void)setupUI {
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(STATUSBAR_HEIGHT);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

- (void)requestData {
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

- (void)addRefresh {
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

- (void)loadMessagesList:(CaocaoCarMessageListRefreshType)type {
    @weakobj(self);
    [self.viewModel loadMessageListWithRefreshType:type resultHandler:^(BOOL isSuccess, NSError *error) {
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

- (void)dataLoadActionCallback {
    //刷新
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

#pragma mark - SLEmptyWithLoginButtonViewDelegate
- (void)gotoLoginPage {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login", H5BaseUrl]];
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    @weakobj(self)
    dvc.loginSucessCallback = ^{
        @strongobj(self)
        [self requestData];
    };
    [self presentViewController:dvc animated:YES completion:nil];
}

- (void)jumpToH5WithUrl:(NSString *)url andShowProgress:(BOOL)show {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    dvc.isShowProgress = show;
    [dvc startLoadRequestWithUrl:url];
    dvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:dvc animated:YES];
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SLArticleTodayEntity *entity = [self.viewModel.dataArray objectAtIndex:indexPath.row];
    NSString *url = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, entity.articleId];
    [self jumpToH5WithUrl:url andShowProgress:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SLProfileDynamicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLProfileDynamicTableViewCell" forIndexPath:indexPath];
    if (cell) {
        SLArticleTodayEntity *entity = [self.viewModel.dataArray objectAtIndex:indexPath.row];
        [cell updateWithEntity:entity];
        cell.controlName = @"CONCERN_LIST";
        cell.args = @{
            @"url": entity.url,
            @"title": entity.title,
        };
        @weakobj(self);
        cell.likeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel likeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        
        cell.dislikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel dislikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        
        cell.checkDetailClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            [SLAlertManager showAlertWithTitle:@"提示"
                                       message:@"您确定要打开此链接吗？"
                                           url:[NSURL URLWithString:entity.url]
                                       urlText:entity.url
                                  confirmTitle:@"是"
                                   cancelTitle:@"否"
                                confirmHandler:^{
                [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_CONCERN" parameters:@{@"url": entity.url}];
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:entity.url] options:@{} completionHandler:nil];
                                }
                                 cancelHandler:^{
                                }
                             fromViewController:self];
//            [self jumpToH5WithUrl:entity.url andShowProgress:YES];
        };
        
        cell.cancelLikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        cell.cancelDisLikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                
            }];
        };
        cell.showDetailClick = ^(SLArticleTodayEntity * _Nonnull entity) {
            NSString *url = [NSString stringWithFormat:@"%@/post/%@",H5BaseUrl,entity.articleId];
            [self jumpToH5WithUrl:url andShowProgress:NO];
        };
    }
    return cell;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"empty_placeholder"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"还没有内容";
    
    NSDictionary *attributes = @{
                              NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f],
                              NSForegroundColorAttributeName: Color16(0xC6C6C6)
                             };
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return 98.0/2.0;
}

#pragma mark - UI Element
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[SLProfileDynamicTableViewCell class] forCellReuseIdentifier:@"SLProfileDynamicTableViewCell"];
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        _tableView.estimatedRowHeight = 100;
        _tableView.sectionHeaderHeight = 51;
        
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
    }
    return _tableView;
}

- (SLConcernedViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[SLConcernedViewModel alloc] init];
    }
    return _viewModel;
}

- (SLHomePageViewModel *)homeViewModel {
    if (!_homeViewModel) {
        _homeViewModel = [[SLHomePageViewModel alloc] init];
    }
    return _homeViewModel;
}


@end
