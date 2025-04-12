//
//  SLRecordViewController.m
//  digg
//
//  Created by Tim Bao on 2025/1/16.
//

#import "SLRecordViewController.h"
#import "SLGeneralMacro.h"
#import "EnvConfigHeader.h"
#import "Masonry.h"
#import "SLHomeTagView.h"
#import "SLRecordViewTagInputCollectionViewCell.h"
#import "SLRecordViewTagCollectionViewCell.h"
#import "SLCustomFlowLayout.h"
#import "SLRecordViewModel.h"
#import "SVProgressHUD.h"
#import "SLWebViewController.h"
#import "SLColorManager.h"
#import "UIView+Associated.h"
#import "digg-Swift.h"

@interface SLRecordViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *commitButton;

@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) SLHomeTagView *tagView;
@property (nonatomic, strong) UITextView *titleField; // 标题输入框
@property (nonatomic, strong) UITextView *linkField;  // 链接输入框
@property (nonatomic, strong) RZRichTextView *textView;    // 多行文本输入框
@property (nonatomic, strong) UIView *line1View;
@property (nonatomic, strong) UIView *line2View;
@property (nonatomic, strong) UIView *line3View;

@property (nonatomic, strong) UICollectionView *collectionView; // 显示标签的集合视图
@property (nonatomic, strong) NSMutableArray *tags;             // 存储标签的数组
@property (nonatomic, strong) NSIndexPath *editingIndexPath;    // 正在编辑的标签的 IndexPath
@property (nonatomic, assign) BOOL isEditing;                   // 是否处于编辑状态

@property (nonatomic, strong) SLRecordViewModel *viewModel;
@property (nonatomic, assign) BOOL isUpdateUrl;

@end

@implementation SLRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self.leftBackButton setHidden:NO];
    self.tags = [NSMutableArray array];
    [self setupUI];
    
    self.isUpdateUrl = NO;
    if (self.isEdit) {
        [self.leftBackButton setTitle:@"取消" forState:UIControlStateNormal];

        self.titleField.text = self.titleText;
        UILabel *titlePlaceholder = [self.titleField viewWithTag:999];
        titlePlaceholder.hidden = self.titleText.length > 0;
        [self updateTitleFieldHeight];

        self.linkField.text = self.url;
        UILabel *linkPlaceholder = [self.linkField viewWithTag:998];
        linkPlaceholder.hidden = self.url.length > 0;
        [self updateLinkFieldHeight];

        [self.textView html2AttributedstringWithHtml:self.htmlContent];
        [self.textView showPlaceHolder];
        [self.textView becomeFirstResponder];

        [self.tags addObjectsFromArray:self.labels];
        [self showTagView];
    } else {
        [self.leftBackButton setTitle:@"清空" forState:UIControlStateNormal];
    }
    [self.collectionView reloadData];
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
        make.height.mas_equalTo(32);
    }];
    
    [self.navigationView addSubview:self.commitButton];
    [self.commitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationView).offset(-16);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.height.mas_equalTo(32);
    }];
    
    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    [self.contentView addSubview:self.tagView];
    [self.contentView addSubview:self.titleField];
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(22);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(60); // 恢复为原来的高度
    }];
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleField);
        make.left.equalTo(self.contentView).offset(23);
    }];
    [self.contentView addSubview:self.line1View];
    [self.line1View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(0.5);
    }];
    [self.contentView addSubview:self.linkField];
    [self.linkField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line1View.mas_bottom).offset(15);
        make.left.equalTo(self.contentView).offset(23);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(30);
    }];

    [self.contentView addSubview:self.line2View];
    [self.line2View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom).offset(15);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(0.5);
    }];
    [self.contentView addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line2View.mas_bottom);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(300);
    }];
    [self.contentView addSubview:self.line3View];
    [self.line3View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView.mas_bottom);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(0.5);
    }];
    [self.contentView addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line3View.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-16);
    }];
}

#pragma mark - Clear Button

