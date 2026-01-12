//
//  SLHomePageViewController.m
//  digg
//
//  Created by hey on 2024/9/24.
//

#import "SLHomePageViewController.h"
#import "SLGeneralMacro.h"
#import <JXCategoryView/JXCategoryView.h>
#import <JXCategoryView/JXCategoryListContainerView.h>
#import "UIView+CommonKit.h"
#import "SLHomeWebViewController.h"
#import "SLHomePageViewModel.h"
#import "SLColorManager.h"
#import "EnvConfigHeader.h"

@interface SLHomePageViewController ()<JXCategoryViewDelegate,JXCategoryListContainerViewDelegate>
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) JXCategoryNumberView *categoryView;
@property (nonatomic, strong) JXCategoryListContainerView *listContainerView;
@property (nonatomic, assign) BOOL isNeedIndicatorPositionChangeItem;
@property (nonatomic, strong) JXCategoryNumberView *myCategoryView;
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<JXCategoryListContentViewDelegate>> *listCache;
@property (nonatomic, strong) SLHomePageViewModel *viewModel;

@end

@implementation SLHomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self.view addSubview:self.categoryView];
    [self.view addSubview:self.listContainerView];
    self.titles = @[@"今天", @"发现", @"为你"];
    self.listCache = [NSMutableDictionary dictionary];

    CGFloat categoryViewHeight = 30;
    CGFloat categoryViewSpacing = 8;
    self.categoryView.frame = CGRectMake(0, STATUSBAR_HEIGHT, self.view.bounds.size.width-categoryViewHeight, categoryViewHeight);
    self.listContainerView.frame = CGRectMake(0, categoryViewHeight+STATUSBAR_HEIGHT+categoryViewSpacing, self.view.bounds.size.width, self.view.bounds.size.height-(categoryViewHeight+STATUSBAR_HEIGHT+categoryViewSpacing)-self.tabBarController.tabBar.frame.size.height);
    self.myCategoryView.titles = self.titles;
    self.myCategoryView.counts = @[@0, @0, @0];
    self.myCategoryView.numberLabelOffset = CGPointMake(-2, 5);
    self.myCategoryView.numberStringFormatterBlock = ^NSString *(NSInteger number) {
        if (number > 99) {
            return @"99+";
        }
        return [NSString stringWithFormat:@"%ld", (long)number];
    };
    
    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    lineView.indicatorColor = [SLColorManager themeColor];
    lineView.indicatorWidth = 28;
    self.myCategoryView.indicators = @[lineView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    @weakobj(self);
    [self.viewModel getForYouRedPoint:^(NSInteger number, NSError *error) {
        if (!error) {
            @strongobj(self);
            self.myCategoryView.counts = @[@0, @0, @(number)];
            [self.myCategoryView reloadDataWithoutListContainer];
        }
    }];
}

- (JXCategoryNumberView *)myCategoryView {
    return (JXCategoryNumberView *)self.categoryView;
}

- (JXCategoryNumberView *)preferredCategoryView {
    return [[JXCategoryNumberView alloc] init];
}

#pragma mark - JXCategoryViewDelegate

// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，不关心具体是点击还是滚动选中的。
- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    if (index == 2) {
        self.myCategoryView.counts = @[@0, @0, @0];
        [self.myCategoryView reloadDataWithoutListContainer];
    }
}

// 滚动选中的情况才会调用该方法
- (void)categoryView:(JXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index {
    if (index == 2) {
        self.myCategoryView.counts = @[@0, @0, @0];
        [self.myCategoryView reloadDataWithoutListContainer];
    }
}

#pragma mark - JXCategoryListContainerViewDelegate

// 返回列表的数量
- (NSInteger)numberOfListsInlistContainerView:(JXCategoryListContainerView *)listContainerView {
    return self.titles.count;
}

// 返回各个列表菜单下的实例，该实例需要遵守并实现 <JXCategoryListContentViewDelegate> 协议
- (id<JXCategoryListContentViewDelegate>)listContainerView:(JXCategoryListContainerView *)listContainerView initListForIndex:(NSInteger)index {
    
    NSString *targetTitle = self.titles[index];
    id<JXCategoryListContentViewDelegate> list = _listCache[targetTitle];
    if (list) {
        //②之前已经初始化了对应的list，就直接返回缓存的list，无需再次初始化
        return list;
    } else {
        SLHomeWebViewController *vc = [[SLHomeWebViewController alloc] init];
        NSString *url = @"";
        if (index == 0) {
            url = HOME_TODAY_PAGE_URL;
        } else if (index == 1) {
            url = HOME_RECENT_PAGE_URL;
        } else if (index == 2) {
            url = HOME_FORYOU_PAGE_URL;
        }
        [vc startLoadRequestWithUrl:url];
        _listCache[targetTitle] = vc;
        return vc;
    }
}

- (void)refreshCurrentPage {
    NSInteger index = self.categoryView.selectedIndex;
    if (index < self.titles.count) {
        NSString *targetTitle = self.titles[index];
        SLHomeWebViewController *vc = (SLHomeWebViewController *)_listCache[targetTitle];
        if (vc && [vc isKindOfClass:[SLHomeWebViewController class]]) {
            [vc sendRefreshPageDataMessage];
        }
    }
}


// 分页菜单视图
- (JXCategoryBaseView *)categoryView {
    if (!_categoryView) {
        _categoryView = [self preferredCategoryView];
        _categoryView.numberBackgroundColor = Color16(0x14932A);
        _categoryView.delegate = self;
        _categoryView.titleColorGradientEnabled = YES;
        _categoryView.titleLabelZoomEnabled = YES;
        _categoryView.titleFont = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _categoryView.titleLabelZoomScale = 1.125;
        _categoryView.titleSelectedColor = [SLColorManager categorySelectedTextColor];
        _categoryView.titleColor = [SLColorManager categoryNormalTextColor];
        // !!!: 将列表容器视图关联到 categoryView
        _categoryView.listContainer = self.listContainerView;
        _categoryView.cellSpacing = 24;
        _categoryView.averageCellSpacingEnabled = NO;
        _categoryView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _categoryView;
}

// 列表容器视图
- (JXCategoryListContainerView *)listContainerView {
    if (!_listContainerView) {
        _listContainerView = [[JXCategoryListContainerView alloc] initWithType:JXCategoryListContainerType_ScrollView delegate:self];
        _listContainerView.scrollView.showsHorizontalScrollIndicator = false;
        _listContainerView.scrollView.showsVerticalScrollIndicator = false;
        _listContainerView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _listContainerView;
}

- (SLHomePageViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[SLHomePageViewModel alloc] init];
    }
    return _viewModel;
}

@end
