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
#import "SLRecordViewModel.h"
#import "SVProgressHUD.h"
#import "SLWebViewController.h"
#import "SLColorManager.h"
#import "UIView+Associated.h"
#import "digg-Swift.h"
#import "SLArticleDetailViewControllerV2.h"
#import "SLZoomTransitionDelegate.h"

#define FIELD_DEFAULT_HEIGHT 60
#define TAG_DEFAULT_HEIGHT 24

@interface SLRecordViewController () <UITextFieldDelegate, UITextViewDelegate, RZRichTextViewDelegate>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *commitButton;

@property (nonatomic, strong) UIScrollView* contentView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SLHomeTagView *tagView;
@property (nonatomic, strong) UITextView *titleField; // 标题输入框
@property (nonatomic, strong) UITextView *linkField;  // 链接输入框
@property (nonatomic, strong) RZRichTextView *textView;    // 多行文本输入框
@property (nonatomic, strong) UIView *line1View;
@property (nonatomic, strong) UIView *line2View;
@property (nonatomic, strong) UIView *line3View;

@property (nonatomic, strong) NSMutableArray *tags;             // 存储标签的数组
@property (nonatomic, strong) NSIndexPath *editingIndexPath;    // 正在编辑的标签的 IndexPath
@property (nonatomic, assign) BOOL isEditing;                   // 是否处于编辑状态

@property (nonatomic, strong) UIView *tagContainerView;
@property (nonatomic, strong) UITextField *tagInputField;
@property (nonatomic, strong) UIButton *addTagButton;

@property (nonatomic, strong) SLRecordViewModel *viewModel;
@property (nonatomic, assign) BOOL isUpdateUrl;

@property (nonatomic, assign) CGFloat textViewContentHeight; // 记录文本视图高度

@property (nonatomic, strong) UILabel *titleCountLabel; // 标题字数提示标签
@property (nonatomic, strong) UILabel *linkWarningLabel; // 链接警告标签

@end