// 清空输入框
- (void)clearTextField:(UIButton *)sender {
    if (sender.tag == 1001) { // 使用 tag 来标识是哪个输入框的清除按钮
        self.titleField.text = @"";
        UILabel *placeholderLabel = [self.titleField viewWithTag:999];
        placeholderLabel.hidden = NO;
        UIButton *clearButton = [self.titleField associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;
        
        [self performSelector:@selector(updateTitleFieldHeight) withObject:nil afterDelay:0.1];
    } else if (sender.tag == 1002) { // 链接输入框的清除按钮
        self.linkField.text = @"";
        UILabel *placeholderLabel = [self.linkField viewWithTag:998];
        placeholderLabel.hidden = NO;
        UIButton *clearButton = [self.linkField associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;

        [self performSelector:@selector(updateLinkFieldHeight) withObject:nil afterDelay:0.1];
    }
}

- (void)clearAll {
    [self.titleField resignFirstResponder];
    [self.linkField resignFirstResponder];
    [self.textView resignFirstResponder];
    
    self.titleField.text = @"";
    UILabel *placeholderLabel = [self.titleField viewWithTag:999];
    placeholderLabel.hidden = NO;
    UIButton *clearButton = [self.titleField associatedObjectForKey:@"clearButton"];
    clearButton.hidden = YES;
    
    // 清空链接输入框
    self.linkField.text = @"";
    UILabel *linkPlaceholder = [self.linkField viewWithTag:998];
    linkPlaceholder.hidden = NO;
    UIButton *clearButton2 = [self.linkField associatedObjectForKey:@"clearButton"];
    clearButton2.hidden = YES;

    [self.textView clearContent];

    [self.tags removeAllObjects];
    [self.collectionView reloadData];
    
    [self.tagView setHidden:YES];
    [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(23);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(60);
    }];
}

- (void)showTagView {
    // 获取当前 titleField 的高度
    CGFloat currentHeight = self.titleField.frame.size.height;
    // 确保最小高度为 60
    CGFloat titleHeight = MAX(60, currentHeight);
    
    if (self.tags.count > 0) {
        [self.tagView setHidden:NO];
        [self.tagView updateWithLabel:self.tags.firstObject];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.tagView.mas_right).offset(5);
            make.right.equalTo(self.contentView).offset(-20);
            make.height.mas_equalTo(titleHeight); // 使用计算后的高度
        }];
    } else {
        [self.tagView setHidden:YES];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(23);
            make.right.equalTo(self.contentView).offset(-20);
            make.height.mas_equalTo(titleHeight); // 使用计算后的高度
        }];
    }
    [self performSelector:@selector(updateTitleFieldHeight) withObject:nil afterDelay:0.1];
}

- (void)updateTitleFieldHeight {
    CGFloat fixedWidth = self.titleField.frame.size.width > 0 ? self.titleField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    CGSize newSize = [self.titleField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGFloat newHeight = MAX(60, newSize.height); // 最小高度为60
    
    [self.titleField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(newHeight);
    }];
    
    // 更新清除按钮位置
    UIButton *clearButton = [self.titleField associatedObjectForKey:@"clearButton"];
    if (clearButton) {
        CGRect frame = clearButton.frame;
        // 修改为与父视图右边缘的固定距离，与下方按钮对齐
        frame.origin.x = self.titleField.bounds.size.width - frame.size.width - 5;
        frame.origin.y = (self.titleField.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
    }
    
    // 确保 line1View 与 titleField 底部保持适当距离
    [self.line1View mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom);
    }];
}

- (void)updateLinkFieldHeight {
    CGFloat fixedWidth = self.linkField.frame.size.width > 0 ? self.linkField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    CGSize newSize = [self.linkField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGFloat newHeight = MAX(30, newSize.height); // 最小高度为30
    
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(newHeight);
    }];
    
    // 更新清除按钮位置
    UIButton *clearButton = [self.linkField associatedObjectForKey:@"clearButton"];
    if (clearButton) {
        CGRect frame = clearButton.frame;
        frame.origin.x = self.linkField.bounds.size.width - frame.size.width;
        frame.origin.y = (self.linkField.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
    }
    
    // 确保 line2View 与 linkField 底部保持适当距离
    [self.line2View mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom).offset(15);
    }];
}

- (void)gotoH5Page:(NSString *)articleId {
    NSString *url = [NSString stringWithFormat:@"%@/post/%@", H5BaseUrl, articleId];
    SLWebViewController *vc = [[SLWebViewController alloc] init];
    vc.isShowProgress = NO;
    [vc startLoadRequestWithUrl:url];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions
- (void)backPage {
    if (self.isEdit) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self clearAll];
    }
}

