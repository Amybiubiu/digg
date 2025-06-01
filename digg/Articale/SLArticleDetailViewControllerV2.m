//
//  SLArticleDetailViewController.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleDetailViewControllerV2.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLArticleEntity.h"
#import "SLArticleDetailViewModel.h"
#import "SLUser.h"
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import <SDWebImage/SDWebImage.h>
#import "SLCommentCellV2.h"
#import "SLShowMoreCell.h"
#import "SLSecondCommentCell.h"
#import "SLArticleTagCell.h"
#import "SLWebViewController.h"
#import "SVProgressHUD.h"
#import "SLCustomNavigationBar.h"
#import "SLTagListView.h"
#import "SLTagListContainerViewController.h"
#import "SLCommentInputViewController.h"
#import "SLBottomToolBar.h"
#import "SLArticleHeaderView.h"
#import "SLArticleContentView.h"
#import "SLRelatedLinksView.h"
#import "EnvConfigHeader.h"
#import "UIView+SLToast.h"
#import "SLHomePageViewModel.h"
#import "SLRecordViewController.h"
#import "SLAddLinkViewController.h"
#import "SLProfileViewController.h"
#import "SLEmptyCommentCell.h"
#import "SLEndOfListCell.h"


@interface SLArticleDetailViewControllerV2 () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SLCustomNavigationBarDelegate, SLBottomToolBarDelegate>

// 导航栏
@property (nonatomic, strong) SLCustomNavigationBar *navigationBar;
// 底部工具栏
@property (nonatomic, strong) SLBottomToolBar *toolbarView;
// 内容区域
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) SLArticleHeaderView *articleHeaderView;
@property (nonatomic, strong) SLArticleContentView *articleContentView;
@property (nonatomic, strong) SLTagListView *tagListView;
@property (nonatomic, strong) SLRelatedLinksView *relatedLinksView;
// 数据
@property (nonatomic, strong) SLHomePageViewModel *homeViewModel;
@property (nonatomic, strong) SLArticleDetailViewModel *viewModel;
@property (nonatomic, strong) SLArticleTodayEntity *articleEntity;
@property (nonatomic, strong) NSArray<NSString *> *tags;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;

// 滚动相关
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isNavBarHidden;
@property (nonatomic, assign) BOOL isToolbarHidden;
@property (nonatomic, assign) CGFloat tabBarHeight;
@property (nonatomic, assign) CGFloat scrollThreshold;
@property (nonatomic, assign) NSTimeInterval lastScrollTime;
@property (nonatomic, assign) CGFloat scrollVelocity;
@property (nonatomic, assign) BOOL isAtBottomState;
@property (nonatomic, assign) BOOL isLoadData;

@end

@implementation SLArticleDetailViewControllerV2

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isLoadData = NO;
    self.homeViewModel = [[SLHomePageViewModel alloc] init];
    [self setupUI];
    [self setupGestures];
    
    // 初始化评论输入控制器
    self.commentVC = [[SLCommentInputViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    [self loadData];
}

#pragma mark - Private Methods

- (void)setupUI {
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    // 设置导航栏
    [self setupNavigationBar];
    
    // 设置底部工具栏
    [self setupToolbar];
    
    // 设置内容区域
    [self setupContentView];
}

- (void)setupNavigationBar {
    self.navigationBar = [[SLCustomNavigationBar alloc] init];
    self.navigationBar.delegate = self;
    [self.view addSubview:self.navigationBar];
    
    [self.navigationBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@(NAVBAR_HEIGHT));
    }];
}

- (void)setupToolbar {
    self.tabBarHeight = 49.0 + kiPhoneXBottomMargin;
    self.toolbarView = [[SLBottomToolBar alloc] init];
    self.toolbarView.delegate = self;
    [self.view addSubview:self.toolbarView];
    
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@(self.tabBarHeight));
    }];
}

- (void)setupContentView {
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = UIColor.clearColor; //[SLColorManager primaryBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 100.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[SLCommentCellV2 class] forCellReuseIdentifier:@"SLCommentCellV2"];
    [self.tableView registerClass:[SLSecondCommentCell class] forCellReuseIdentifier:@"SLSecondCommentCell"];
    [self.tableView registerClass:[SLShowMoreCell class] forCellReuseIdentifier:@"SLShowMoreCell"];
    [self.tableView registerClass:[SLEmptyCommentCell class] forCellReuseIdentifier:@"SLEmptyCommentCell"];
    [self.tableView registerClass:[SLEndOfListCell class] forCellReuseIdentifier:@"SLEndOfListCell"];
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.bounces = NO;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationBar.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbarView.mas_top);
    }];
    
    // 创建表头视图
    [self setupTableHeaderView];
}

