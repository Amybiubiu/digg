//
//  SLProfileViewController.m
//  digg
//
//  Created by Tim Bao on 2025/1/5.
//

#import "SLProfileViewController.h"
#import "SLProfileHeaderView.h"
#import "Masonry.h"
#import "SLSegmentControl.h"
#import "SLGeneralMacro.h"
#import "SLHomePageNewsTableViewCellV2.h"
#import "SLEmptyWithLoginButtonView.h"
#import "SLWebViewController.h"
#import "EnvConfigHeader.h"
#import "SLUser.h"
#import "SLProfilePageViewModel.h"
#import "SDWebImage.h"
#import "SLProfileEntity.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "SLHomePageViewModel.h"
#import "SLEditProfileViewController.h"
#import "KxMenu.h"
#import "SVProgressHUD.h"
#import "SLProfileDynamicTableViewCell.h"
#import "SLTagListContainerViewController.h"
#import "digg-Swift.h"
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import "SLTrackingManager.h"
#import "TMViewTrackerSDK.h"
#import "UIView+TMViewTracker.h"
#import "SLArticleDetailViewControllerV2.h"
#import "SLZoomTransitionDelegate.h"


@interface SLProfileViewController () <SLSegmentControlDelegate, UITableViewDelegate, UITableViewDataSource, SLEmptyWithLoginButtonViewDelegate, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SLEmptyWithLoginButtonViewDelegate, SLProfileHeaderViewDelegate>

@property (nonatomic, strong) UIImageView* headerImageView;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;

@property (nonatomic, strong) UIButton* leftBackButton;
@property (nonatomic, strong) UIButton* moreButton;
@property (nonatomic, strong) UILabel* nameLabel;
@property (nonatomic, strong) UILabel* briefLabel;
@property (nonatomic, strong) SLProfileHeaderView* headerView;

@property (nonatomic, strong) SLSegmentControl* segmentControl;
@property (nonatomic, strong) UIView* line;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *hideView;

@property (nonatomic, strong) SLEmptyWithLoginButtonView* emptyView;

@property (nonatomic, strong) SLProfilePageViewModel *viewModel;
@property (nonatomic, strong) SLHomePageViewModel *homeViewModel;

@end

@implementation SLProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self setupUI];
    [self.hideView setHidden:NO];
    
    [TMViewTrackerManager setCurrentPageName:@"Profile"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tableView.backgroundColor = UIColor.clearColor;
    if (!_fromWeb) {
        @weakobj(self)
        [self.viewModel isUserLogin:^(BOOL isLogin, NSError * _Nonnull error) {
            @strongobj(self)
            if (isLogin) {
                if ([self.userId length] == 0) {
                    self.userId = [SLUser defaultUser].userEntity.userId;
                }
                [self updateUI];
            } else {
                [self.hideView setHidden:YES];
                [self.emptyView setHidden:NO];
            }
        }];
    } else {
        [self updateUI];
    }
}