- (void)commitBtnClick {
    NSString* title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (title.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请添加标题"];
        return;
    }
    NSString* url = [self.linkField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [SVProgressHUD show];
    @weakobj(self)
    if (self.isEdit) {
        [self.viewModel updateRecord:title link:url content:self.textView.text htmlContent:self.textView.code2html labels:self.tags articleId:self.articleId resultHandler:^(BOOL isSuccess, NSString * _Nonnull articleId) {
            @strongobj(self)
            [SVProgressHUD dismiss];
            if (isSuccess) {
                [self gotoH5Page:articleId];
                [self clearAll];
            }
        }];
    } else {
        [self.viewModel subimtRecord:title link:url content:self.textView.text htmlContent:self.textView.code2html labels:self.tags resultHandler:^(BOOL isSuccess, NSString * articleId) {
            @strongobj(self)
            [SVProgressHUD dismiss];
            if (isSuccess) {
                [self gotoH5Page:articleId];
                [self clearAll];
            }
        }];
    }
}

- (void)setupTitlePlaceholder {
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"添加标题";
    placeholderLabel.font = [UIFont systemFontOfSize:20];
    placeholderLabel.textColor = [UIColor lightGrayColor];
    placeholderLabel.numberOfLines = 0;
    [placeholderLabel sizeToFit];
    
    // 设置标签位置
    placeholderLabel.frame = CGRectMake(5, 15, placeholderLabel.frame.size.width, placeholderLabel.frame.size.height);
    placeholderLabel.tag = 999;
    
    [self.titleField addSubview:placeholderLabel];
}

- (void)setupLinkPlaceholder {
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"链接";
    placeholderLabel.font = [UIFont systemFontOfSize:16];
    placeholderLabel.textColor = [UIColor lightGrayColor];
    placeholderLabel.numberOfLines = 0;
    [placeholderLabel sizeToFit];
    
    // 设置标签位置
    placeholderLabel.frame = CGRectMake(5, 8, placeholderLabel.frame.size.width, placeholderLabel.frame.size.height);
    placeholderLabel.tag = 998;
    
    [self.linkField addSubview:placeholderLabel];
}

// 实现 UITextViewDelegate 方法来处理占位文本的显示和隐藏
- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.titleField) {
        UILabel *placeholderLabel = [textView viewWithTag:999];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 更新清除按钮状态 - 只有当文本不为空时才显示
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = textView.text.length == 0;
        
        // 更新清除按钮位置 - 与下方清除按钮右侧对齐
        CGRect frame = clearButton.frame;
        // 修改为与父视图右边缘的固定距离，与下方按钮对齐
        frame.origin.x = textView.bounds.size.width - frame.size.width;
        frame.origin.y = (textView.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
        
        // 根据内容自动调整高度
        CGFloat fixedWidth = textView.frame.size.width;
        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGFloat newHeight = MAX(60, newSize.height); // 最小高度为60
        
        [textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(newHeight);
        }];
        
        // 确保 line1View 与 titleField 底部保持适当距离
        [self.line1View mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleField.mas_bottom);
        }];
    } else if (textView == self.linkField) {
        UILabel *placeholderLabel = [textView viewWithTag:998];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 更新清除按钮状态 - 只有当文本不为空时才显示
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = textView.text.length == 0;
        
        // 更新清除按钮位置
        CGRect frame = clearButton.frame;
        frame.origin.x = textView.bounds.size.width - frame.size.width;
        frame.origin.y = (textView.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
        
        // 根据内容自动调整高度
        CGFloat fixedWidth = textView.frame.size.width;
        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGFloat newHeight = MAX(30, newSize.height); // 最小高度为30
        
        [textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(newHeight);
        }];
        
        // 确保 line2View 与 linkField 底部保持适当距离
        [self.line2View mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.linkField.mas_bottom).offset(15);
        }];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView == self.titleField) {
        UILabel *placeholderLabel = [textView viewWithTag:999];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 显示清除按钮 - 只有当文本不为空时才显示
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = textView.text.length == 0;
        
        // 更新清除按钮位置 - 与下方清除按钮右侧对齐
        CGRect frame = clearButton.frame;
        // 修改为与父视图右边缘的固定距离，与下方按钮对齐
        frame.origin.x = textView.bounds.size.width - frame.size.width;
        frame.origin.y = (textView.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
    } else if (textView == self.linkField) {
        UILabel *placeholderLabel = [textView viewWithTag:998];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 显示清除按钮 - 只有当文本不为空时才显示
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = textView.text.length == 0;
        
        // 更新清除按钮位置
        CGRect frame = clearButton.frame;
        frame.origin.x = textView.bounds.size.width - frame.size.width;
        frame.origin.y = (textView.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.titleField) {
        UILabel *placeholderLabel = [textView viewWithTag:999];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 隐藏清除按钮
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;
    } else if (textView == self.linkField) {
        UILabel *placeholderLabel = [textView viewWithTag:998];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 隐藏清除按钮
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;
    }
}

#pragma mark - UICollectionView DataSource & Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tags.count + 1; // +1 用于显示“添加标签”入口
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.tags.count) {
        SLRecordViewTagInputCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SLRecordViewTagInputCollectionViewCell" forIndexPath:indexPath];
        [cell configDataWithIndex:indexPath.item];
        [cell startInput:self.isEditing];
        cell.inputField.enabled = YES;
        cell.inputField.delegate = self;
        [cell.inputField addTarget:self action:@selector(startEditing:) forControlEvents:UIControlEventEditingDidBegin];
        return cell;
    } else {
        SLRecordViewTagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SLRecordViewTagCollectionViewCell" forIndexPath:indexPath];
        NSString* name = self.tags[indexPath.item];
        [cell configDataWithTagName:name index:indexPath.item];
        @weakobj(self)
        cell.removeTag = ^(NSString * _Nonnull tagName, NSInteger index) {
            @strongobj(self)
            [self.tags removeObjectAtIndex:index];
            [self showTagView];
            [self.collectionView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        };
        return cell;
    }
}