- (void)setupTableHeaderView {
    __weak typeof(self) weakSelf = self;
    // 创建表头视图
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0)];
    self.headerView.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    // 1. 顶部区域 - 固定高度
    self.articleHeaderView = [[SLArticleHeaderView alloc] init];
    self.articleHeaderView.readOriginalHandler = ^{
        [weakSelf readOriginalArticle];
    };
    self.articleHeaderView.avatarClickHandler = ^{
        [weakSelf gotoProfilePage:weakSelf.viewModel.userEntity.userId];
    };
    [self.headerView addSubview:self.articleHeaderView];
    
    // 2. 内容区域 - 富文本内容
    self.articleContentView = [[SLArticleContentView alloc] init];
    self.articleContentView.heightChangedHandler = ^(CGFloat height) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.articleContentView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(height);
            }];
            [weakSelf updateTableHeaderViewHeight];
        });
    };
    [self.headerView addSubview:self.articleContentView];
    
    // 3. 标签区域
    self.tagListView = [[SLTagListView alloc] init];
    self.tagListView.tagClickHandler = ^(NSString *tag) {
        [weakSelf handleTagClick:tag];
    };
    [self.headerView addSubview:self.tagListView];

    // 4. 相关链接区域
    self.relatedLinksView = [[SLRelatedLinksView alloc] init];
    self.relatedLinksView.linkClickHandler = ^(SLReferEntity *refer) {
        [weakSelf handleReferClick:refer];
    };
    [self.headerView addSubview:self.relatedLinksView];
    
    // 设置约束
    CGFloat margin = 16.0;
    
    // 1. 顶部区域约束
    [self.articleHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView);
        make.left.equalTo(self.headerView);
        make.right.equalTo(self.headerView);
    }];
    
    // 2. 内容区域约束
    [self.articleContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.articleHeaderView.mas_bottom).offset(margin - 4); //margin 因为内部设置了行间距4
        make.left.equalTo(self.headerView);
        make.right.equalTo(self.headerView);
        make.height.mas_equalTo(0);
    }];
    
    // 3. 标签区域约束
    [self.tagListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.articleContentView.mas_bottom).offset(margin);
        make.left.equalTo(self.headerView).offset(margin);
        make.right.equalTo(self.headerView).offset(-margin);
        make.height.equalTo(@0);
    }];
    
   // 4. 相关链接区域约束
   [self.relatedLinksView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.top.equalTo(self.tagListView.mas_bottom).offset(margin);
       make.left.equalTo(self.headerView).offset(margin);
       make.right.equalTo(self.headerView).offset(-margin);
       make.height.mas_equalTo(0);
       make.bottom.equalTo(self.headerView);
   }];
}

// 添加阅读原文方法
- (void)readOriginalArticle {
    if (self.viewModel.articleEntity.url.length > 0) {
        //TODO:打开safafi 之前弹窗：是否要访问
        SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                           message:nil
                                                               url:[NSURL URLWithString:self.viewModel.articleEntity.url]
                                                           urlText:self.viewModel.articleEntity.url
                                                      confirmTitle:@"是"
                                                       cancelTitle:@"否"
                                                    confirmHandler:^{
                                                        NSURL* url = [NSURL URLWithString:self.viewModel.articleEntity.url];
                                                        if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                        } else {
                                                            [self.view sl_showToast:@"链接异常，无法打开"];
                                                        }
                                                    }
                                                     cancelHandler:^{
                                                    }
                                                 fromViewController:nil];
        [alertView show];
    }
}

// 跳转到profile页面
- (void)gotoProfilePage:(NSString *)userId {
    SLProfileViewController *dvc = [[SLProfileViewController alloc] init];
    dvc.userId = userId;
    dvc.fromWeb = YES;
    [self.navigationController pushViewController:dvc animated:YES];

}

- (void)loadData {
    if (!self.viewModel) {
        self.viewModel = [[SLArticleDetailViewModel alloc] init];
    }
    
//    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    
    [self.viewModel loadArticleDetail:self.articleId resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
//        [SVProgressHUD dismiss];
        if (isSuccess) {
            self.isLoadData = YES;
            SLArticleDetailEntity *articleEntity = weakSelf.viewModel.articleEntity;
            if (articleEntity) {
                // 更新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateUIWithArticleEntity:articleEntity];
                });
            }
        }
    }];
}

- (void)updateUIWithArticleEntity:(SLArticleDetailEntity *)entity {
    // 更新顶部区域
    NSString *publishTimeStr = @"";
    if (entity.gmtCreate) {
        NSDate *publishDate = [NSDate dateWithTimeIntervalSince1970:[entity.gmtCreate doubleValue]/1000];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        publishTimeStr = [dateFormatter stringFromDate:publishDate];
    }
    
    [self.articleHeaderView setupWithTitle:entity.title
                                    source:entity.source
                               avatarImage:self.viewModel.userEntity.avatar
                                authorName:self.viewModel.userEntity.userName
                               publishTime:publishTimeStr
                                     url:entity.url];
    
    // 更新内容区域
    NSString* content = entity.richContent ?: entity.content;
    if (content.length > 0) {
        self.articleContentView.hidden = NO;
        [self.articleContentView setupWithRichContent:content];
    } else {
        self.articleContentView.hidden = YES;
        [self.articleContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }

    // 更新标签
    if (entity.labels.count > 0) {
        self.tagListView.hidden = NO;
        [self.tagListView setTags:entity.labels];
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@24);
        }];
    } else {
        self.tagListView.hidden = YES;
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
    }

    // 更新相关链接区域
    [self.relatedLinksView setupWithReferList:self.viewModel.referList];
    [self.relatedLinksView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.relatedLinksView getContentHeight]);
    }];

    // 更新底部工具栏
    [self.toolbarView updateLikeStatus:entity.liked count:entity.likeCnt];
    [self.toolbarView updateCommentCount:entity.commentsCnt];
    [self.toolbarView updateShareCount:entity.share];
    
    // 更新表头视图高度
    [self updateTableHeaderViewHeight];
    
    // 加载评论数据
    [self.tableView reloadData];
}