- (void)updateUI {
    if (!_fromWeb) {
        [self.hideView setHidden:YES];
        if (self.userId.length == 0) {
            [self.emptyView setHidden:NO];
        } else {
            [self.emptyView setHidden:YES];
            
            @weakobj(self);
            [self.viewModel loadUserProfileWithProfileID:self.userId resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
                @strongobj(self)
                if (isSuccess) {
                    if ([self.viewModel.entity.bgImage length] > 0) {
                        [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:self.viewModel.entity.bgImage]];
                    }
                    
                    self.nameLabel.text = self.viewModel.entity.userName;
                    self.briefLabel.text = self.viewModel.entity.desc;
                    if (self.viewModel.entity.isSelf && !self.fromWeb) {
                        [self.leftBackButton setHidden:YES];
                        [self.moreButton setHidden:NO];
                        [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.headerImageView).offset(16);
                            make.top.equalTo(self.headerImageView).offset(52);
                            make.right.equalTo(self.moreButton.mas_left).offset(-12);
                        }];
                    } else {
                        [self.leftBackButton setHidden:NO];
                        [self.moreButton setHidden:YES];
                        [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.leftBackButton.mas_right).offset(12);
                            make.bottom.equalTo(self.leftBackButton.mas_centerY);
                            make.right.equalTo(self.moreButton.mas_left).offset(-12);
                        }];
                    }
                    self.headerView.entity = self.viewModel.entity;
                    [self updateTableHeaderViewHeight];
                    [self.tableView reloadData];
                }
            }];
        }
    } else {
        [self.hideView setHidden:YES];
        [self.emptyView setHidden:YES];
        @weakobj(self);
        [self.viewModel loadUserProfileWithProfileID:self.userId resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
            @strongobj(self)
            if (isSuccess) {
                if ([self.viewModel.entity.bgImage length] > 0) {
                    [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:self.viewModel.entity.bgImage]];
                }
                
                self.nameLabel.text = self.viewModel.entity.userName;
                self.briefLabel.text = self.viewModel.entity.desc;
                if (self.viewModel.entity.isSelf && !self.fromWeb) {
                    [self.leftBackButton setHidden:YES];
                    [self.moreButton setHidden:NO];
                    [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(self.headerImageView).offset(16);
                        make.top.equalTo(self.headerImageView).offset(52);
                        make.right.equalTo(self.moreButton.mas_left).offset(-12);
                    }];
                } else {
                    [self.leftBackButton setHidden:NO];
                    [self.moreButton setHidden:YES];
                    [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(self.leftBackButton.mas_right).offset(12);
                        make.bottom.equalTo(self.leftBackButton.mas_centerY);
                        make.right.equalTo(self.moreButton.mas_left).offset(-12);
                    }];
                }
                self.headerView.entity = self.viewModel.entity;
                [self updateTableHeaderViewHeight];
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)updateTableHeaderViewHeight {
    UIView *currentHeaderView = self.tableView.tableHeaderView;
    
    // 只在必要时强制布局
    if (!self.headerView.frame.size.height) {
        [self.headerView setNeedsLayout];
        [self.headerView layoutIfNeeded];
    }
    
    CGFloat height = [self.headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    // 只有当高度发生变化时才更新frame
    if (self.headerView.frame.size.height != height) {
        CGFloat oldHeight = self.headerView.frame.size.height;

        CGRect frame = self.headerView.frame;
        frame.size.height = height;

        [UIView animateWithDuration:0.3 animations:^{
            self.headerView.frame = frame;
            self.headerImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, height);
            self.blurEffectView.frame = self.headerImageView.bounds;
            
            // 调整tableView的contentOffset以保持视觉连续性
            if (oldHeight > 0) {
                CGFloat offsetDiff = height - oldHeight;
                CGPoint contentOffset = self.tableView.contentOffset;
                if (contentOffset.y <= 0) { // 只在顶部时调整
                    contentOffset.y -= offsetDiff;
                    self.tableView.contentOffset = contentOffset;
                }
            }
        } completion:^(BOOL finished) {
            // 只有当headerView不是当前tableHeaderView时才设置
            if (currentHeaderView != self.headerView) {
                self.tableView.tableHeaderView = self.headerView;
            } else {
                // 即使是同一个headerView，也需要重新设置以更新布局
                self.tableView.tableHeaderView = self.headerView;
            }
        }];
    }
}

#pragma mark - Setup UI
- (void)setupUI {
    self.headerImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 180);
    [self.view addSubview:self.headerImageView];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.frame = self.headerImageView.bounds;
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blurEffectView.alpha = 0;
    [self.headerImageView addSubview:self.blurEffectView];
    
    [self.headerImageView addSubview:self.leftBackButton];
    [self.leftBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.headerImageView).offset(16);
        make.top.equalTo(self.headerImageView).offset(52);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    
    [self.headerImageView addSubview:self.moreButton];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.leftBackButton);
        make.right.equalTo(self.headerImageView).offset(-16);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    
    [self.headerImageView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.leftBackButton.mas_right).offset(12);
        make.bottom.equalTo(self.leftBackButton.mas_centerY);
        make.right.equalTo(self.moreButton.mas_left).offset(-12);
    }];
    
    [self.headerImageView addSubview:self.briefLabel];
    [self.briefLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.nameLabel);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
    }];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(98);
        make.left.right.equalTo(self.view);
        if (self.fromWeb) {
            make.bottom.equalTo(self.view);
        } else {
            make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
        }
    }];
    self.tableView.tableHeaderView = self.headerView;
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
    }];
    [self updateTableHeaderViewHeight];
    
    [self.view addSubview:self.emptyView];
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
    }];
    [self.view addSubview:self.hideView];
    [self.hideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.tableView).offset(120);
        make.bottom.equalTo(self.view);
    }];
}