@implementation SLRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self.leftBackButton setHidden:NO];
    self.tags = [NSMutableArray array];
     self.textViewContentHeight = 300;
    [self setupUI];
    
    self.isUpdateUrl = NO;
    self.tagInputField.hidden = YES;
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
    [self refreshTagsDisplay];
    [self updateTagsLayout];
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
        make.left.equalTo(self.navigationView).offset(17);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.height.mas_equalTo(32);
    }];
    
    [self.navigationView addSubview:self.commitButton];
    [self.commitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationView).offset(-17);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.height.mas_equalTo(32);
    }];
    
    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    [self.contentView addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
    }];
    
    [self.containerView addSubview:self.tagView];
    [self.containerView addSubview:self.titleField];
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleField);
        make.left.equalTo(self.containerView).offset(13);
    }];
    [self.containerView addSubview:self.line1View];
    [self.line1View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom);
        make.left.equalTo(self.containerView).offset(10);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(1.0/[UIScreen mainScreen].scale);
    }];
    [self.containerView addSubview:self.linkField];
    [self.linkField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line1View.mas_bottom);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];

    [self.containerView addSubview:self.line2View];
    [self.line2View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom);
        make.left.equalTo(self.containerView).offset(10);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(1.0/[UIScreen mainScreen].scale);
    }];
    [self.containerView addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line2View.mas_bottom).offset(10);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-12);
        make.height.mas_equalTo(300);
    }];
    [self.containerView addSubview:self.line3View];
    [self.line3View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView.mas_bottom);
        make.left.equalTo(self.containerView).offset(10);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(1.0/[UIScreen mainScreen].scale);
    }];
    [self.containerView addSubview:self.tagContainerView];
    [self.tagContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line3View.mas_bottom).offset(16);
        make.left.equalTo(self.containerView).offset(17);
        make.right.equalTo(self.containerView).offset(-16);
    }];
    // 添加"+ 标签"按钮
    [self.tagContainerView addSubview:self.addTagButton];
    [self.addTagButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagContainerView);
        make.centerY.equalTo(self.tagContainerView);
        make.height.mas_equalTo(TAG_DEFAULT_HEIGHT);
        make.width.mas_equalTo(100);
    }];
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.tagContainerView.mas_bottom).offset(16);
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
        self.titleCountLabel.hidden = YES;
        
        [self performSelector:@selector(updateTitleFieldHeight) withObject:nil afterDelay:0.1];
    } else if (sender.tag == 1002) { // 链接输入框的清除按钮
        self.linkField.text = @"";
        UILabel *placeholderLabel = [self.linkField viewWithTag:998];
        placeholderLabel.hidden = NO;
        UIButton *clearButton = [self.linkField associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;
        self.linkWarningLabel.hidden = YES;
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
    self.titleCountLabel.hidden = YES;
    
    // 清空链接输入框
    self.linkField.text = @"";
    UILabel *linkPlaceholder = [self.linkField viewWithTag:998];
    linkPlaceholder.hidden = NO;
    UIButton *clearButton2 = [self.linkField associatedObjectForKey:@"clearButton"];
    clearButton2.hidden = YES;
    self.linkWarningLabel.hidden = YES;
    [self updateLinkFieldHeight];

    [self.textView clearContent];
    [self updateTextViewHeight];

    [self.tags removeAllObjects];
    [self refreshTagsDisplay];
    [self updateTagsLayout];
    
    [self.tagView setHidden:YES];
    [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(12);
        make.right.equalTo(self.contentView).offset(-10);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];
}

- (void)showTagView {
    CGFloat currentHeight = self.titleField.frame.size.height;
    CGFloat titleHeight = MAX(FIELD_DEFAULT_HEIGHT, currentHeight);
    
    if (self.tags.count > 0) {
        [self.tagView setHidden:NO];
        [self.tagView updateWithLabel:self.tags.firstObject];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.tagView.mas_right).offset(5);
            make.right.equalTo(self.contentView).offset(-10);
            make.height.mas_equalTo(titleHeight);
        }];
    } else {
        [self.tagView setHidden:YES];
        [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(12);
            make.right.equalTo(self.contentView).offset(-10);
            make.height.mas_equalTo(titleHeight);
        }];
    }
    [self performSelector:@selector(updateTitleFieldHeight) withObject:nil afterDelay:0.1];
}

- (void)updateTitleFieldHeight {
    CGFloat fixedWidth = self.titleField.frame.size.width > 0 ? self.titleField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    CGSize newSize = [self.titleField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGFloat newHeight = MAX(FIELD_DEFAULT_HEIGHT, newSize.height);
    
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
}

- (void)updateLinkFieldHeight {
    CGFloat fixedWidth = self.linkField.frame.size.width > 0 ? self.linkField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    CGSize contentSize = [self.linkField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    // CGFloat newHeight = MAX(FIELD_DEFAULT_HEIGHT, newSize.height);
    // 如果警告标签可见，增加额外高度
    CGFloat extraHeight = self.linkWarningLabel.hidden ? 0 : 25; // 警告标签高度+间距
    CGFloat newHeight = contentSize.height + extraHeight;
    
    // 更新linkField高度
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(newHeight);
    }];
    
    // 更新line2的位置
    [self.line2View mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom);
    }];
    
    // 更新textView的位置
    [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line2View.mas_bottom);
    }];
    
    // 更新清除按钮位置
    UIButton *clearButton = [self.linkField associatedObjectForKey:@"clearButton"];
    if (clearButton) {
        CGRect frame = clearButton.frame;
        frame.origin.x = self.linkField.bounds.size.width - frame.size.width - 5;
        frame.origin.y = (self.linkField.bounds.size.height - frame.size.height) / 2;
        clearButton.frame = frame;
    }

    // 强制布局更新
    [self.view layoutIfNeeded];
}