- (void)updateTableHeaderViewHeight {    
    // 修改：使用更可靠的方式计算高度
    CGFloat margin = 16.0;
    CGFloat height = margin;

    height += [self.articleHeaderView getContentHeight];
    height += margin;
    if (!self.articleContentView.isHidden) {
        height += [self.articleContentView getContentHeight];
        height += margin - 4;
        
        [self.articleContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.articleHeaderView.mas_bottom).offset(margin - 4);
        }];
    } else {
        [self.articleContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.articleHeaderView.mas_bottom).offset(0);
        }];
    }

    if (!self.tagListView.isHidden) {
        height += [self.tagListView getContentHeight];
        height += margin;
        
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.articleContentView.mas_bottom).offset(margin);
        }];
    } else {
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.articleContentView.mas_bottom).offset(0);
        }];
    }
    
    if (self.viewModel.referList.count > 0) {
        height += [self.relatedLinksView getContentHeight];
        
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagListView.mas_bottom).offset(margin);
        }];
    } else {
        [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagListView.mas_bottom).offset(0);
        }];
    }
    
    if (self.articleContentView.isHidden && self.tagListView.isHidden && self.viewModel.referList.count == 0) {
        height -= margin;
        
        [self.articleHeaderView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.headerView);
        }];
    }

    CGRect frame = self.headerView.frame;
    frame.size.height = height;
    self.headerView.frame = frame;
    
    self.tableView.tableHeaderView = self.headerView;
}

#pragma mark - Action Methods

// 添加处理相关链接点击的方法
- (void)handleReferClick:(SLReferEntity *)refer {
    if (refer.url.length > 0) {
        SLCustomAlertView *alertView = [SLAlertManager showCustomAlertWithTitle:@"您确定要打开此链接吗？"
                                                           message:nil
                                                               url:[NSURL URLWithString:refer.url]
                                                           urlText:refer.url
                                                      confirmTitle:@"是"
                                                       cancelTitle:@"否"
                                                    confirmHandler:^{
                                                        NSURL* url = [NSURL URLWithString:refer.url];
                                                        if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                        } else {
                                                            [self.view sl_showToast:@"链接异常，无法打开"];
                                                        }
                                                    }
                                                     cancelHandler:^{
                                                    }
                                                 fromViewController:nil];
        [alertView show];
    }
}

- (void)likeButtonTapped {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        return;
    }
    @weakobj(self)
    if (self.viewModel.articleEntity.liked) {
        // 如果已经点赞，则取消点赞
        [self.homeViewModel cancelLikeWith:self.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
            @strongobj(self)
            if (isSuccess) {
                self.viewModel.articleEntity.liked = NO;
                self.viewModel.articleEntity.likeCnt -= 1;
                [self.toolbarView updateLikeStatus:NO count:self.viewModel.articleEntity.likeCnt];
            } else {
                if (error) {
                    [self gotoLoginPage];
                } else {
                    [self.view sl_showToast:request_error_msg];
                }
            }
        }];
    } else {
        // 如果未点赞，则点赞
        [self.homeViewModel likeWith:self.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
            @strongobj(self)
            if (isSuccess) {
                self.viewModel.articleEntity.liked = YES;
                self.viewModel.articleEntity.likeCnt += 1;
                [self.toolbarView updateLikeStatus:YES count:self.viewModel.articleEntity.likeCnt];
            } else {
                if (error) {
                    [self gotoLoginPage];
                } else {
                    [self.view sl_showToast:request_error_msg];
                }
            }
        }];
    }
}

- (void)commentButtonTapped {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.commentVC.placeholder = @"写回复";
    self.commentVC.submitHandler = ^(NSString *text) {
        [weakSelf submitCommentToArticle:text];
    };
    [self.commentVC showInViewController:self];
}

- (void)handleTagClick:(NSString *)tag {
    SLTagListContainerViewController *tagListVC = [[SLTagListContainerViewController alloc] init];
    tagListVC.label = tag;
    tagListVC.source = @"article";
    tagListVC.articleId = self.articleId;
    [self.navigationController pushViewController:tagListVC animated:YES];
}

#pragma mark - Helper Methods

- (void)gotoLoginPage {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login", H5BaseUrl]];
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [self presentViewController:dvc animated:YES completion:nil];
}