#pragma mark - Actions
- (void)backPage {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showMenu {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular scale:UIImageSymbolScaleMedium];
    UIImage *powerImage = [UIImage systemImageNamed:@"power" withConfiguration:config];

    UIAction *logoutAction = [UIAction actionWithTitle:@"退出登录"
                                                    image:powerImage
                                            identifier:nil
                                                handler:^(__kindof UIAction * _Nonnull action) {
        [self logoutAction];
    }];
    
    // 创建菜单
    UIMenu *menu = [UIMenu menuWithTitle:@""
                                    children:@[logoutAction]];
    
    // 设置按钮的菜单
    self.moreButton.showsMenuAsPrimaryAction = YES;
    self.moreButton.menu = menu;
}

- (void)logoutAction {
    [SVProgressHUD show];
    @weakobj(self)
    [self.viewModel logout:^(BOOL success, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        if (success) {
            @strongobj(self)
            self.userId = @"";
            [self updateUI];
        }
    }];
}

#pragma mark - SLSegmentControlDelegate
- (void)segmentControl:(SLSegmentControl *)segmentControl didSelectIndex:(NSInteger)index {
    [self.tableView reloadData];
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
        self.userId = [SLUser defaultUser].userEntity.userId;
        NSLog(@"userid = %@", self.userId);
        [self updateUI];
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = scrollView.contentOffset;
        
    CGFloat alpha = MAX(0, MIN(1, contentOffset.y / 100));
    self.nameLabel.alpha = alpha;
    self.briefLabel.alpha = alpha;
    self.blurEffectView.alpha = alpha;
    // 设置头像的变换
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat avatarSize = 60;
    CGFloat minAvatarSize = 30;

    CGFloat offsetY = scrollView.contentOffset.y;
    
    // 限制最大偏移
     CGFloat avatarInitialSize = avatarSize;
     CGFloat avatarFinalSize = minAvatarSize;
    
    // 计算缩放比例
    CGFloat scaleFactor = MAX(avatarFinalSize / avatarInitialSize, 1 - offsetY / 100);
    if (scaleFactor > 1.0) {
        scaleFactor = 1.0;
    }
    
    // 应用缩放和位置变化
    self.headerView.avatarImageView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    
    // 限制 header 的压缩高度
    if (offsetY > 0) {
        self.headerView.frame = CGRectMake(0, -offsetY, self.view.bounds.size.width, headerHeight);
    }
}

#pragma mark - SLProfileHeaderViewDelegate
- (void)gotoEditPersonalInfo {
   UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"输入网址"
                                                                            message:@"请输入您想要访问的网址"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
   [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       textField.placeholder = @"https://";
       textField.keyboardType = UIKeyboardTypeURL;
       textField.autocorrectionType = UITextAutocorrectionTypeNo;
       textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
   }];
   
   UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
       NSString *url = alertController.textFields.firstObject.text;
       
       if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
           url = [NSString stringWithFormat:@"https://%@", url];
       }
       SLWebViewController *webVC = [[SLWebViewController alloc] init];
       webVC.isShowProgress = NO;
       [webVC startLoadRequestWithUrl:url];
       webVC.hidesBottomBarWhenPushed = YES;
       [self.navigationController pushViewController:webVC animated:YES];
   }];
   
   UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
   [alertController addAction:confirmAction];
   [alertController addAction:cancelAction];
   
   [self presentViewController:alertController animated:YES completion:nil];
    
//    SLEditProfileViewController* vc = [SLEditProfileViewController new];
//    vc.entity = self.viewModel.entity;
//    @weakobj(self)
//    vc.updateSucessCallback = ^{
//        @strongobj(self)
//        [self updateUI];
//    };
//    [self presentViewController:vc animated:YES completion:nil];
}

- (void)follow:(BOOL)cancel {
    [SVProgressHUD show];
    @weakobj(self)
    [self.viewModel followWithUserID:self.userId cancel:cancel resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (isSuccess) {
            @strongobj(self)
            self.viewModel.entity.hasFollow = cancel;
            self.headerView.entity = self.viewModel.entity;
        }
    }];
}

