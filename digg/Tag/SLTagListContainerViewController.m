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
#import <JXCategoryView/JXCategoryView.h>
#import <JXCategoryView/JXCategoryListContainerView.h>
#import "SLTagListContainerViewModel.h"
#import "SLProfileDynamicTableViewCell.h"
#import "CaocaoRefresh.h"
#import "SLHomePageViewModel.h"
#import "SLUser.h"
#import "SLWebViewController.h"
#import "SLAlertManager.h"
#import "SLTrackingManager.h"
#import "TMViewTrackerSDK.h"
#import "UIView+TMViewTracker.h"

@interface UILabel (LineCheck)

- (BOOL)isTextExceedingLines:(NSInteger)maxLines;

@end

@implementation UILabel (LineCheck)

- (BOOL)isTextExceedingLines:(NSInteger)maxLines {
    if (!self.text || !self.font) return NO;
    
    // 获取单行高度
    CGFloat singleLineHeight = [@"Single Line" sizeWithAttributes:@{NSFontAttributeName: self.font}].height;
    
    // 获取文本的实际高度
    CGFloat maxWidth = self.frame.size.width - 32;
    CGRect textRect = [self.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                           attributes:@{NSFontAttributeName: self.font}
                                              context:nil];
    CGFloat textHeight = textRect.size.height;
    
    // 比较实际高度与允许的最大高度
    return textHeight > singleLineHeight * maxLines;
}

@end

@interface SLTagListContainerViewController () <JXCategoryViewDelegate, JXCategoryListContainerViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* briefLabel;
@property (nonatomic, strong) UIView* contentView;

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) JXCategoryTitleView *categoryView;
//@property (nonatomic, strong) JXCategoryListContainerView *listContainerView;
@property (nonatomic, strong) JXCategoryTitleView *myCategoryView;

@property (nonatomic, strong) SLTagListContainerViewModel *viewModel;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) SLHomePageViewModel *homeViewModel;

@property (nonatomic, strong) UITableView *tableView;

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
    
    [TMViewTrackerManager setCurrentPageName:@"TagList"];
}

#pragma mark - Methods
- (void)setupUI {
    [self.view addSubview:self.navigationView];
    [self.navigationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(NAVBAR_HEIGHT + 5);
    }];
    
    [self.navigationView addSubview:self.leftBackButton];
    [self.leftBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.navigationView).offset(16);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    
    self.headerView.frame = CGRectMake(0, NAVBAR_HEIGHT, self.view.bounds.size.width, 130);
    [self.headerView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(15);
        make.left.equalTo(self.headerView).offset(16);
        make.right.equalTo(self.headerView).offset(-16);
    }];
    
    [self.headerView addSubview:self.briefLabel];
    [self.briefLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.titleLabel);
    }];
    
    [self.headerView addSubview:self.moreButton];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.briefLabel.mas_bottom).offset(8);
        make.left.equalTo(self.titleLabel);
        make.bottom.equalTo(self.headerView).offset(-25);
    }];
    
    self.titles = @[@"编辑精选", @"最新", @"最热"];
    self.myCategoryView.titles = self.titles;

    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    lineView.indicatorColor = Color16(0xFF1852);
    lineView.indicatorWidth = 28;
    self.myCategoryView.indicators = @[lineView];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.navigationView.mas_bottom);
        make.bottom.equalTo(self.view);
    }];
    
    [self updateTableHeaderViewHeight];
}

- (void)updateTableHeaderViewHeight {
    [self.headerView updateConstraintsIfNeeded];
    [self.headerView setNeedsLayout];
    [self.headerView layoutIfNeeded];
    
    CGFloat height = [self.headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGRect frame = self.headerView.frame;
    frame.size.height = height;
    self.headerView.frame = frame;
    self.tableView.tableHeaderView = self.headerView;
}

- (void)requestData {
    [self requestLabelInfo];
    [self requestTabList];
}

- (void)requestLabelInfo {
    @weakobj(self)
    [self.viewModel loadLabelInfoWithLabelId:self.label resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
        @strongobj(self)
        if (isSuccess) {
            self.briefLabel.text = self.viewModel.content;
            [self updateTableHeaderViewHeight];
            if ([self.briefLabel isTextExceedingLines: 2]) {
                [self.moreButton setHidden:NO];
            } else {
                [self.moreButton setHidden:YES];
            }
        }
    }];
}

