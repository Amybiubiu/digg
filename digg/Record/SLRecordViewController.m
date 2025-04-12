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
#import "SLCustomTextField.h"
#import "SLColorManager.h"
#import "digg-Swift.h"

@interface SLRecordViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *commitButton;

@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) SLHomeTagView *tagView;
@property (nonatomic, strong) UITextField *titleField; // 标题输入框
@property (nonatomic, strong) SLCustomTextField *linkField;  // 链接输入框
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
        [self.leftBackButton setHidden:NO];
        [self.textView becomeFirstResponder];
        self.titleField.text = self.titleText;
        self.linkField.text = self.url;
        [self.textView html2AttributedstringWithHtml:self.htmlContent];
        [self.textView showPlaceHolder];
        [self.tags addObjectsFromArray:self.labels];
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
        make.height.mas_equalTo(60);
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.linkField.frame.size.width > 0 && self.linkField.frame.size.height > 0) {
        self.linkField.customFrame = self.linkField.frame;
        if (self.isEdit && !self.isUpdateUrl) {
            self.isUpdateUrl = YES;
            [self.linkField textChangedHeight:self.url];
        }
    }
}

- (void)updateLinkTextFieldFrame:(CGFloat)height {
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height);
    }];
}

#pragma mark - Clear Button

// 创建清除按钮
- (UIButton *)createClearButtonForTextField:(UITextField *)textField {
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    clearButton.frame = CGRectMake(0, 0, 30, 30);
    [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
    return clearButton;
}

// 清空输入框
- (void)clearTextField:(UIButton *)sender {
    if ([self.titleField.rightView isEqual:sender]) {
        self.titleField.text = @"";
    } else if ([self.linkField.rightView isEqual:sender]) {
        self.linkField.text = @"";
    }
}

- (void)clearAll {
    self.titleField.text = @"";
    [self.linkField clear];
    self.textView.text = @"";
    [self.textView showPlaceHolder];
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
    if (self.tags.count > 0) {
        [self.tagView setHidden:NO];
        [self.tagView updateWithLabel:self.tags.firstObject];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.tagView.mas_right).offset(5);
            make.right.equalTo(self.contentView).offset(-20);
            make.height.mas_equalTo(60);
        }];
    } else {
        [self.tagView setHidden:YES];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(23);
            make.right.equalTo(self.contentView).offset(-20);
            make.height.mas_equalTo(60);
        }];
    }
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
    [self.navigationController popViewControllerAnimated:YES];
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
        [_leftBackButton addTarget:self action:@selector(clearAll) forControlEvents:UIControlEventTouchUpInside];
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

- (UITextField *)titleField {
    if (!_titleField) {
        _titleField = [[UITextField alloc] init];
        _titleField.placeholder = @"添加标题";
        _titleField.borderStyle = UITextBorderStyleNone;
        _titleField.font = [UIFont systemFontOfSize:20];
        _titleField.clearButtonMode = UITextFieldViewModeAlways;
        _titleField.rightViewMode = UITextFieldViewModeWhileEditing;
        _titleField.textColor = [SLColorManager cellTitleColor];
    }
    return _titleField;
}

- (SLCustomTextField *)linkField {
    if (!_linkField) {
        _linkField = [[SLCustomTextField alloc] initWithFrame:CGRectZero placeholder:@"链接" clear:YES leftView:NULL fontSize:16];
        __weak typeof(self) weakSelf = self;
        _linkField.updateFrame = ^(CGFloat height) {
            [weakSelf updateLinkTextFieldFrame:height];
        };
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