- (void)gotoArticaleDetail:(NSString *)articleId {
    SLArticleDetailViewControllerV2* vc = [SLArticleDetailViewControllerV2 new];
    vc.articleId = articleId;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SLArticleTodayEntity *entity;
    if (self.segmentControl.selectedIndex == 0) {
        entity = [self.viewModel.entity.feedList objectAtIndex:indexPath.row];
    } else if (self.segmentControl.selectedIndex == 1) {
        entity = [self.viewModel.entity.likeList objectAtIndex:indexPath.row];
    } else if (self.segmentControl.selectedIndex == 2) {
        entity = [self.viewModel.entity.submitList objectAtIndex:indexPath.row];
    }
    [self gotoArticaleDetail: entity.articleId];
//    NSString *url = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, entity.articleId];
//    [self jumpToH5WithUrl:url andShowProgress:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentControl.selectedIndex == 0) {
        return self.viewModel.entity.feedList.count;
    } else if (self.segmentControl.selectedIndex == 1) {
        return self.viewModel.entity.likeList.count;
    } else if (self.segmentControl.selectedIndex == 2) {
        return self.viewModel.entity.submitList.count;
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 41)];
    sectionView.backgroundColor = [SLColorManager primaryBackgroundColor];
    [sectionView addSubview:self.segmentControl];
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sectionView);
        make.left.equalTo(sectionView).offset(50);
        make.right.equalTo(sectionView).offset(-50);
        make.height.mas_equalTo(40);
    }];
    
    [sectionView addSubview:self.line];
    [self.line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom);
        make.left.right.equalTo(sectionView);
        make.height.mas_equalTo(1);
    }];
    return sectionView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.segmentControl.selectedIndex == 0) {
        SLProfileDynamicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLProfileDynamicTableViewCell" forIndexPath:indexPath];
        if (cell) {
            SLArticleTodayEntity *entity = [self.viewModel.entity.feedList objectAtIndex:indexPath.row];
            [cell updateWithEntity:entity];
            cell.controlName = @"Profile_LIST";
            cell.args = @{
                @"url": entity.url,
                @"title": entity.title,
                @"index": @(self.segmentControl.selectedIndex)
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
                SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                                   message:nil
                                                                       url:[NSURL URLWithString:entity.url]
                                                                   urlText:entity.url
                                                              confirmTitle:@"是"
                                                               cancelTitle:@"否"
                                                            confirmHandler:^{
                                                                NSDictionary* param = @{
                                                                    @"url": entity.url,
                                                                    @"index": @(self.segmentControl.selectedIndex)
                                                                };
                                                                [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_PROFILE" parameters:param];
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
    } else {
        SLHomePageNewsTableViewCellV2 *cell = [tableView dequeueReusableCellWithIdentifier:@"SLHomePageNewsTableViewCellV2" forIndexPath:indexPath];
        if (cell) {
            SLArticleTodayEntity *entity;
            if (self.segmentControl.selectedIndex == 1) {
                entity = [self.viewModel.entity.likeList objectAtIndex:indexPath.row];
            } else if (self.segmentControl.selectedIndex == 2) {
                entity = [self.viewModel.entity.submitList objectAtIndex:indexPath.row];
            }
            [cell updateWithEntity:entity];
            cell.controlName = @"Profile_LIST";
            cell.args = @{
                @"url": entity.url,
                @"title": entity.title,
                @"index": @(self.segmentControl.selectedIndex)
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
                SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                                   message:nil
                                                                       url:[NSURL URLWithString:entity.url]
                                                                   urlText:entity.url
                                                              confirmTitle:@"是"
                                                               cancelTitle:@"否"
                                                            confirmHandler:^{
                                                                NSDictionary* param = @{
                                                                    @"url": entity.url,
                                                                    @"index": @(self.segmentControl.selectedIndex)
                                                                };
                                                                [[SLTrackingManager sharedInstance] trackEvent:@"OPEN_DETAIL_FROM_PROFILE" parameters:param];
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
            cell.labelClick = ^(SLArticleTodayEntity *entity) {
                if (entity.label.length > 0) {
                    @strongobj(self);
                    SLTagListContainerViewController* vc = [SLTagListContainerViewController new];
                    vc.hidesBottomBarWhenPushed = YES;
                    vc.label = entity.label;
                    vc.entity = entity;
                    vc.source = @"self";
                    vc.articleId = entity.articleId;
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
    return [UITableViewCell new];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"empty_placeholder"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"还没有内容";
    
    NSDictionary *attributes = @{
                              NSFontAttributeName: [UIFont pingFangSemiboldWithSize:16.0f],
                              NSForegroundColorAttributeName: Color16(0xC6C6C6)
                             };
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return 98.0/2.0;
}

#pragma mark - SLProfileHeaderViewDelegate

- (void)profileHeaderView:(SLProfileHeaderView *)headerView didSelectTag:(NSString *)tag atIndex:(NSInteger)index {
    SLTagListContainerViewController* vc = [SLTagListContainerViewController new];
    vc.label = tag;
    vc.source = @"self";
    vc.articleId = @"";
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma makr - UI Elements
- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
        _headerImageView.backgroundColor = UIColor.clearColor;
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_headerImageView setUserInteractionEnabled:YES];
    }
    return _headerImageView;
}

- (UIButton *)leftBackButton {
    if (!_leftBackButton) {
        _leftBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 创建配置
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular scale:UIImageSymbolScaleMedium];
        // 创建图标并设置颜色
        UIImage *backImage = [[UIImage systemImageNamed:@"chevron.backward" withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        // 设置按钮背景为黑色圆形
        _leftBackButton.backgroundColor =  [UIColor colorWithWhite:0 alpha:0.4];
        _leftBackButton.layer.cornerRadius = 16; // 圆形效果
        _leftBackButton.clipsToBounds = YES;
        
        [_leftBackButton setImage:backImage forState:UIControlStateNormal];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 创建配置 - 调整大小使图标更大
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular scale:UIImageSymbolScaleMedium];
        
        // 使用普通的ellipsis图标而不是circle.fill版本
        UIImage *moreImage = [[UIImage systemImageNamed:@"ellipsis" withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        
        // 设置按钮背景为黑色圆形
        _moreButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _moreButton.layer.cornerRadius = 16; // 圆形效果
        _moreButton.clipsToBounds = YES;
        
        [_moreButton setImage:moreImage forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"";
        _nameLabel.textColor = UIColor.whiteColor;
        _nameLabel.font = [UIFont pingFangSemiboldWithSize:18];
        _nameLabel.alpha = 0;
    }
    return _nameLabel;
}

- (UILabel *)briefLabel {
    if (!_briefLabel) {
        _briefLabel = [[UILabel alloc] init];
        _briefLabel.text = @"";
        _briefLabel.textColor = UIColor.whiteColor;
        _briefLabel.font = [UIFont pingFangRegularWithSize:12];
        _briefLabel.alpha = 0;
    }
    return _briefLabel;
}

- (SLProfileHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[SLProfileHeaderView alloc] init];
        _headerView.backgroundColor = [UIColor clearColor];
        _headerView.delegate = self;
    }
    return _headerView;
}

- (SLSegmentControl *)segmentControl {
    if (!_segmentControl) {
        _segmentControl = [[SLSegmentControl alloc] initWithFrame:CGRectZero];
        _segmentControl.titles = @[@"动态", @"赞同", @"发布"];
        _segmentControl.delegate = self; // 设置代理为当前控制器
    }
    return _segmentControl;
}

- (UIView *)line {
    if (!_line) {
        _line = [UIView new];
        _line.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _line;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[SLHomePageNewsTableViewCellV2 class] forCellReuseIdentifier:@"SLHomePageNewsTableViewCellV2"];
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

- (SLEmptyWithLoginButtonView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[SLEmptyWithLoginButtonView alloc] initWithFrame:CGRectZero];
        _emptyView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _emptyView.delegate = self;
        [_emptyView setHidden:YES];
    }
    return _emptyView;
}

- (SLProfilePageViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[SLProfilePageViewModel alloc] init];
    }
    return _viewModel;
}

- (SLHomePageViewModel *)homeViewModel {
    if (!_homeViewModel) {
        _homeViewModel = [[SLHomePageViewModel alloc] init];
    }
    return _homeViewModel;
}

- (UIView *)hideView {
    if (!_hideView) {
        _hideView = [[UIView alloc] initWithFrame:CGRectZero];
        _hideView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _hideView;
}

@end