- (void)requestTabList {
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

- (JXCategoryTitleView *)myCategoryView {
    return (JXCategoryTitleView *)self.categoryView;
}

- (JXCategoryTitleView *)preferredCategoryView {
    return [[JXCategoryTitleView alloc] init];
}

#pragma mark - JXCategoryViewDelegate
// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，不关心具体是点击还是滚动选中的。
- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

// 滚动选中的情况才会调用该方法
- (void)categoryView:(JXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index {
    [self loadMessagesList:CaocaoCarMessageListRefreshTypeRefresh];
}

#pragma mark - Actions
- (void)backPage {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)moreBrief {
    self.briefLabel.numberOfLines = 0;
    [self.moreButton setHidden:YES];
}

#pragma mark - UI Elements
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [UIView new];
        _headerView.backgroundColor = UIColor.clearColor;
        _headerView.clipsToBounds = NO;
        _headerView.layer.cornerRadius = 16.0;
        _headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    return _headerView;
}

- (UIButton *)leftBackButton {
    if (!_leftBackButton) {
        _leftBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBackButton setImage:[UIImage imageNamed:@"tag_left_icon"] forState:UIControlStateNormal];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"";
        _titleLabel.textColor = UIColor.blackColor;
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
    }
    return _titleLabel;
}

- (UILabel *)briefLabel {
    if (!_briefLabel) {
        _briefLabel = [[UILabel alloc] init];
        _briefLabel.text = @"";
        _briefLabel.textColor = Color16(0x999999);
        _briefLabel.font = [UIFont systemFontOfSize:12];
        _briefLabel.numberOfLines = 2;
    }
    return _briefLabel;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setTitle:@"更多" forState:UIControlStateNormal];
        [_moreButton setTitleColor:Color16(0x666666) forState:UIControlStateNormal];
        _moreButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_moreButton addTarget:self action:@selector(moreBrief) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = UIColor.whiteColor;
        _contentView.clipsToBounds = NO;
        _contentView.layer.cornerRadius = 16.0;
        _contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    return _contentView;
}

- (UIView *)navigationView {
    if (!_navigationView) {
        _navigationView = [UIView new];
        _navigationView.backgroundColor = Color16(0xF2F2F2);
    }
    return _navigationView;
}

// 分页菜单视图
- (JXCategoryBaseView *)categoryView {
    if (!_categoryView) {
        _categoryView = [self preferredCategoryView];
        _categoryView.delegate = self;
        _categoryView.titleColorGradientEnabled = YES;
        _categoryView.titleLabelZoomEnabled = YES;
        _categoryView.titleFont = [UIFont boldSystemFontOfSize:18];
        _categoryView.titleLabelZoomScale = 1.125;
        _categoryView.titleSelectedColor = [UIColor blackColor];
        _categoryView.titleColor = Color16(0x7B7B7B);
        _categoryView.cellSpacing = 24;
        _categoryView.averageCellSpacingEnabled = NO;
    }
    return _categoryView;
}

// ---- 

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
    [self.viewModel loadMessageListWithRefreshType:type withPageStyle:self.myCategoryView.selectedIndex withLabel:self.label resultHandler:^(BOOL isSuccess, NSError *error) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SLArticleTodayEntity *entity = self.viewModel.dataArray[indexPath.row];
    NSString *url = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, entity.articleId];
    [self jumpToH5WithUrl:url andShowProgress:NO];
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
        cell.controlName = @"TAG_LIST";
        cell.args = @{
            @"url": entity.url,
            @"title": entity.title,
            @"index": @(self.myCategoryView.selectedIndex)
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
                NSDictionary* param = @{
                    @"url": entity.url,
                    @"label": self.label,
                    @"index": @(self.myCategoryView.selectedIndex)
                };
                [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_TAGLIST" parameters:param];
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
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 58;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat categoryViewHeight = 58;
    UIView* sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, categoryViewHeight)];
    sectionView.backgroundColor = UIColor.whiteColor;
    sectionView.clipsToBounds = NO;
    sectionView.layer.cornerRadius = 16.0;
    sectionView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [sectionView addSubview:self.categoryView];
    [self.categoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sectionView).offset(14);
        make.left.right.equalTo(sectionView);
        make.bottom.equalTo(sectionView).offset(-14);
    }];
    return sectionView;
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
