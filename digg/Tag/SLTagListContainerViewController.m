//
//  SLTagListContainerViewController.m
//  digg
//
//  Created by Tim Bao on 2025/1/12.
//

#import "SLTagListContainerViewController.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"
#import "SLTagListContainerViewModel.h"
#import "SLTagListContainerViewModel.h"
#import "SLProfileDynamicTableViewCell.h"
#import "CaocaoRefresh.h"
#import "SLHomePageViewModel.h"
#import "SLUser.h"
#import "SLWebViewController.h"
#import "SLAlertManager.h"
#import "SLArticleTodayEntity.h"
#import "UIView+SLToast.h"
#import "SLColorManager.h"
#import "SLArticleDetailViewControllerV2.h"
#import "UIView+SLToast.h"


@interface SLTagListContainerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIImageView* imageBgView;
@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) SLTagListContainerViewModel *viewModel;
@property (nonatomic, strong) SLHomePageViewModel *homeViewModel;

@end

@implementation SLTagListContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = Color16(0xF2F2F2);
    
    self.titleLabel.text = self.label;
    [self setupUI];
    [self addRefresh];
    [self requestData];
}

#pragma mark - Methods
- (void)setupUI {
    [self.view addSubview:self.imageBgView];
    [self.imageBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
    }];

    [self.view addSubview:self.navigationView];
    [self.navigationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(NAVBAR_HEIGHT);
    }];
    
    [self.navigationView addSubview:self.leftBackButton];
    [self.leftBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.navigationView).offset(16);
        make.top.equalTo(self.navigationView).offset((44-32)/2 + STATUSBAR_HEIGHT);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    
    [self.navigationView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.leftBackButton.mas_right).offset(16);
        make.centerY.equalTo(self.leftBackButton);
    }];
    
    [self.navigationView addSubview:self.shareButton];
    [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationView).offset(-16);
        make.centerY.equalTo(self.leftBackButton);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    
    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.navigationView.mas_bottom);
        make.bottom.equalTo(self.view);
    }];

    [self.contentView addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

- (void)requestData {
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

#pragma mark - Actions
- (void)backPage {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shareBtnClick {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [NSString stringWithFormat:@"http://39.106.147.0/label?name=%@", self.label];
    
    [self.view sl_showToast:@"链接已复制到粘贴板"];
}

#pragma mark - UI Elements
- (UIImageView *)imageBgView {
    if (!_imageBgView) {
        _imageBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag_header_bg"]];
        _imageBgView.contentMode = UIViewContentModeScaleToFill;
    }
    return _imageBgView;
}

- (UIButton *)leftBackButton {
    if (!_leftBackButton) {
        _leftBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
        UIImage *backImage = [[UIImage systemImageNamed:@"chevron.backward" withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        [_leftBackButton setImage:backImage forState:UIControlStateNormal];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
        UIImage *shareImage = [[UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        [_shareButton setImage:shareImage forState:UIControlStateNormal];
        [_shareButton addTarget:self action:@selector(shareBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    }
    return _titleLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [SLColorManager primaryBackgroundColor];
//        _contentView.clipsToBounds = NO;
//        _contentView.layer.cornerRadius = 16.0;
//        _contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    return _contentView;
}

- (UIView *)navigationView {
    if (!_navigationView) {
        _navigationView = [UIView new];
        _navigationView.backgroundColor = UIColor.clearColor;
    }
    return _navigationView;
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

- (void)setView:(UIView *)view{
    [super setView:view];
}

- (void)loadMessagesList:(CaocaoCarMessageListRefreshType)type {
    @weakobj(self);
    [self.viewModel loadMessageListWithRefreshType:type withPageStyle:0 withLabel:self.label souce:self.source articleId:self.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
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

#pragma mark - SLEmptyWithLoginButtonViewDelegate
- (void)gotoLoginPage {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login", H5BaseUrl]];
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [self presentViewController:dvc animated:YES completion:nil];
}

- (void)jumpToH5WithUrl:(NSString *)url andShowProgress:(BOOL)show {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    dvc.isShowProgress = show;
    [dvc startLoadRequestWithUrl:url];
    dvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:dvc animated:YES];
}

- (void)gotoArticaleDetail:(NSString *)articleId {
    SLArticleDetailViewControllerV2* vc = [SLArticleDetailViewControllerV2 new];
    vc.articleId = articleId;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SLArticleTodayEntity *entity = self.viewModel.dataArray[indexPath.row];
    [self gotoArticaleDetail: entity.articleId];
//    NSString *url = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, entity.articleId];
//    [self jumpToH5WithUrl:url andShowProgress:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel.dataArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SLProfileDynamicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLProfileDynamicTableViewCell" forIndexPath:indexPath];
    if (cell) {
        SLArticleTodayEntity *entity = [self.viewModel.dataArray objectAtIndex:indexPath.row];
        [cell updateWithEntity:entity];
        @weakobj(self);
        cell.likeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel likeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                if (!isSuccess) { //401
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    if (error) {
                        [self gotoLoginPage];
                    } else {
                        [self.view sl_showToast:request_error_msg];
                    }
                }
            }];
        };
        
        cell.dislikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel dislikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                if (!isSuccess) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    if (error) {
                        [self gotoLoginPage];
                    } else {
                        [self.view sl_showToast:request_error_msg];
                    }
                }
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
                                                                @"label": self.label,
                                                                @"index": @(0)
                                                            };
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
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                if (!isSuccess) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    if (error) {
                        [self gotoLoginPage];
                    } else {
                        [self.view sl_showToast:request_error_msg];
                    }
                }
            }];
        };
        cell.cancelDisLikeClick = ^(SLArticleTodayEntity *entity) {
            @strongobj(self);
            if (![SLUser defaultUser].isLogin) {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self gotoLoginPage];
                return;
            }
            [self.homeViewModel cancelLikeWith:entity.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
                if (!isSuccess) { //401
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self gotoLoginPage];
                }
            }];
        };
        cell.showDetailClick = ^(SLArticleTodayEntity * _Nonnull entity) {
            NSString *url = [NSString stringWithFormat:@"%@/post/%@",H5BaseUrl,entity.articleId];
            [self jumpToH5WithUrl:url andShowProgress:NO];
        };
    }
    return cell;
}

#pragma mark - UI Elements
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.clipsToBounds = YES;
        _tableView.layer.cornerRadius = 16.0;
        _tableView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
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
    }
    return _tableView;
}


- (SLTagListContainerViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[SLTagListContainerViewModel alloc] init];
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