- (void)gotoH5Page:(NSString *)articleId {
    SLArticleDetailViewControllerV2* vc = [SLArticleDetailViewControllerV2 new];
    vc.articleId = articleId;
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
                [self backPage];
//                [self gotoH5Page:articleId];
//                [self clearAll];
            } else {
                [SVProgressHUD showErrorWithStatus:@"提交失败"];
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
    placeholderLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    placeholderLabel.textColor = [UIColor placeholderTextColor];
    placeholderLabel.numberOfLines = 0;
    [placeholderLabel sizeToFit];
    
    // 设置标签位置
    placeholderLabel.frame = CGRectMake(3, (FIELD_DEFAULT_HEIGHT - placeholderLabel.frame.size.height)/2.0, placeholderLabel.frame.size.width, placeholderLabel.frame.size.height);
    placeholderLabel.tag = 999;
    
    [self.titleField addSubview:placeholderLabel];
}

- (void)setupLinkPlaceholder {
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"链接";
    placeholderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    placeholderLabel.textColor = [UIColor placeholderTextColor];
    placeholderLabel.numberOfLines = 0;
    [placeholderLabel sizeToFit];
    
    // 设置标签位置
    placeholderLabel.frame = CGRectMake(3, (FIELD_DEFAULT_HEIGHT - placeholderLabel.frame.size.height)/2.0, placeholderLabel.frame.size.width, placeholderLabel.frame.size.height);
    placeholderLabel.tag = 998;
    
    [self.linkField addSubview:placeholderLabel];
}

