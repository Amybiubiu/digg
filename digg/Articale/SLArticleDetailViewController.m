//
//  SLArticleDetailViewController.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleDetailViewController.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLArticleEntity.h"
#import "SLArticleDetailViewModel.h"
#import "SLUser.h"
#import "SLColorManager.h"
#import "SLAlertManager.h"
#import <SDWebImage/SDWebImage.h>
#import "SLCommentCell.h"
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


@interface SLArticleDetailViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SLCustomNavigationBarDelegate, SLBottomToolBarDelegate>

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
@property (nonatomic, strong) SLArticleDetailViewModel *viewModel;
@property (nonatomic, strong) SLArticleTodayEntity *articleEntity;
@property (nonatomic, strong) NSArray<NSString *> *tags;
@property (nonatomic, strong) SLCommentInputViewController *commentVC;

// 滚动相关
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isNavBarHidden;
@property (nonatomic, assign) BOOL isToolbarHidden;

@end

@implementation SLArticleDetailViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupGestures];
    [self loadData];
    
    // 初始化评论输入控制器
    self.commentVC = [[SLCommentInputViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
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
    self.toolbarView = [[SLBottomToolBar alloc] init];
    self.toolbarView.delegate = self;
    [self.view addSubview:self.toolbarView];
    
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@(49.0 + kiPhoneXBottomMargin));
    }];
}

- (void)setupContentView {
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [SLColorManager primaryBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[SLCommentCell class] forCellReuseIdentifier:@"CommentCell"];
    
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
    [self.headerView addSubview:self.articleHeaderView];
    
    // 2. 内容区域 - 富文本内容
    self.articleContentView = [[SLArticleContentView alloc] init];
    self.articleContentView.heightChangedHandler = ^(CGFloat height) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.articleContentView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo([weakSelf.articleContentView getContentHeight]);
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
        make.top.equalTo(self.articleHeaderView.mas_bottom).offset(margin);
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
        SLWebViewController *webVC = [[SLWebViewController alloc] init];
        [webVC startLoadRequestWithUrl:self.viewModel.articleEntity.url];
        [self.navigationController pushViewController:webVC animated:YES];
    }
}

- (void)setupGestures {
    // 添加点击手势以隐藏键盘
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)loadData {
    if (!self.viewModel) {
        self.viewModel = [[SLArticleDetailViewModel alloc] init];
    }
    
    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    
    [self.viewModel loadArticleDetail:self.articleId resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        if (isSuccess) {
            SLArticleDetailEntity *articleEntity = weakSelf.viewModel.articleEntity;
            if (articleEntity) {
                // 更新UI
                [weakSelf updateUIWithArticleEntity:articleEntity];
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
                               publishTime:publishTimeStr];
    
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
    [self loadComments];
}

- (void)updateTableHeaderViewHeight {    
    // 修改：使用更可靠的方式计算高度
    CGFloat margin = 16.0;
    CGFloat height = margin;

    height += [self.articleHeaderView getContentHeight];
    height += margin;
    if (!self.articleContentView.isHidden) {
        height += [self.articleContentView getContentHeight];
        height += margin;
    }
    if (!self.tagListView.isHidden) {
        height += [self.tagListView getContentHeight];
        height += margin;
    }
    if (self.viewModel.referList.count > 0) {
        height += [self.relatedLinksView getContentHeight];
    }
    
    CGRect frame = self.headerView.frame;
    frame.size.height = height;
    self.headerView.frame = frame;
    
    self.tableView.tableHeaderView = self.headerView;
}

- (void)loadComments {
    if (self.viewModel.commentList.count > 0) {
        [self.tableView reloadData];
    } else {
        // TODO：这里可以添加一个空状态视图的实现
    }
}

#pragma mark - Action Methods

// 添加处理相关链接点击的方法
- (void)handleReferClick:(SLReferEntity *)refer {
    if (refer.url.length > 0) {
        SLWebViewController *webVC = [[SLWebViewController alloc] init];
        [webVC startLoadRequestWithUrl:refer.url];
        [self.navigationController pushViewController:webVC animated:YES];
    }
}

- (void)navigationBarBackButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationBarMoreButtonTapped {
    // 显示更多选项菜单
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self reportArticle];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareArticle];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)likeButtonTapped {
    if (![SLUser defaultUser].isLogin) {
        [self showLoginAlert];
        return;
    }
    
//    __weak typeof(self) weakSelf = self;
//    [self.viewModel likeArticleWithID:self.articleId isLike:!self.likeButton.selected completion:^(BOOL success, NSError *error) {
//        if (success) {
//            weakSelf.likeButton.selected = !weakSelf.likeButton.selected;
//            NSInteger likeCount = [weakSelf.likeCountLabel.text integerValue];
//            if (weakSelf.likeButton.selected) {
//                likeCount++;
//            } else {
//                likeCount = MAX(0, likeCount - 1);
//            }
//            weakSelf.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)likeCount];
//        }
//    }];
}