#pragma mark - Action

 - (void)startEditing:(UITextField *)sender {
     if (self.isEditing) {
         return; // 如果已经在编辑模式，返回
     }
    
     self.isEditing = YES;
     self.editingIndexPath = [NSIndexPath indexPathForItem:self.tags.count inSection:0];
    
     // 让输入框成为第一响应者
     SLRecordViewTagInputCollectionViewCell *cell = (SLRecordViewTagInputCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.editingIndexPath];
     [cell startInput:YES];
     [cell.inputField becomeFirstResponder];
 }

#pragma mark - UITextField Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self finishInputTag:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self finishInputTag:textField];
    return YES;
}

- (void)finishInputTag:(UITextField *)textField {
    [textField resignFirstResponder];
    self.isEditing = NO;
    
    if (textField.text.length > 0) {
        // 新标签插入到第一个位置
        NSString* text = textField.text;
        if (text.length > 30) {
            [SVProgressHUD showErrorWithStatus:@"标签字数不能超过30字符"];
            text = [text substringWithRange:NSMakeRange(0, 30)];
        }
        [self.tags addObject:text];
    }
    textField.text = @"";
    [self.collectionView reloadData]; // 刷新数据
    [self showTagView];
}

#pragma mark - UI Elements
- (UIView *)navigationView {
    if (!_navigationView) {
        _navigationView = [UIView new];
        _navigationView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _navigationView;
}

- (UIButton *)leftBackButton {
    if (!_leftBackButton) {
        _leftBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBackButton setTitle:@"取消" forState:UIControlStateNormal];
        [_leftBackButton setTitleColor:[SLColorManager cellTitleColor] forState:UIControlStateNormal];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UIButton *)commitButton {
    if (!_commitButton) {
        _commitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_commitButton setTitle:@"提交" forState:UIControlStateNormal];
        [_commitButton setTitleColor:[SLColorManager cellTitleColor] forState:UIControlStateNormal];
        [_commitButton addTarget:self action:@selector(commitBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commitButton;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _contentView;
}

- (SLHomeTagView *)tagView {
    if (!_tagView) {
        _tagView = [[SLHomeTagView alloc] init];
        [_tagView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisHorizontal];
        [_tagView setHidden:YES];
    }
    return _tagView;
}

- (UITextView *)titleField {
    if (!_titleField) {
        _titleField = [[UITextView alloc] init];
        _titleField.font = [UIFont systemFontOfSize:20];
        _titleField.textColor = [SLColorManager cellTitleColor];
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.delegate = self;
        _titleField.scrollEnabled = YES;
        _titleField.returnKeyType = UIReturnKeyDefault; // 允许换行
        _titleField.textContainerInset = UIEdgeInsetsMake(15, 0, 15, 30); // 右侧增加30的内边距，为清除按钮留出空间
        
        // 添加占位文本
        [self setupTitlePlaceholder];

        // 添加清除按钮
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 修改清除按钮的颜色，与下方清除按钮一致
        [clearButton setImage:[[UIImage systemImageNamed:@"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [clearButton setTintColor:[UIColor lightGrayColor]]; // 设置为浅灰色，与下方按钮一致
        clearButton.frame = CGRectMake(0, 0, 30, 30);
        clearButton.tag = 1001; // 设置标签以便识别
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        clearButton.hidden = YES; // 初始状态隐藏
        [_titleField addSubview:clearButton];
        
        // 保存清除按钮的引用，以便后续访问
        [_titleField setAssociatedObject:clearButton forKey:@"clearButton"];
    }
    return _titleField;
}

- (UITextView *)linkField {
    if (!_linkField) {
        _linkField = [[UITextView alloc] init];
        _linkField.font = [UIFont systemFontOfSize:16];
        _linkField.textColor = [SLColorManager lineTextColor];
        _linkField.backgroundColor = [UIColor clearColor];
        _linkField.delegate = self;
        _linkField.scrollEnabled = YES;
        _linkField.returnKeyType = UIReturnKeyDefault; // 允许换行
        _linkField.textContainerInset = UIEdgeInsetsMake(8, 0, 8, 30); // 右侧增加30的内边距，为清除按钮留出空间
        
        // 添加占位文本
        [self setupLinkPlaceholder];

        // 添加清除按钮
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 修改清除按钮的颜色
        [clearButton setImage:[[UIImage systemImageNamed:@"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [clearButton setTintColor:[UIColor lightGrayColor]]; // 设置为浅灰色
        clearButton.frame = CGRectMake(0, 0, 30, 30);
        clearButton.tag = 1002; // 设置标签以便识别
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        clearButton.hidden = YES; // 初始状态隐藏
        [_linkField addSubview:clearButton];
        
        // 保存清除按钮的引用，以便后续访问
        [_linkField setAssociatedObject:clearButton forKey:@"clearButton"];
        
        // 设置内容优先级，确保不会挤压其他视图
        [_linkField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_linkField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    }
    return _linkField;
}

- (RZRichTextView *)textView {
    if (!_textView) {
        _textView = [[RZRichTextView alloc] initWithFrame:CGRectZero viewModel:[RZRichTextViewModel sharedWithEdit:YES]];
        _textView.font = [UIFont systemFontOfSize:16];
        _textView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _textView.textColor = [SLColorManager cellTitleColor];
    }
    return _textView;
}

- (UIView *)line1View {
    if (!_line1View) {
        _line1View = [[UIView alloc] init];
        _line1View.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _line1View;
}

- (UIView *)line2View {
    if (!_line2View) {
        _line2View = [[UIView alloc] init];
        _line2View.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _line2View;
}

- (UIView *)line3View {
    if (!_line3View) {
        _line3View = [[UIView alloc] init];
        _line3View.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _line3View;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        SLCustomFlowLayout *layout = [[SLCustomFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 10;
        layout.estimatedItemSize = CGSizeMake(100, 25);
        layout.sectionInset = UIEdgeInsetsZero;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        
        [_collectionView registerClass:[SLRecordViewTagInputCollectionViewCell class] forCellWithReuseIdentifier:@"SLRecordViewTagInputCollectionViewCell"];
        [_collectionView registerClass:[SLRecordViewTagCollectionViewCell class] forCellWithReuseIdentifier:@"SLRecordViewTagCollectionViewCell"];
    }
    return _collectionView;
}

- (SLRecordViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [SLRecordViewModel new];
    }
    return _viewModel;
}

@end