- (void)addTagFromInput {
    NSString *tagText = [self.tagInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (tagText.length > 0) {
        [self.tags addObject:tagText];
        [self showTagView]; // 更新顶部标签显示
        [self refreshTagsDisplay]; // 刷新标签显示
    }
    
    // 重置输入框
    self.tagInputField.text = @"";
    [self.tagInputField removeFromSuperview];
    self.tagInputField.hidden = YES;
    
    // 显示添加按钮
    self.addTagButton.hidden = NO;
    [self.tagInputField resignFirstResponder];
    // 更新布局
    [self updateTagsLayout];
}

// 刷新标签显示
- (void)refreshTagsDisplay {
    // 清除现有标签视图
    for (UIView *view in self.tagContainerView.subviews) {
        if (![view isEqual:self.addTagButton] && ![view isEqual:self.tagInputField]) {
            [view removeFromSuperview];
        }
    }
    
    // 重新布局所有标签
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    CGFloat tagHeight = TAG_DEFAULT_HEIGHT;
    CGFloat tagSpacing = 10;
    CGFloat lineSpacing = 10;
    CGFloat tagInsetSpacing = 7;
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - 43; // 屏幕宽度减去左右边距(27+16)
    
    // 根据标签数量更新按钮文案
    NSString *buttonTitle;
    if (self.tags.count == 0) {
        buttonTitle = @"+ 标签";
    } else if (self.tags.count == 1) {
        buttonTitle = @"+ 二级标签";
    } else if (self.tags.count == 2) {
        buttonTitle = @"+ 三级标签";
    } else if (self.tags.count == 3) {
        buttonTitle = @"+ 四级标签";
    } else if (self.tags.count == 4) {
        buttonTitle = @"+ 五级标签";
    } else if (self.tags.count == 5) {
        buttonTitle = @"+ 六级标签";
    } else if (self.tags.count == 6) {
        buttonTitle = @"+ 七级标签";
    } else if (self.tags.count == 7) {
        buttonTitle = @"+ 八级标签";
    } else if (self.tags.count == 8) {
        buttonTitle = @"+ 九级标签";
    } else if (self.tags.count == 9) {
        buttonTitle = @"+ 十级标签";
    } else {
        buttonTitle = [NSString stringWithFormat:@"+ %ld级标签", self.tags.count + 1];
    }
    [self.addTagButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    // 计算按钮宽度 - 文本宽度 + 左右各10像素的间距
    UIFont *buttonFont = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    CGSize buttonTextSize = [buttonTitle sizeWithAttributes:@{NSFontAttributeName: buttonFont}];
    CGFloat buttonWidth = buttonTextSize.width + (tagInsetSpacing * 2); // 左右各tagInsetSpacing像素的间距;
    
    // 更新虚线边框
    for (CALayer *layer in self.addTagButton.layer.sublayers) {
        if ([layer.name isEqualToString:@"dashedBorder"]) {
            CAShapeLayer *borderLayer = (CAShapeLayer *)layer;
            CGRect borderRect = CGRectMake(0, 0, buttonWidth, TAG_DEFAULT_HEIGHT);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:TAG_DEFAULT_HEIGHT/2];
            borderLayer.path = path.CGPath;
            break;
        }
    }

    for (NSInteger i = 0; i < self.tags.count; i++) {
        NSString *tagName = self.tags[i];
        
        // 计算标签宽度
        UIFont *font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        CGSize textSize = [tagName sizeWithAttributes:@{NSFontAttributeName: font}];
        
        // 删除按钮宽度和间距
        CGFloat deleteButtonWidth = 10; // 删除按钮宽度
        CGFloat deleteButtonSpacing = 3; // 删除按钮距离文本的间距
        
        // 计算标签总宽度：左侧间距 + 文本宽度 + 删除按钮间距 + 删除按钮宽度 + 右侧间距
        CGFloat tagWidth = tagInsetSpacing + textSize.width + deleteButtonSpacing + deleteButtonWidth + tagInsetSpacing;
        
        // 检查是否需要换行
        BOOL needNewLine = NO;
        
        // 如果标签宽度超过最大宽度的80%，或者剩余空间不足，则换行
        if (tagWidth > maxWidth * 0.8 || (xOffset > 0 && xOffset + tagWidth > maxWidth)) {
            xOffset = 0;
            yOffset += tagHeight + lineSpacing;
            needNewLine = YES;
        }
        
        // 计算实际标签宽度，确保不超过最大宽度
        CGFloat actualTagWidth = MIN(tagWidth, maxWidth);
        
        // 创建标签视图
        UIView *tagView = [[UIView alloc] init];
        tagView.backgroundColor = [SLColorManager recorderTagBgColor];
        tagView.layer.cornerRadius = TAG_DEFAULT_HEIGHT/2;
        tagView.layer.borderColor = [SLColorManager recorderTagBorderColor].CGColor;
        tagView.layer.borderWidth = 1;
        
        // 创建标签文本
        UILabel *tagLabel = [[UILabel alloc] init];
        tagLabel.text = tagName;
        tagLabel.font = font;
        tagLabel.textColor = [SLColorManager recorderTagTextColor];
        
        // 只有当一行只有这一个标签且长度超过最大宽度时才使用省略号
        if (xOffset == 0 && actualTagWidth >= maxWidth) {
            tagLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        } else {
            // 否则允许多行显示
            tagLabel.lineBreakMode = NSLineBreakByWordWrapping;
            tagLabel.numberOfLines = 0;
        }
        
        // 创建删除按钮
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setImage:[[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [deleteButton setTintColor:[SLColorManager recorderTagTextColor]];
        deleteButton.tag = i; // 使用tag存储索引
        [deleteButton addTarget:self action:@selector(deleteTag:) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加到标签视图
        [tagView addSubview:tagLabel];
        [tagView addSubview:deleteButton];
        
        // 设置标签视图位置
        tagView.frame = CGRectMake(xOffset, yOffset, actualTagWidth, tagHeight);
        
        // 计算标签文本最大宽度，确保删除按钮可见
        CGFloat maxLabelWidth = actualTagWidth - tagInsetSpacing - deleteButtonWidth - deleteButtonSpacing - tagInsetSpacing;
        
        // 设置标签文本和删除按钮位置 - 确保垂直居中
        tagLabel.frame = CGRectMake(tagInsetSpacing, (tagHeight - textSize.height) / 2, maxLabelWidth, textSize.height);
        deleteButton.frame = CGRectMake(actualTagWidth - deleteButtonWidth - tagInsetSpacing, (tagHeight - deleteButtonWidth) / 2, deleteButtonWidth, deleteButtonWidth);
        
        [self.tagContainerView addSubview:tagView];
        
        // 更新下一个标签的位置
        xOffset += actualTagWidth + tagSpacing;
    }
    
    // 检查是否需要为添加按钮换行
    if (xOffset + buttonWidth > maxWidth) { // 使用计算后的按钮宽度
        xOffset = 0;
        yOffset += tagHeight + lineSpacing;
    }
    
    // 更新添加按钮位置和宽度
    [self.addTagButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagContainerView).offset(xOffset);
        make.top.equalTo(self.tagContainerView).offset(yOffset);
        make.height.mas_equalTo(TAG_DEFAULT_HEIGHT);
        make.width.mas_equalTo(buttonWidth); // 使用计算后的宽度
    }];
    
    // 更新容器高度和宽度
    CGFloat containerHeight = yOffset + tagHeight;
    [self.tagContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(maxWidth);
        make.height.mas_equalTo(containerHeight);
    }];
}

// 删除标签
- (void)deleteTag:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.tags.count) {
        [self.tags removeObjectAtIndex:index];
        [self showTagView]; // 更新顶部标签显示
        [self refreshTagsDisplay]; // 刷新标签显示
    }
}