- (void)commentButtonTapped {
    if (![SLUser defaultUser].isLogin) {
        [self showLoginAlert];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.commentVC.placeholder = @"写评论...";
    self.commentVC.submitHandler = ^(NSString *text) {
        [weakSelf submitComment:text];
    };
    [self.commentVC showInViewController:self];
}

- (void)shareButtonTapped {
    [self shareArticle];
}

- (void)bookmarkButtonTapped {
    if (![SLUser defaultUser].isLogin) {
        [self showLoginAlert];
        return;
    }
    
//    __weak typeof(self) weakSelf = self;
//    [self.viewModel collectArticleWithID:self.articleId isCollect:!self.bookmarkButton.selected completion:^(BOOL success, NSError *error) {
//        if (success) {
//            weakSelf.bookmarkButton.selected = !weakSelf.bookmarkButton.selected;
//        }
//    }];
}

- (void)handleTagClick:(NSString *)tag {
    SLTagListContainerViewController *tagListVC = [[SLTagListContainerViewController alloc] init];
    tagListVC.label = tag;
    tagListVC.source = @"article";
    tagListVC.articleId = self.articleId;
    [self.navigationController pushViewController:tagListVC animated:YES];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    // 点击空白区域隐藏键盘
    [self.view endEditing:YES];
}

#pragma mark - Helper Methods

- (void)showLoginAlert {
//    [SLAlertManager showAlertWithTitle:@"提示" message:@"请先登录后再操作" confirmTitle:@"去登录" cancelTitle:@"取消" confirmHandler:^{
//        [self gotoLogin];
//    } cancelHandler:nil fromViewController:self];
}

- (void)gotoLogin {
//    SLWebViewController *loginVC = [[SLWebViewController alloc] init];
//    [loginVC startLoadRequestWithUrl:[NSString stringWithFormat:@"%@/login", H5BaseUrl]];
//    loginVC.isLoginPage = YES;
//    [self presentViewController:loginVC animated:YES completion:nil];
}

- (void)submitComment:(NSString *)comment {
    if (comment.length == 0) {
        return;
    }
    
//    [SVProgressHUD show];
//    __weak typeof(self) weakSelf = self;
//    
//    [self.viewModel submitCommentWithArticleID:self.articleId content:comment completion:^(BOOL success, NSError *error) {
//        [SVProgressHUD dismiss];
//        
//        if (success) {
//            // 更新评论数
//            NSInteger commentCount = [weakSelf.commentCountLabel.text integerValue] + 1;
//            weakSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)commentCount];
//            
//            // 重新加载评论
//            [weakSelf loadComments];
//        } else {
//            [SLAlertManager showAlertWithTitle:@"提示" message:@"评论发送失败，请稍后重试" confirmTitle:@"确定" cancelTitle:nil confirmHandler:nil cancelHandler:nil fromViewController:weakSelf];
//        }
//    }];
}

- (void)reportArticle {
//    [SLAlertManager showAlertWithTitle:@"举报" message:@"确定要举报该文章吗？" confirmTitle:@"确定" cancelTitle:@"取消" confirmHandler:^{
//        [SVProgressHUD showSuccessWithStatus:@"举报已提交"];
//    } cancelHandler:nil fromViewController:self];
}

- (void)shareArticle {
//    NSString *shareUrl = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, self.articleId];
//    
//    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.articleEntity.title ?: @"", shareUrl] applicationActivities:nil];
//    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - SLBottomToolBarDelegate

- (void)toolBar:(SLBottomToolBar *)toolBar didClickLikeButton:(UIButton *)button {
    [self likeButtonTapped];
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickCommentButton:(UIButton *)button {
    [self commentButtonTapped];
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickAIButton:(UIButton *)button {
    // 实现AI功能
    [self aiButtonTapped];
}

- (void)toolBar:(SLBottomToolBar *)toolBar didClickShareButton:(UIButton *)button {
    [self shareButtonTapped];
}

// 添加AI按钮点击方法
- (void)aiButtonTapped {
//    // 这里实现AI功能
//    if (![SLUser isLogin]) {
//        [SLAlertManager showLoginAlert];
//        return;
//    }
//    
//    // 实现AI分析文章内容的功能
//    [SVProgressHUD showWithStatus:@"AI正在分析文章..."];
//    // 这里添加AI分析的实际代码
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [SVProgressHUD dismiss];
//        // 显示AI分析结果
//        [SLAlertManager showAlertWithTitle:@"AI分析" message:@"这篇文章主要讨论了...(AI分析结果)" confirmTitle:@"确定" cancelTitle:nil confirmHandler:nil cancelHandler:nil];
//    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.commentList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SLCommentEntity *comment = self.viewModel.commentList[indexPath.row];
    SLCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    if (!cell) {
        cell = [[SLCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CommentCell"];
    }
    
    [cell updateWithComment:comment authorId: self.viewModel.articleEntity.userId];
    
    __weak typeof(self) weakSelf = self;
    cell.replyHandler = ^(SLCommentEntity *commentEntity) {
        [weakSelf replyToComment:commentEntity];
    };
    
    cell.likeHandler = ^(SLCommentEntity *commentEntity) {
        [weakSelf likeComment:commentEntity];
    };
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 7.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithRed:246/255.0 green:246/255.0 blue:246/255.0 alpha:1.0]; // #F6F6F6
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

#pragma mark - 评论展开方法

- (void)expandButtonTapped:(UIButton *)button {
//    NSString *commentId = objc_getAssociatedObject(button, "commentId");
//    if (!commentId) return;
//    
//    // 增加展开计数
//    NSInteger currentExpandCount = [self.viewModel isCommentExpanded:commentId] ? 1 : 0;
//    [self.viewModel setCommentExpanded:commentId expanded:(currentExpandCount + 1)];
//    
//    // 刷新对应的section
//    NSInteger section = [self findSectionForCommentId:commentId];
//    if (section != NSNotFound) {
//        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
//    }
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
//    CGFloat contentOffsetY = scrollView.contentOffset.y;
//    
//    // 导航栏显示/隐藏逻辑
//    if (contentOffsetY > 200 && !self.isNavBarHidden) {
//        [self showNavigationBarTitle:YES];
//    } else if (contentOffsetY <= 200 && self.isNavBarHidden) {
//        [self showNavigationBarTitle:NO];
//    }
//    
//    // 工具栏显示/隐藏逻辑
//    if (contentOffsetY > self.lastContentOffset + 50 && !self.isToolbarHidden) {
//        [self showToolbar:NO];
//    } else if (contentOffsetY < self.lastContentOffset - 50 && self.isToolbarHidden) {
//        [self showToolbar:YES];
//    }
//    
//    // 记录最后的滚动位置
//    if (ABS(contentOffsetY - self.lastContentOffset) > 50) {
//        self.lastContentOffset = contentOffsetY;
//    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    if (!decelerate) {
//        [self showToolbar:YES];
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    [self showToolbar:YES];
}

#pragma mark - SLCustomNavigationBarDelegate

- (void)navigationBarDidTapBackButton:(SLCustomNavigationBar *)navigationBar {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationBarDidTapMoreButton:(SLCustomNavigationBar *)navigationBar {
    [self navigationBarMoreButtonTapped];
}

#pragma mark - Helper Methods

- (void)showNavigationBarTitle:(BOOL)show {
    self.isNavBarHidden = !show;
//    [self.navigationBar setTitleVisible:show];
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

- (void)replyToComment:(SLCommentEntity *)comment {
    if (![SLUser defaultUser].isLogin) {
        [self showLoginAlert];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    NSString *placeholder = [NSString stringWithFormat:@"回复 %@", comment.username];
    self.commentVC.placeholder = placeholder;
    self.commentVC.submitHandler = ^(NSString *text) {
        [weakSelf submitReplyToComment:comment content:text];
    };
    [self.commentVC showInViewController:self];
}

- (void)submitReplyToComment:(SLCommentEntity *)comment content:(NSString *)content {
    if (content.length == 0) {
        return;
    }
    
//    __weak typeof(self) weakSelf = self;
//    [SVProgressHUD show];
//    
//    [self.viewModel submitReplyWithArticleID:self.articleId commentID:comment.commentId content:content completion:^(BOOL success, NSError *error) {
//        [SVProgressHUD dismiss];
//        
//        if (success) {
//            [weakSelf loadComments];
//        } else {
//            /*[SLAlertManager showAlertWithTitle:@"回复失败" message:@"请稍后重试" confirmTitle:@"确定" cancelTitle:nil confirmHandler:nil cancelHandler:nil fromVi*/ewController:weakSelf];
//        }
//    }];
}

- (void)likeComment:(SLCommentEntity *)comment {
    if (![SLUser defaultUser].isLogin) {
        [self showLoginAlert];
        return;
    }
    
//    __weak typeof(self) weakSelf = self;
//    [self.viewModel likeCommentWithID:comment.commentId isLike:!comment.liked completion:^(BOOL success, NSError *error) {
//        if (success) {
//            [weakSelf loadComments];
//        }
//    }];
}

- (void)submitReportWithReason:(NSString *)reason {
//    __weak typeof(self) weakSelf = self;
//    [SVProgressHUD show];
//    
//    [self.viewModel reportArticleWithID:self.articleId reason:reason completion:^(BOOL success, NSError *error) {
//        [SVProgressHUD dismiss];
//        
//        if (success) {
//            /*[SLAlertManager showAlertWithTitle:@"举报成功" message:@"感谢您的反馈，我们会尽快处理" confirmTitle:@"确定" cancelTitle:nil confirmHandler:nil cancelHandler:nil fromVi*/ewController:weakSelf];
//        } else {
//            /*[SLAlertManager showAlertWithTitle:@"举报失败" message:@"请稍后重试" confirmTitle:@"确定" cance*/lTitle:nil confirmHandler:nil cancelHandler:nil fromViewController:weakSelf];
//        }
//    }];
}

- (void)navigateToLogin {
    // 跳转到登录页面的逻辑
}

@end