- (void)submitCommentToArticle:(NSString *)comment {
    if (comment.length == 0) {
        return;
    }
    
    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    
    // 获取文章作者ID
    NSString *replyUserId = self.viewModel.articleEntity.userId;
    
    // 调用ViewModel中的一级评论接口
    [self.viewModel replyToArticle:self.articleId 
                       replyUserId:replyUserId 
                          content:comment 
                    resultHandler:^(SLCommentEntity * _Nullable newComment, NSError * _Nullable error) {
        [SVProgressHUD dismiss];
        weakSelf.commentVC.textView.text = @"";
        if (newComment) {
            // 更新评论数
            [weakSelf.toolbarView updateCommentCount:weakSelf.viewModel.articleEntity.commentsCnt + 1];
            weakSelf.viewModel.articleEntity.commentsCnt += 1;
            
            // 使用插入section的方式更新表格
            [weakSelf.tableView beginUpdates];
            [weakSelf.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
            [weakSelf.tableView endUpdates];
            
            // 滚动到新插入的评论
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            // 显示成功提示
            [SVProgressHUD showSuccessWithStatus:@"评论成功"];
        } else {
            [weakSelf gotoLoginPage];
        }
    }];
}

#pragma mark - SLBottomToolBarDelegate

- (void)toolBar:(SLBottomToolBar *)toolBar didClickLikeButton:(UIButton *)button {
    [self likeButtonTapped];
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickCommentButton:(UIButton *)button {
    [self commentButtonTapped];
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickAIButton:(UIButton *)button {
    //TODO: 实现AI功能
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickShareButton:(UIButton *)button {
    NSString *shareUrl = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, self.articleId];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = shareUrl;
    [self.view sl_showToast:@"链接已复制"];
    self.viewModel.articleEntity.share += 1;
    [self.toolbarView updateShareCount:self.viewModel.articleEntity.share];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 如果没有评论，返回1个section用于显示空白提示
    return self.viewModel.commentList.count > 0 ? self.viewModel.commentList.count + 1 : self.isLoadData ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 如果没有评论，返回1行用于显示空白提示
    if (self.viewModel.commentList.count == 0) {
        return 1;
    }
    // 如果是最后一个section（"已经到底了"提示），返回1行
    if (section == self.viewModel.commentList.count) {
        return 1;
    }
    return 1 + self.viewModel.commentList[section].expandedRepliesCount + (self.viewModel.commentList[section].hasMore ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 如果没有评论，显示空白提示Cell
    if (self.viewModel.commentList.count == 0) {
        SLEmptyCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLEmptyCommentCell"];
        __weak typeof(self) weakSelf = self;
        cell.commentButtonTapHandler = ^{
            [weakSelf commentButtonTapped];
        };
        return cell;
    }
    // 如果是最后一个section（"已经到底了"提示）
    if (indexPath.section == self.viewModel.commentList.count) {
        SLEndOfListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLEndOfListCell"];
        return cell;
    }
    SLCommentEntity *comment = self.viewModel.commentList[indexPath.section];
    if (indexPath.row == 0) {
        SLCommentCellV2 *cell = [tableView dequeueReusableCellWithIdentifier:@"SLCommentCellV2"];
        if (!cell) {
            cell = [[SLCommentCellV2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SLCommentCellV2"];
        }
        cell.section = indexPath.section;
        cell.row = indexPath.row;
        
        __weak typeof(self) weakSelf = self;
        cell.replyHandler = ^(SLCommentEntity *commentEntity, NSInteger section) {
            [weakSelf replyToComment:commentEntity index:section];
        };
        
        cell.likeHandler = ^(SLCommentEntity *commentEntity, NSInteger section, NSInteger row, BOOL selected) {
            [weakSelf likeComment:commentEntity section:section row:row selected:selected];
        };
        
        cell.dislikeHandler = ^(SLCommentEntity *commentEntity, NSInteger section, NSInteger row, BOOL selected) {
            [weakSelf dislikeComment:commentEntity section:section row:row selected:selected];
        };

        cell.linkTapHandler = ^(NSURL *url) {
            SLWebViewController *webVC = [[SLWebViewController alloc] init];
            [webVC startLoadRequestWithUrl:url.absoluteString];
            [self.navigationController pushViewController:webVC animated:YES];
        };
        cell.avatarClickHandler = ^(SLCommentEntity *commentEntity) {
            [weakSelf gotoProfilePage:commentEntity.userId];
        };
        
        [cell updateWithComment:comment authorId: self.viewModel.articleEntity.userId contentWidth:self.view.frame.size.width - 32];
        return cell;
    } else if (indexPath.row <= comment.expandedRepliesCount) { 
        // 展示二级评论
        SLSecondCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLSecondCommentCell"];
        if (!cell) {
            cell = [[SLSecondCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SLSecondCommentCell"];
        }
        cell.section = indexPath.section;
        cell.row = indexPath.row;
        // 获取对应的回复评论
        SLCommentEntity *replyComment = comment.replyList[indexPath.row - 1];
        __weak typeof(self) weakSelf = self;
        cell.replyHandler = ^(SLCommentEntity *commentEntity, NSInteger section, NSInteger row) {
            [weakSelf replyToSecondComment:commentEntity section:section row:row];
        };
        
        cell.likeHandler = ^(SLCommentEntity *commentEntity, NSInteger section, NSInteger row, BOOL selected) {
            [weakSelf likeComment:commentEntity section:indexPath.section row:indexPath.row selected:selected];
        };
        
        cell.dislikeHandler = ^(SLCommentEntity *commentEntity, NSInteger section, NSInteger row, BOOL selected) {
            [weakSelf dislikeComment:commentEntity section:section row:row selected:selected];
        };
        
        cell.linkTapHandler = ^(NSURL *url) {
            SLWebViewController *webVC = [[SLWebViewController alloc] init];
            [webVC startLoadRequestWithUrl:url.absoluteString];
            [self.navigationController pushViewController:webVC animated:YES];
        };
        cell.avatarClickHandler = ^(SLCommentEntity *commentEntity) {
            [weakSelf gotoProfilePage:commentEntity.userId];
        };
        
        [cell updateWithComment:replyComment authorId:self.viewModel.articleEntity.userId contentWidth:self.view.frame.size.width - 60];
        return cell;
    } else { 
        // 最后一个 SLShowMoreCell
        SLShowMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SLShowMoreCell"];
        if (!cell) {
            cell = [[SLShowMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SLShowMoreCell"];
        }
        cell.comment = comment;
        __weak typeof(self) weakSelf = self;
        cell.showMoreButtonTappedHandler = ^(SLCommentEntity * _Nonnull entity) {
            [weakSelf loadMoreRepliesForComment:entity atSection:indexPath.section];
        };
        return cell;
    }
}

// 添加UITableViewDelegate方法设置Cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 如果没有评论，设置空白提示Cell的高度
    if (self.viewModel.commentList.count == 0) {
        return 200; // 调整为合适的高度
    }
    // 如果是最后一个section（"已经到底了"提示）
    if (indexPath.section == self.viewModel.commentList.count) {
        return 200; // 设置"已经到底了"提示的高度
    }
    
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)loadMoreRepliesForComment:(SLCommentEntity *)comment atSection:(NSInteger)section {
    NSInteger currentCount = comment.expandedRepliesCount;
    NSInteger totalReplies = comment.replyList.count;
    NSInteger batchSize = 5;
    NSInteger newCount = MIN(currentCount + batchSize, totalReplies);

    comment.expandedRepliesCount = newCount;
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    for (NSInteger i = currentCount + 1; i <= newCount; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }

    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];

    BOOL hasMore = (newCount < totalReplies);
    comment.hasMore = hasMore;
    if (section < self.viewModel.commentList.count) {
        self.viewModel.commentList[section] = comment;
    }
    if (!hasMore) {
        NSInteger showMoreRow = newCount + 1;
        if ([self.tableView numberOfRowsInSection:section] > showMoreRow) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:showMoreRow inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (NSInteger)findSectionForCommentId:(NSString *)commentId {
    for (NSInteger i = 0; i < self.viewModel.commentList.count; i++) {
        SLCommentEntity *comment = self.viewModel.commentList[i];
        if ([comment.commentId isEqualToString:commentId]) {
            return i;
        }
    }
    return NSNotFound;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 计算滚动速度
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - self.lastScrollTime;
    
    if (timeDiff > 0) {
        CGFloat distance = scrollView.contentOffset.y - self.lastContentOffset;
        self.scrollVelocity = fabs(distance / timeDiff);
    }
    
    self.lastScrollTime = currentTime;
    
    // 获取当前内容偏移量
    CGFloat contentOffset = scrollView.contentOffset.y;
    
    // 保存上次偏移量，确保每次调用都能正确更新
    CGFloat previousOffset = self.lastContentOffset;
    self.lastContentOffset = contentOffset;
    
    // 滚动到顶部时显示导航栏和工具栏
    if (contentOffset <= 0) {
        [self updateBarsPosition:0.0 animated:NO];
        return;
    }

    // 检测是否滚动到底部
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    CGFloat bottomThreshold = 30.0; // 增加容差值，更可靠地检测底部
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - bottomThreshold);
    
    // 如果已经处于底部状态或者当前检测到底部
    if (self.isAtBottomState || isAtBottom) {
        // 确保状态标记设置为YES
        if (!self.isAtBottomState) {
            [self updateBarsPosition:0.0 animated:YES];
            self.isAtBottomState = YES;
        }
        return;
    }
    
    // 只有确定不在底部时才重置状态
    if (contentOffset < contentHeight - scrollViewHeight - bottomThreshold - 20) {
        self.isAtBottomState = NO;
    }
    
    // 根据滚动方向调整进度
    CGFloat diff = contentOffset - previousOffset;
    
    // 获取当前进度
    CGFloat currentProgress;
    if (self.isNavBarHidden) {
        currentProgress = 1.0;
    } else {
        // 通过当前约束值计算进度
        CGFloat navBarTop = self.navigationBar.frame.origin.y;
        currentProgress = MAX(0, MIN(1, navBarTop / -NAVBAR_HEIGHT));
    }
    
    CGFloat targetProgress = currentProgress;
    
    // 向下滚动（内容向上移动），增加进度（隐藏导航栏）
    if (diff > 0) {
        // 根据滚动速度调整进度增量
        CGFloat increment = MIN(0.05, self.scrollVelocity / 500.0);
        targetProgress = MIN(1.0, currentProgress + increment);
    }
    // 向上滚动（内容向下移动），减少进度（显示导航栏）
    else if (diff < 0) {
        // 根据滚动速度调整进度减量
        CGFloat decrement = MIN(0.05, self.scrollVelocity / 500.0);
        targetProgress = MAX(0.0, currentProgress - decrement);
    }
    
    // 更新导航栏和底部工具栏位置，使用平滑过渡
    [self updateBarsPosition:targetProgress animated:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 检测是否滚动到底部
    CGFloat contentOffset = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - 20);
    
    if (isAtBottom) {
        // 滚动到底部时显示导航栏和底部工具栏，但避免重复触发
        if (!self.isAtBottomState) {
            [self updateBarsPosition:0.0 animated:YES];
            self.isAtBottomState = YES;
        }
        return;
    }
    
    // 如果不会减速，则直接完成滚动
    if (!decelerate) {
        [self finishScrollingWithVelocity:self.scrollVelocity];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 检测是否滚动到底部
    CGFloat contentOffset = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    BOOL isAtBottom = (contentOffset >= contentHeight - scrollViewHeight - 20);
    
    if (isAtBottom) {
        // 滚动到底部时显示导航栏和底部工具栏，但避免重复触发
        if (!self.isAtBottomState) {
            [self updateBarsPosition:0.0 animated:YES];
            self.isAtBottomState = YES;
        }
        return;
    } else {
        // 不在底部时重置状态
        self.isAtBottomState = NO;
    }
    
    // 完成滚动，使用当前速度决定最终状态
    [self finishScrollingWithVelocity:self.scrollVelocity];
}

// 更新导航栏和工具栏位置，添加透明度渐变效果
- (void)updateBarsPosition:(CGFloat)progress animated:(BOOL)animated {
    // 计算导航栏应该移动的距离
    CGFloat navBarOffset = -NAVBAR_HEIGHT * progress;
    CGFloat tabBarOffset = self.tabBarHeight * progress;
    
    // 更新导航栏位置
    [self.navigationBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(navBarOffset);
    }];
    
    // 更新底部工具栏位置
    [self.toolbarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(tabBarOffset);
    }];
    
    // 添加导航栏透明度渐变效果
    self.navigationBar.alpha = 1.0 - progress;
    
    // 确保tableView不超过顶部安全区
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    // 调整tableView的顶部约束，确保不超过安全区
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(MAX(safeAreaInsets.top, NAVBAR_HEIGHT * (1.0 - progress)));
    }];
    
    // 更新状态
    self.isNavBarHidden = (progress >= 0.99);
    self.isToolbarHidden = (progress >= 0.99);
    
   if (animated) {
       // 使用弹性动画效果，更接近原生体验
       [UIView animateWithDuration:0.3
                             delay:0
            usingSpringWithDamping:0.8
             initialSpringVelocity:0.2
                           options:UIViewAnimationOptionAllowUserInteraction
                        animations:^{
           [self.view layoutIfNeeded];
       } completion:nil];
   } else {
       [self.view layoutIfNeeded];
   }
}

// 根据最终速度决定导航栏和底部工具栏的最终状态
- (void)finishScrollingWithVelocity:(CGFloat)velocity {
    // 获取当前进度
    CGFloat currentProgress = fabs(self.navigationBar.frame.origin.y) / NAVBAR_HEIGHT;
    
    // 快速滑动阈值
    CGFloat fastScrollThreshold = 300.0;
    
    // 根据当前进度和速度决定最终状态
    if (velocity > fastScrollThreshold) {
        // 快速向下滑动，显示导航栏和工具栏
        [self updateBarsPosition:0.0 animated:YES];
    } else if (currentProgress < 0.1) {
        [self updateBarsPosition:0.0 animated:YES];
    } else if (currentProgress > 0.9) {
        [self updateBarsPosition:1.0 animated:YES];
    } else {
        // 根据当前进度决定
        if (currentProgress > 0.5) {
            [self updateBarsPosition:1.0 animated:YES];
        } else {
            [self updateBarsPosition:0.0 animated:YES];
        }
    }
}

- (void)setupGestures {
    // 添加点击手势，点击内容区域时显示/隐藏导航栏和工具栏
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    if (self.isNavBarHidden || self.isToolbarHidden) {
        [self updateBarsPosition:0.0 animated:YES]; // 显示
    } else {
        [self updateBarsPosition:1.0 animated:YES]; // 隐藏
    }
}

#pragma mark - SLCustomNavigationBarDelegate

- (void)navigationBarBackButtonTapped {
     [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationBarMoreButtonTapped {
    UIButton *moreButton = self.navigationBar.moreButton;

    NSMutableArray *actions = [NSMutableArray array];
    
    if (self.viewModel.userEntity.isSelf) {
        // 自己发布的文章
        [actions addObject:[UIAction actionWithTitle:@"编辑" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理编辑逻辑
            [self editArticle];
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"删除" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理删除逻辑
            [self deleteArticle];
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"添加链接" image:[UIImage systemImageNamed:@"link"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理添加链接逻辑
            [self addLink];
        }]];
    } else {
        // 他人发布的文章
        [actions addObject:[UIAction actionWithTitle:@"反馈" image:[UIImage systemImageNamed:@"exclamationmark.bubble"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理反馈逻辑
            [self provideFeedback];
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"举报" image:[UIImage systemImageNamed:@"flag"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理举报逻辑
            [self reportArticle];
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"不喜欢" image:[UIImage systemImageNamed:@"hand.thumbsdown"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理不喜欢逻辑
            [self dislikeArticle];
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"添加链接" image:[UIImage systemImageNamed:@"link"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            // 处理添加链接逻辑
            [self addLink];
        }]];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
    moreButton.menu = menu;
    moreButton.showsMenuAsPrimaryAction = YES;
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    // 只有在评论列表为空时显示
    return self.viewModel.commentList.count == 0;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    // 点击"立即评论"按钮的处理
    [self commentButtonTapped];
}

#pragma mark - Helper Methods

- (void)showNavigationBarTitle:(BOOL)show {
    self.isNavBarHidden = !show;
}

- (void)showToolbar:(BOOL)show {
    self.isToolbarHidden = !show;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.toolbarView.frame;
        if (show) {
            frame.origin.y = self.view.bounds.size.height - frame.size.height;
        } else {
            frame.origin.y = self.view.bounds.size.height;
        }
        self.toolbarView.frame = frame;
    }];
}

- (void)replyToComment:(SLCommentEntity *)comment index:(NSInteger)section {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    NSString *contentPreview = @"";
    if (comment.content.length > 0) {
        NSString *content = comment.content;
        contentPreview = content.length > 10 ? [content substringToIndex:10] : content;
    }
    NSString *placeholder = [NSString stringWithFormat:@"回复@%@|%@", comment.username, contentPreview];
    self.commentVC.placeholder = placeholder;
    self.commentVC.submitHandler = ^(NSString *text) {
        [weakSelf submitReplyToComment:comment index:section content:text];
    };
    [self.commentVC showInViewController:self];
}

- (void)submitReplyToComment:(SLCommentEntity *)comment index:(NSInteger)section content:(NSString *)content {
    if (content.length == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD show];
    [self.viewModel replyToComment:self.viewModel.articleEntity.articleId commentId:comment.commentId replyUserId:comment.userId content:content resultHandler:^(SLCommentEntity * _Nullable newComment, NSError * _Nullable error) {
        [SVProgressHUD dismiss];
        weakSelf.commentVC.textView.text = @"";
        if (newComment) {
            // 更新评论数
            [weakSelf.toolbarView updateCommentCount:weakSelf.viewModel.articleEntity.commentsCnt + 1];
            weakSelf.viewModel.articleEntity.commentsCnt += 1;

            NSInteger currentCount = comment.expandedRepliesCount;
            comment.expandedRepliesCount = currentCount + 1;
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:1 inSection:section]];

            [weakSelf.tableView beginUpdates];
            [weakSelf.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationBottom];
            [weakSelf.tableView endUpdates];

            // 滚动到新添加的评论位置
            if (indexPathsToInsert.count > 0) {
                NSIndexPath *lastIndexPath = [indexPathsToInsert lastObject];
                [weakSelf.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }

            [SVProgressHUD showSuccessWithStatus:@"评论成功"];
        } else {
            [weakSelf gotoLoginPage];
        }
    }];
}

- (void)replyToSecondComment:(SLCommentEntity *)comment section:(NSInteger)section row:(NSInteger)row {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    NSString *contentPreview = @"";
    if (comment.content.length > 0) {
        NSString *content = comment.content;
        contentPreview = content.length > 10 ? [content substringToIndex:10] : content;
    }
    NSString *placeholder = [NSString stringWithFormat:@"回复@%@|%@", comment.username, contentPreview];
    self.commentVC.placeholder = placeholder;
    self.commentVC.submitHandler = ^(NSString *text) {
        [weakSelf submitReplyToSecondComment:comment section:section row:row content:text];
    };
    [self.commentVC showInViewController:self];
}

- (void)submitReplyToSecondComment:(SLCommentEntity *)comment section:(NSInteger)section row:(NSInteger)row content:(NSString *)content {
    if (content.length == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD show];
    SLCommentEntity* rootComment = self.viewModel.commentList[section];
    SLCommentEntity* secondComment = rootComment.replyList[row - 1];
    [self.viewModel replyToSecondComment:self.viewModel.articleEntity.articleId rootCommentId:rootComment.commentId commentId:secondComment.commentId replyUserId:secondComment.userId content:content resultHandler:^(SLCommentEntity * _Nullable newComment, NSError * _Nullable error) {
        [SVProgressHUD dismiss];
        weakSelf.commentVC.textView.text = @"";
        if (newComment) {
            // 更新评论数
            [weakSelf.toolbarView updateCommentCount:weakSelf.viewModel.articleEntity.commentsCnt + 1];
            weakSelf.viewModel.articleEntity.commentsCnt += 1;

            NSInteger currentCount = rootComment.expandedRepliesCount;
            rootComment.expandedRepliesCount = currentCount + 1;
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:row + 1 inSection:section]];

            [weakSelf.tableView beginUpdates];
            [weakSelf.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationBottom];
            [weakSelf.tableView endUpdates];

            // 滚动到新添加的评论位置
            if (indexPathsToInsert.count > 0) {
                NSIndexPath *lastIndexPath = [indexPathsToInsert lastObject];
                [weakSelf.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }

            [SVProgressHUD showSuccessWithStatus:@"评论成功"];
        } else {
            [weakSelf gotoLoginPage];
        }
    }];
}

#pragma mark - Comment Actions

- (void)likeComment:(SLCommentEntity *)commentEntity section:(NSInteger)section row:(NSInteger)row selected:(BOOL)selected {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
            SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
            [commentCell updateLikeStatus:commentEntity];
        } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
            SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
            [commentCell updateLikeStatus:commentEntity];
        }
        return;
    }
    if (!selected) {
        [self.viewModel cancelCommentLike:commentEntity.commentId resultHandler:^(BOOL isSuccess, BOOL needLogin, NSError *error) {
            if (isSuccess) {
                commentEntity.disliked = nil;
                commentEntity.likeCount = MAX(0, commentEntity.likeCount - 1);
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
            } else if (needLogin) {
                [self gotoLoginPage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
                return;
            }
        }];
    } else {
        [self.viewModel likeComment:commentEntity.commentId resultHandler:^(BOOL isSuccess, BOOL needLogin, NSError *error) {
            if (isSuccess) {
                if ([commentEntity.disliked isEqualToString:@"false"]) {
                    commentEntity.dislikeCount -= 1;
                }
                commentEntity.disliked = @"true";
                commentEntity.likeCount += 1;

                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
            } else if (needLogin) {
                [self gotoLoginPage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
                return;
            }
        }];
    }
}

- (void)dislikeComment:(SLCommentEntity *)commentEntity section:(NSInteger)section row:(NSInteger)row selected:(BOOL)selected {
    if (![SLUser defaultUser].isLogin) {
        [self gotoLoginPage];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
            SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
            [commentCell updateLikeStatus:commentEntity];
        } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
            SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
            [commentCell updateLikeStatus:commentEntity];
        }
        return;
    }
    
    if (!selected) {
        [self.viewModel cancelCommentLike:commentEntity.commentId resultHandler:^(BOOL isSuccess, BOOL needLogin, NSError *error) {
            if (isSuccess) {
                commentEntity.disliked = nil;
                commentEntity.dislikeCount = MAX(0, commentEntity.dislikeCount - 1);
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
            } else if (needLogin) {
                [self gotoLoginPage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
                return;
            }
        }];
    } else {
        [self.viewModel dislikeComment:commentEntity.commentId resultHandler:^(BOOL isSuccess, BOOL needLogin, NSError *error) {
            if (isSuccess) {
                if ([commentEntity.disliked isEqualToString:@"true"]) {
                    commentEntity.likeCount -= 1;
                }
                commentEntity.disliked = @"false";
                commentEntity.dislikeCount += 1;
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
            } else if (needLogin) {
                [self gotoLoginPage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([cell isKindOfClass:[SLCommentCellV2 class]] && row == 0) {
                    SLCommentCellV2 *commentCell = (SLCommentCellV2 *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                } else if ([cell isKindOfClass:[SLSecondCommentCell class]] && row > 0) {
                    SLSecondCommentCell *commentCell = (SLSecondCommentCell *)cell;
                    [commentCell updateLikeStatus:commentEntity];
                }
                return;
            }
        }];
    }
}

#pragma mark - More Menu Actions

- (void)editArticle {
    SLRecordViewController *dvc = [[SLRecordViewController alloc] init];
    dvc.articleId = self.viewModel.articleEntity.articleId;
    dvc.titleText = self.viewModel.articleEntity.title;
    dvc.url = self.viewModel.articleEntity.url;
    dvc.content = self.viewModel.articleEntity.content;
    dvc.htmlContent = self.viewModel.articleEntity.richContent;
    dvc.labels = self.viewModel.articleEntity.labels;
    dvc.isEdit = YES;
    [self.navigationController pushViewController:dvc animated:YES];
}

- (void)deleteArticle {
    [SVProgressHUD show];
    [self.viewModel deleteArticle:self.articleId resultHandler:^(BOOL isSuccess, NSError *error) {
        if (isSuccess) {
            [SVProgressHUD showSuccessWithStatus:@"删除成功"];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:@"删除失败"];
        }
    }];
}

- (void)addLink {
    // 添加链接的实现
    SLAddLinkViewController *addLinkVC = [[SLAddLinkViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    addLinkVC.submitHandler = ^(NSString *title, NSString *link) {
        // 处理添加链接的逻辑
        [weakSelf submitLink:title url:link];
    };
    [addLinkVC showInViewController:self];
}

- (void)provideFeedback {
    // 反馈的实现
    [self.view sl_showToast:@"反馈功能暂未实现"];
}

- (void)reportArticle {
    [SVProgressHUD show];
    [self.viewModel reportContent:@"article" 
                            itemId:self.articleId 
                    resultHandler:^(BOOL isSuccess, NSError *error) {
        if (isSuccess) {
            [SVProgressHUD showSuccessWithStatus:@"举报成功"];
        } else {
            [SVProgressHUD showErrorWithStatus:@"举报失败"];
        }
    }];
}

- (void)dislikeArticle {
    // 不喜欢的实现
    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    [self.viewModel reportContent:@"article"
                            itemId:self.articleId
                    resultHandler:^(BOOL isSuccess, NSError *error) {
        [SVProgressHUD dismiss];
        if (isSuccess) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)submitLink:(NSString *)title url:(NSString *)url {
    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    [self.viewModel addLink:self.articleId
                      title:title
                        url:url
              resultHandler:^(BOOL isSuccess, NSError *error) {
        if (isSuccess) {
            [weakSelf loadData];
        } else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"添加失败：%@", error.localizedDescription]];
        }
    }];
}

@end