// 更新标签布局
- (void)updateTagsLayout {
    [self.tagContainerView layoutIfNeeded];
}

#pragma mark - UITextViewDelegate
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

        // 限制标题最大字符数为50
        NSInteger maxLength = 50;
        if (textView.text.length > maxLength) {
            textView.text = [textView.text substringToIndex:maxLength];
        }
        // 更新字数提示标签
        NSInteger textLength = textView.text.length;
        self.titleCountLabel.text = [NSString stringWithFormat:@"%ld/%ld", textLength, maxLength];
        
        // 当字数接近或达到最大值时显示标签
        self.titleCountLabel.hidden = (textLength < maxLength * 0.8);
        
        // 更新标签位置 - 放在右下角，不会被文字遮挡
        CGRect labelFrame = self.titleCountLabel.frame;
        labelFrame.origin.x = textView.bounds.size.width - labelFrame.size.width - 10;
        labelFrame.origin.y = textView.bounds.size.height - labelFrame.size.height - 10;
        self.titleCountLabel.frame = labelFrame;
        
        // 根据内容自动调整高度
        CGFloat fixedWidth = textView.frame.size.width;
        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGFloat newHeight = MAX(FIELD_DEFAULT_HEIGHT, newSize.height); // 最小高度为60
        
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

        // 验证链接
        NSString *linkText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL isValidLink = [self isValidURL:linkText];
        
        // 只有当链接不为空且无效时才显示警告
        self.linkWarningLabel.hidden = (linkText.length == 0 || isValidLink);

        // 如果显示警告，确保警告标签位置正确
        if (!self.linkWarningLabel.hidden) {
            // 计算文本的位置和大小
            CGRect textRect = [textView.layoutManager usedRectForTextContainer:textView.textContainer];
            CGFloat textHeight = textRect.size.height;
            
            // 警告标签位置 - 放在文本下方
            CGFloat xPos = textView.textContainerInset.left;
            CGFloat yPos = textView.textContainerInset.top + textHeight + 5; // 文本下方5个点的位置
            
            self.linkWarningLabel.frame = CGRectMake(xPos, yPos, 100, 15);
        }
        // 更新linkField的高度以适应警告标签
        [self updateLinkFieldHeight];
        
//        // 根据内容自动调整高度
//        CGFloat fixedWidth = textView.frame.size.width;
//        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//        CGFloat newHeight = MAX(FIELD_DEFAULT_HEIGHT, newSize.height); // 最小高度为30
//        
//        [textView mas_updateConstraints:^(MASConstraintMaker *make) {
//            make.height.mas_equalTo(newHeight);
//        }];
    } else if (textView == self.textView) {
        [self updateTextViewHeight];
        [self.textView contentTextChanged];
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
        
        // 验证链接
        NSString *linkText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL isValidLink = [self isValidURL:linkText];
        
        // 只有当链接不为空且无效时才显示警告
        self.linkWarningLabel.hidden = (linkText.length == 0 || isValidLink);
        
        // 如果显示警告，确保警告标签位置正确
        if (!self.linkWarningLabel.hidden) {
            // 计算文本的位置和大小
            CGRect textRect = [textView.layoutManager usedRectForTextContainer:textView.textContainer];
            CGFloat textHeight = textRect.size.height;
            
            // 警告标签位置 - 放在文本下方
            CGFloat xPos = textView.textContainerInset.left;
            CGFloat yPos = textView.textContainerInset.top + textHeight + 5; // 文本下方5个点的位置
            
            self.linkWarningLabel.frame = CGRectMake(xPos, yPos, 100, 15);
        }
        [self updateLinkFieldHeight];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.titleField) {
        UILabel *placeholderLabel = [textView viewWithTag:999];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 隐藏清除按钮
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;

        // 保持字数提示标签可见（如果接近最大字数）
        NSInteger maxLength = 50;
        NSInteger textLength = textView.text.length;
        self.titleCountLabel.hidden = (textLength < maxLength * 0.8);
    } else if (textView == self.linkField) {
        UILabel *placeholderLabel = [textView viewWithTag:998];
        placeholderLabel.hidden = textView.text.length > 0;
        
        // 隐藏清除按钮
        UIButton *clearButton = [textView associatedObjectForKey:@"clearButton"];
        clearButton.hidden = YES;

        // 验证链接
        NSString *linkText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL isValidLink = [self isValidURL:linkText];
        
        // 只有当链接不为空且无效时才显示警告
        self.linkWarningLabel.hidden = (linkText.length == 0 || isValidLink);
        
        // 如果显示警告，确保警告标签位置正确
        if (!self.linkWarningLabel.hidden) {
            // 计算文本的位置和大小
            CGRect textRect = [textView.layoutManager usedRectForTextContainer:textView.textContainer];
            CGFloat textHeight = textRect.size.height;
            
            // 警告标签位置 - 放在文本下方
            CGFloat xPos = textView.textContainerInset.left;
            CGFloat yPos = textView.textContainerInset.top + textHeight + 5; // 文本下方5个点的位置
            
            self.linkWarningLabel.frame = CGRectMake(xPos, yPos, 100, 15);
        } else {
            self.linkWarningLabel.frame = CGRectZero;
        }
        // 更新linkField的高度以适应警告标签
        [self updateLinkFieldHeight];
    }
}

#pragma mark - UITextField Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.tagInputField) {
        [self addTagFromInput];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagInputField) {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        return newText.length <= 30; // 限制最多30个字
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.tagInputField) {
        [self addTagFromInput];
    }
    return YES;
}

- (void)showTagInput {
    // 隐藏添加按钮
    self.addTagButton.hidden = YES;
    
    // 显示输入框
    self.tagInputField.hidden = NO;
    [self.tagContainerView addSubview:self.tagInputField];
    
    // 确保布局已更新
    [self.tagContainerView layoutIfNeeded];
    // 获取添加按钮的位置
    CGFloat buttonX = self.addTagButton.frame.origin.x;
    CGFloat buttonY = self.addTagButton.frame.origin.y;
    
    // 设置输入框位置 - 从添加按钮的位置开始，延伸到屏幕右侧
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat rightMargin = 43;
    CGFloat inputWidth = screenWidth - buttonX - rightMargin; // 使用全部可用宽度
    
    [self.tagInputField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagContainerView).offset(buttonX);
        make.top.equalTo(self.tagContainerView).offset(buttonY);
        make.height.mas_equalTo(TAG_DEFAULT_HEIGHT);
        make.width.mas_equalTo(inputWidth);
    }];
    
    [self.tagInputField becomeFirstResponder];
}

// 更新 textView 高度的方法
- (void)updateTextViewHeight {
    // 计算内容高度
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, MAXFLOAT)];
    CGFloat newHeight = MAX(300, contentSize.height); // 最小高度为300
    
    // 只有当高度变化时才更新约束
    if (newHeight != self.textViewContentHeight) {
        self.textViewContentHeight = newHeight;
        
        [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(newHeight);
        }];
        
        // 更新line3View的位置
        [self.line3View mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.textView.mas_bottom);
        }];
        
        // 更新tagContainerView的位置
        [self.tagContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.line3View.mas_bottom).offset(16);
        }];
        
        // 更新containerView的底部约束
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.tagContainerView.mas_bottom).offset(16);
        }];
        
        // 强制布局更新
        [self.view layoutIfNeeded];
    }
}

- (void)richTextViewDidInsertAttachment:(RZRichTextView *)textView {
    [self updateTextViewHeight];
}

- (BOOL)isValidURL:(NSString *)urlString {
    // 简单的URL验证
    NSURL *url = [NSURL URLWithString:urlString];
    return (url && url.scheme && url.host);
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
        _leftBackButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_leftBackButton setTitleColor:[SLColorManager recorderTextColor] forState:UIControlStateNormal];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UIButton *)commitButton {
    if (!_commitButton) {
        _commitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_commitButton setTitle:@"提交" forState:UIControlStateNormal];
        _commitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_commitButton setTitleColor:[SLColorManager recorderTextColor] forState:UIControlStateNormal];
        [_commitButton addTarget:self action:@selector(commitBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commitButton;
}

- (UIScrollView *)contentView {
    if (!_contentView) {
        _contentView = [[UIScrollView alloc] init];
        _contentView.backgroundColor = UIColor.clearColor;
        _contentView.showsVerticalScrollIndicator = YES;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.bounces = YES;
    }
    return _contentView;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [SLColorManager primaryBackgroundColor];
    }
    return _containerView;
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
        _titleField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _titleField.textColor = [SLColorManager recorderTextColor];
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.delegate = self;
        _titleField.scrollEnabled = NO;
        _titleField.returnKeyType = UIReturnKeyDefault; // 允许换行
        _titleField.textContainerInset = UIEdgeInsetsMake(17.35, 0, 17.35, 30); // 右侧增加30的内边距，为清除按钮留出空间
        
        // 添加占位文本
        [self setupTitlePlaceholder];

        // 添加清除按钮
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 修改清除按钮的颜色，与下方清除按钮一致
        [clearButton setImage:[[UIImage systemImageNamed:@"xmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [clearButton setTintColor:[UIColor lightGrayColor]]; // 设置为浅灰色，与下方按钮一致
        clearButton.frame = CGRectMake(0, 0, 30, 30);
        clearButton.tag = 1001; // 设置标签以便识别
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        clearButton.hidden = YES; // 初始状态隐藏
        [_titleField addSubview:clearButton];
        
        // 保存清除按钮的引用，以便后续访问
        [_titleField setAssociatedObject:clearButton forKey:@"clearButton"];

        // 添加字数提示标签
        UILabel *countLabel = [[UILabel alloc] init];
        countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        countLabel.textColor = Color16(0X646566);
        countLabel.textAlignment = NSTextAlignmentCenter;
        countLabel.hidden = YES;
        countLabel.frame = CGRectMake(_titleField.bounds.size.width - 50, _titleField.bounds.size.height - 25, 40, 20);
        [_titleField addSubview:countLabel];
        self.titleCountLabel = countLabel;
    }
    return _titleField;
}

- (UITextView *)linkField {
    if (!_linkField) {
        _linkField = [[UITextView alloc] init];
        _linkField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _linkField.textColor = [SLColorManager lineTextColor];
        _linkField.backgroundColor = [UIColor clearColor];
        _linkField.delegate = self;
        _linkField.scrollEnabled = NO;
        _linkField.returnKeyType = UIReturnKeyDefault; // 允许换行
        _linkField.textContainerInset = UIEdgeInsetsMake(18.7, 0, 18.7, 30); // 右侧增加30的内边距，为清除按钮留出空间
        
        // 添加占位文本
        [self setupLinkPlaceholder];

        // 添加清除按钮
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // 修改清除按钮的颜色
        [clearButton setImage:[[UIImage systemImageNamed:@"xmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [clearButton setTintColor:[UIColor lightGrayColor]]; // 设置为浅灰色
        clearButton.frame = CGRectMake(0, 0, 30, 30);
        clearButton.tag = 1002; // 设置标签以便识别
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        clearButton.hidden = YES; // 初始状态隐藏
        [_linkField addSubview:clearButton];
        
        // 保存清除按钮的引用，以便后续访问
        [_linkField setAssociatedObject:clearButton forKey:@"clearButton"];
        
        // 设置内容优先级，确保不会挤压其他视图
//        [_linkField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
//        [_linkField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        // 添加链接警告标签 - 直接放在输入框内部
        UILabel *warningLabel = [[UILabel alloc] init];
        warningLabel.text = @"链接不合法";
        warningLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        warningLabel.textColor = [UIColor redColor];
        warningLabel.hidden = YES; // 初始状态隐藏
        [_linkField addSubview:warningLabel];
        self.linkWarningLabel = warningLabel;
    }
    return _linkField;
}

- (RZRichTextView *)textView {
    if (!_textView) {
        _textView = [[RZRichTextView alloc] initWithFrame:CGRectZero viewModel:[RZRichTextViewModel sharedWithEdit:YES]];
        _textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _textView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _textView.textColor = [SLColorManager cellTitleColor];
       _textView.delegate = self;
       _textView.scrollEnabled = NO;
    }
    return _textView;
}

- (UIView *)line1View {
    if (!_line1View) {
        _line1View = [[UIView alloc] init];
        _line1View.backgroundColor = [SLColorManager cellDivideLineColor];
        _line1View.contentScaleFactor = [UIScreen mainScreen].scale;
    }
    return _line1View;
}

- (UIView *)line2View {
    if (!_line2View) {
        _line2View = [[UIView alloc] init];
        _line2View.backgroundColor = [SLColorManager cellDivideLineColor];
        _line2View.contentScaleFactor = [UIScreen mainScreen].scale;
    }
    return _line2View;
}

- (UIView *)line3View {
    if (!_line3View) {
        _line3View = [[UIView alloc] init];
        _line3View.backgroundColor = [SLColorManager cellDivideLineColor];
        _line3View.contentScaleFactor = [UIScreen mainScreen].scale;
    }
    return _line3View;
}

- (UIView *)tagContainerView {
    if (!_tagContainerView) {
        _tagContainerView = [[UIView alloc] init];
        _tagContainerView.backgroundColor = [UIColor clearColor];
    }
    return _tagContainerView;
}

- (UIButton *)addTagButton {
    if (!_addTagButton) {
        _addTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_addTagButton setTitle:@"+ 标签" forState:UIControlStateNormal];
        [_addTagButton setTitleColor:[SLColorManager recorderTagTextColor] forState:UIControlStateNormal];
        _addTagButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _addTagButton.backgroundColor = [SLColorManager recorderTagBgColor];
        _addTagButton.layer.cornerRadius = TAG_DEFAULT_HEIGHT / 2;
        _addTagButton.layer.borderColor = [SLColorManager recorderTagBorderColor].CGColor;
        
        // 创建虚线边框
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.strokeColor = [SLColorManager recorderTagBorderColor].CGColor;
        borderLayer.lineDashPattern = @[@4, @2];
        borderLayer.lineWidth = 1.0;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        
        // 设置路径 - 宽度先设置一个默认值，后续会根据文本动态调整
        CGRect borderRect = CGRectMake(0, 0, 80, TAG_DEFAULT_HEIGHT);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:TAG_DEFAULT_HEIGHT/2];
        borderLayer.path = path.CGPath;
        borderLayer.name = @"dashedBorder"; // 添加名称以便后续更新
        
        [_addTagButton.layer addSublayer:borderLayer];
        [_addTagButton addTarget:self action:@selector(showTagInput) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addTagButton;
}

- (UITextField *)tagInputField {
    if (!_tagInputField) {
        _tagInputField = [[UITextField alloc] init];
        _tagInputField.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _tagInputField.textColor = [SLColorManager recorderTagTextColor];
        _tagInputField.backgroundColor = UIColor.clearColor;
        _tagInputField.returnKeyType = UIReturnKeyDone;
        _tagInputField.delegate = self;
        _tagInputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, TAG_DEFAULT_HEIGHT)];
        _tagInputField.leftViewMode = UITextFieldViewModeAlways;
    }
    return _tagInputField;
}

- (SLRecordViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [SLRecordViewModel new];
    }
    return _viewModel;
}

@end
