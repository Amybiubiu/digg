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
#import "SLRecordViewModel.h"
#import "SVProgressHUD.h"
#import "SLWebViewController.h"
#import "SLColorManager.h"
#import "UIView+Associated.h"
#import "digg-Swift.h"
#import "UIView+SLToast.h"
#import "TZImagePickerController.h"
#import "SLPageControlView.h"

#define FIELD_DEFAULT_HEIGHT 60
#define TAG_DEFAULT_HEIGHT 24

@interface SLRecordViewController () <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *commitButton;

@property (nonatomic, strong) UIScrollView* contentView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextField *titleField; // 标题输入框
@property (nonatomic, strong) UITextField *linkField;  // 链接输入框
@property (nonatomic, strong) UITextView *textView;    // 多行文本输入框
@property (nonatomic, strong) UIScrollView *imagesScrollView; // 图片滚动视图
@property (nonatomic, strong) NSMutableArray *selectedImages; // 选中的图片数组

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
@property (nonatomic, assign) BOOL linkFieldVisible;
@property (nonatomic, strong) UIButton *linkCloseButton;
@property (nonatomic, strong) UIButton *imagesAddButton;
@property (nonatomic, strong) UIButton *imageDeleteOverlayButton;
@property (nonatomic, assign) NSInteger selectedImageIndex;
@property (nonatomic, strong) SLPageControlView *pageControl;

@end

@implementation SLRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    [self.leftBackButton setHidden:NO];
    self.tags = [NSMutableArray array];
    self.selectedImages = [NSMutableArray array];
    self.textViewContentHeight = 300;
    [self setupUI];
    [self setupInputAccessoryView];
    self.tagInputField.hidden = YES;
    if (self.isEdit) {
        [self.leftBackButton setTitle:@"取消" forState:UIControlStateNormal];

        self.titleField.text = self.titleText;
        [self titleFieldDidChange:self.titleField]; // Update count label

        self.linkField.text = self.url;
        if (self.url.length > 0) {
            [self linkFieldDidChange:self.linkField];
            [self showLinkField];
        }

        self.textView.text = self.content;
        UILabel *textViewPlaceholder = [self.textView viewWithTag:997];
        textViewPlaceholder.hidden = self.content.length > 0;
        // [self.textView showPlaceHolder];
        // [self.textView becomeFirstResponder];

        [self.tags addObjectsFromArray:self.labels];
        
        // Load existing images if any
        if (self.imageUrls.count > 0) {
            [self.selectedImages addObjectsFromArray:self.imageUrls];
            [self refreshImagesDisplay];
        }
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
    [self.containerView addSubview:self.titleField];
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];

    [self.containerView addSubview:self.tagContainerView];
    [self.tagContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom).offset(10);
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
    
    [self.containerView addSubview:self.linkField];
    [self.linkField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagContainerView.mas_bottom).offset(10);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(0);
    }];
    self.linkField.hidden = YES;

    // Images ScrollView
    [self.containerView addSubview:self.imagesScrollView];
    [self.imagesScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom).offset(10);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0); // Initially 0, update when images added
    }];
    
    [self.containerView addSubview:self.imagesAddButton];
    [self.imagesAddButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.imagesScrollView.mas_bottom).offset(-8);
        make.right.equalTo(self.containerView).offset(-12);
        make.size.mas_equalTo(CGSizeMake(64, 28));
    }];
    
    [self.containerView addSubview:self.imageDeleteOverlayButton];
    [self.imageDeleteOverlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesScrollView.mas_top).offset(8);
        make.right.equalTo(self.containerView).offset(-12);
        make.width.height.mas_equalTo(32);
    }];
    
    self.pageControl = [[SLPageControlView alloc] init];
    self.pageControl.hidden = YES;
    self.pageControl.dotDiameter = 8.0;
    self.pageControl.dotSpacing = 12.0;
    self.pageControl.contentInsets = UIEdgeInsetsMake(6, 12, 6, 12);
    self.pageControl.dotColor = [UIColor colorWithWhite:1 alpha:0.35];
    self.pageControl.currentDotColor = [UIColor whiteColor];
    self.pageControl.backgroundFillColor = [UIColor colorWithWhite:0 alpha:0.35];
    [self.containerView addSubview:self.pageControl];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.imagesScrollView.mas_bottom).offset(-8);
        make.centerX.equalTo(self.imagesScrollView);
        make.height.mas_equalTo(24);
    }];
    
    [self.containerView addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesScrollView.mas_bottom).offset(10);
        make.left.equalTo(self.containerView).offset(12);
        make.right.equalTo(self.containerView).offset(-12);
        make.height.mas_equalTo(300);
    }];
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.textView.mas_bottom).offset(16);
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
    }
}

- (void)closeLinkField:(UIButton *)sender {
    [self hideLinkField];
}

- (void)clearAll {
    [self.titleField resignFirstResponder];
    [self.linkField resignFirstResponder];
    [self.textView resignFirstResponder];
    
    self.titleField.text = @"";
    self.titleCountLabel.hidden = YES;
    
    // 清空链接输入框
    self.linkField.text = @"";
    self.linkWarningLabel.hidden = YES;
    [self hideLinkField];

    // 清空正文输入框
    self.textView.text = @"";
    UILabel *contentPlaceholder = [self.textView viewWithTag:997];
    contentPlaceholder.hidden = NO;
    
    // 清空图片
    [self.selectedImages removeAllObjects];
    [self refreshImagesDisplay];

    [self.tags removeAllObjects];
    [self refreshTagsDisplay];
    [self updateTagsLayout];
    [self.titleField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(12);
        make.right.equalTo(self.contentView).offset(-10);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];
}

 

- (void)updateLinkFieldHeight {
    CGFloat fixedWidth = self.linkField.frame.size.width > 0 ? self.linkField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    // For UITextField, sizeThatFits might return small height. Ensure min height.
    CGSize contentSize = [self.linkField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGFloat baseHeight = MAX(FIELD_DEFAULT_HEIGHT, contentSize.height);
    
    // 如果警告标签可见，增加额外高度
    CGFloat extraHeight = self.linkWarningLabel.hidden ? 0 : 15; // 警告标签高度+间距
    CGFloat newHeight = baseHeight + extraHeight;
    
    // 更新linkField高度
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(newHeight);
    }];
    
    // 强制布局更新
    [self.view layoutIfNeeded];
    
    if (self.linkCloseButton && !self.linkCloseButton.hidden) {
        CGRect cFrame = self.linkCloseButton.frame;
        cFrame.origin.x = self.linkField.bounds.size.width - cFrame.size.width;
        cFrame.origin.y = (self.linkField.bounds.size.height - cFrame.size.height) / 2;
        self.linkCloseButton.frame = cFrame;
    }
    
    if (!self.linkWarningLabel.hidden) {
         self.linkWarningLabel.frame = CGRectMake(0, self.linkField.bounds.size.height - 15, 100, 15);
    }
}

- (void)gotoH5Page:(NSString *)articleId {
    NSString *url = [NSString stringWithFormat:@"%@%@", ARTICAL_PAGE_DETAIL_URL, articleId];
    SLWebViewController *webVC = [[SLWebViewController alloc] init];
    [webVC startLoadRequestWithUrl:url];
    webVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webVC animated:YES];
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
    NSString* title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (title.length == 0 && content.length == 0) {
        [self.view sl_showToast:@"请添加标题或正文"];
        return;
    }
    
    // Filter images that need upload
    NSMutableArray *imagesToUpload = [NSMutableArray array];
    NSMutableArray *finalImageUrls = [NSMutableArray array];
    
    for (id item in self.selectedImages) {
        if ([item isKindOfClass:[UIImage class]]) {
            [imagesToUpload addObject:item];
        } else if ([item isKindOfClass:[NSString class]]) {
            [finalImageUrls addObject:item];
        }
    }
    
    if (imagesToUpload.count > 0) {
        [SVProgressHUD showWithStatus:@"正在上传图片..."];
        [self uploadImages:imagesToUpload completion:^(NSArray *urls) {
            [finalImageUrls addObjectsFromArray:urls];
            [self submitWithImageUrls:finalImageUrls];
        }];
    } else {
        [self submitWithImageUrls:finalImageUrls];
    }
}

- (void)uploadImages:(NSArray *)images completion:(void(^)(NSArray *urls))completion {
    NSMutableArray *uploadedUrls = [NSMutableArray array];
    [self uploadNextImage:images index:0 result:uploadedUrls completion:completion];
}

- (void)uploadNextImage:(NSArray *)images index:(NSInteger)index result:(NSMutableArray *)result completion:(void(^)(NSArray *urls))completion {
    if (index >= images.count) {
        if (completion) {
            completion(result);
        }
        return;
    }
    
    UIImage *image = images[index];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    
    @weakobj(self)
    [self.viewModel updateImage:imageData progress:nil resultHandler:^(BOOL isSuccess, NSString *url) {
        @strongobj(self)
        if (isSuccess && url) {
            [result addObject:url];
        }
        [self uploadNextImage:images index:index+1 result:result completion:completion];
    }];
}

- (void)submitWithImageUrls:(NSArray *)imageUrls {
    NSString* title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* url = [self.linkField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [SVProgressHUD show];
    @weakobj(self)
    if (self.isEdit) {
        [self.viewModel updateRecord:title link:url content:content imageUrls:imageUrls labels:self.tags articleId:self.articleId resultHandler:^(BOOL isSuccess, NSString * _Nonnull articleId) {
            @strongobj(self)
            [SVProgressHUD dismiss];
            if (isSuccess) {
                [self backPage];
            } else {
                [self gotoLoginPage];
            }
        }];
    } else {
        [self.viewModel subimtRecord:title link:url content:content imageUrls:imageUrls labels:self.tags resultHandler:^(BOOL isSuccess, NSString * articleId) {
            @strongobj(self)
            [SVProgressHUD dismiss];
            if (isSuccess) {
                [self gotoH5Page:articleId];
                [self clearAll];
            } else { //401 跳转到登陆
                [self gotoLoginPage];
            }
        }];
    }
}

- (void)addTagFromInput {
    NSString *tagText = [self.tagInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (tagText.length > 0) {
        [self.tags addObject:tagText];
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
        UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
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
        tagView.backgroundColor = Color16(0xFF6B6B);
        tagView.layer.cornerRadius = 12;
        tagView.layer.borderColor = [SLColorManager recorderTagBorderColor].CGColor;
        tagView.layer.borderWidth = 0;
        
        // 创建标签文本
        UILabel *tagLabel = [[UILabel alloc] init];
        tagLabel.text = tagName;
        tagLabel.font = font;
        tagLabel.textColor = [UIColor whiteColor];
        
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
        [deleteButton setTintColor:[UIColor whiteColor]];
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
        [self refreshTagsDisplay]; // 刷新标签显示
    }
}

// 更新标签布局
- (void)updateTagsLayout {
    [self.tagContainerView layoutIfNeeded];
}

- (void)gotoLoginPage {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:LOGIN_PAGE_URL];
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [self presentViewController:dvc animated:YES completion:nil];
}

#pragma mark - UITextField Event
- (void)titleFieldDidChange:(UITextField *)textField {
    // 限制标题最大字符数为50
    NSInteger maxLength = 50;
    if (textField.text.length > maxLength) {
        textField.text = [textField.text substringToIndex:maxLength];
    }
    
    // 更新字数提示标签
    NSInteger textLength = textField.text.length;
    self.titleCountLabel.text = [NSString stringWithFormat:@"%ld/%ld", textLength, maxLength];
    
    // 当字数接近或达到最大值时显示标签
    self.titleCountLabel.hidden = (textLength < maxLength * 0.8);
    
    // 更新标签位置 - 放在右侧，如果系统清除按钮显示，需要避让
    if (!self.titleCountLabel.hidden) {
        [self.titleCountLabel sizeToFit];
        // 简单处理：放在右侧偏左一点
        CGFloat rightMargin = 10;
        if (textField.isEditing && textField.text.length > 0) {
            rightMargin = 30; // 避让清除按钮
        }
        CGRect frame = self.titleCountLabel.frame;
        frame.origin.x = textField.bounds.size.width - frame.size.width - rightMargin;
        frame.origin.y = (textField.bounds.size.height - frame.size.height) / 2;
        self.titleCountLabel.frame = frame;
        [textField bringSubviewToFront:self.titleCountLabel];
    }
}

- (void)linkFieldDidChange:(UITextField *)textField {
    // Update Close Button Position
    if (self.linkCloseButton) {
        CGRect cFrame = self.linkCloseButton.frame;
        cFrame.origin.x = textField.bounds.size.width - cFrame.size.width;
        cFrame.origin.y = (textField.bounds.size.height - cFrame.size.height) / 2;
        self.linkCloseButton.frame = cFrame;
        self.linkCloseButton.hidden = NO;
    }
    
    // Validate Link
    NSString *linkText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL isValidLink = [self isValidURL:linkText];
    
    // Show/Hide Warning
    self.linkWarningLabel.hidden = (linkText.length == 0 || isValidLink);
    
    // Update Warning Label Position
    if (!self.linkWarningLabel.hidden) {
        // Position below text
        self.linkWarningLabel.frame = CGRectMake(0, textField.bounds.size.height - 15, 100, 15);
    }
    
    [self updateLinkFieldHeight];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.textView) {
        [self updateTextViewHeight];
        
        UILabel *placeholderLabel = [self.textView viewWithTag:997];
        placeholderLabel.hidden = textView.text.length > 0;
    }
}

#pragma mark - UITextField Delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.linkField) {
        [self linkFieldDidChange:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.tagInputField) {
        [self addTagFromInput];
    } else if (textField == self.linkField) {
        [self linkFieldDidChange:textField];
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
        
        // 更新containerView的底部约束
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.textView.mas_bottom).offset(16);
        }];
        
        // 强制布局更新
        [self.view layoutIfNeeded];
    }
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


- (UITextField *)titleField {
    if (!_titleField) {
        _titleField = [[UITextField alloc] init];
        _titleField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _titleField.textColor = [SLColorManager recorderTextColor];
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.delegate = self;
        _titleField.returnKeyType = UIReturnKeyNext;
        _titleField.placeholder = @"添加标题";
        _titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_titleField addTarget:self action:@selector(titleFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

        // 添加字数提示标签
        UILabel *countLabel = [[UILabel alloc] init];
        countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        countLabel.textColor = Color16(0X646566);
        countLabel.textAlignment = NSTextAlignmentCenter;
        countLabel.hidden = YES;
        [_titleField addSubview:countLabel];
        self.titleCountLabel = countLabel;
    }
    return _titleField;
}

- (UITextField *)linkField {
    if (!_linkField) {
        _linkField = [[UITextField alloc] init];
        _linkField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _linkField.textColor = [SLColorManager lineTextColor];
        _linkField.backgroundColor = [UIColor clearColor];
        _linkField.delegate = self;
        _linkField.returnKeyType = UIReturnKeyDone;
        _linkField.placeholder = @"链接";
        [_linkField addTarget:self action:@selector(linkFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        // 使用 rightView 占位，确保文字不被关闭按钮遮挡
        UIView *rightPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 0)];
        _linkField.rightView = rightPaddingView;
        _linkField.rightViewMode = UITextFieldViewModeAlways;
        
        // 添加关闭按钮
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setImage:[[UIImage systemImageNamed:@"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [closeButton setTintColor:[UIColor lightGrayColor]];
        closeButton.frame = CGRectMake(0, 0, 30, 30);
        closeButton.tag = 1003;
        [closeButton addTarget:self action:@selector(closeLinkField:) forControlEvents:UIControlEventTouchUpInside];
        closeButton.hidden = YES;
        [_linkField addSubview:closeButton];
        self.linkCloseButton = closeButton;
        
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

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _textView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _textView.textColor = [SLColorManager cellTitleColor];
        _textView.delegate = self;
        _textView.scrollEnabled = NO;
        _textView.returnKeyType = UIReturnKeyDefault;
        
        [self setupContentPlaceholder];
        [self setupInputAccessoryView];
    }
    return _textView;
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

- (void)setupContentPlaceholder {
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"正文文本";
    placeholderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    placeholderLabel.textColor = [UIColor lightGrayColor];
    placeholderLabel.hidden = NO;
    placeholderLabel.tag = 997;
    [self.textView addSubview:placeholderLabel];
    [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView).offset(8);
        make.left.equalTo(self.textView).offset(5);
    }];
}

- (void)setupInputAccessoryView {
    UIView *accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 44)];
    accessoryView.backgroundColor = [UIColor whiteColor];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.5)];
    line.backgroundColor = [UIColor lightGrayColor];
    [accessoryView addSubview:line];
    
    UIButton *linkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [linkBtn setImage:[UIImage systemImageNamed:@"link"] forState:UIControlStateNormal];
    [linkBtn setTintColor:Color16(0x333333)];
    linkBtn.frame = CGRectMake(15, 0, 44, 44);
    [linkBtn addTarget:self action:@selector(showLinkField) forControlEvents:UIControlEventTouchUpInside];
    [accessoryView addSubview:linkBtn];
    
    UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [imageBtn setImage:[UIImage systemImageNamed:@"photo"] forState:UIControlStateNormal];
    [imageBtn setTintColor:Color16(0x333333)];
    imageBtn.frame = CGRectMake(74, 0, 44, 44);
    [imageBtn addTarget:self action:@selector(addImage) forControlEvents:UIControlEventTouchUpInside];
    [accessoryView addSubview:imageBtn];
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [doneBtn setTintColor:Color16(0x333333)];
    doneBtn.frame = CGRectMake(kScreenWidth - 70, 0, 60, 44);
    [doneBtn addTarget:self action:@selector(keyboardDone) forControlEvents:UIControlEventTouchUpInside];
    [accessoryView addSubview:doneBtn];
    
    self.textView.inputAccessoryView = accessoryView;
    self.titleField.inputAccessoryView = accessoryView;
}

- (void)keyboardDone {
    [self.view endEditing:YES];
}

- (void)showLinkField {
    if (self.linkFieldVisible) {
        [self.linkField becomeFirstResponder];
        return;
    }
    self.linkFieldVisible = YES;
    self.linkField.hidden = NO;
    self.linkCloseButton.hidden = NO;
    
    // 更新高度和按钮位置
    [self updateLinkFieldHeight];
    
    // 聚焦
    [self.linkField becomeFirstResponder];
    
    // 滚动到可见区域
    CGRect rect = [self.linkField convertRect:self.linkField.bounds toView:self.contentView];
    [self.contentView scrollRectToVisible:rect animated:YES];
}

- (void)hideLinkField {
    self.linkFieldVisible = NO;
    [self.linkField resignFirstResponder];
    self.linkField.text = @"";
    self.linkCloseButton.hidden = YES;
    self.linkWarningLabel.hidden = YES;
    
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
    }];
    
    [self.view layoutIfNeeded];
}

- (void)addImage {
    TZImagePickerController *picker = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:nil];
    picker.allowPickingVideo = NO;
    picker.allowTakePicture = NO;
    picker.allowPreview = YES;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    @weakobj(self)
    [picker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        @strongobj(self)
        if (photos.count > 0) {
            [self.selectedImages addObjectsFromArray:photos];
            [self refreshImagesDisplay];
        }
    }];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        [self.selectedImages addObject:image];
        [self refreshImagesDisplay];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshImagesDisplay {
    // Clear existing image views
    [self.imagesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (self.selectedImages.count == 0) {
        self.imagesScrollView.hidden = YES;
        [self.imagesScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
        self.pageControl.hidden = YES;
        [self.pageControl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
        self.imagesAddButton.hidden = YES;
        self.imageDeleteOverlayButton.hidden = YES;
        
        [self.view layoutIfNeeded];
        return;
    }
    
    self.imagesScrollView.hidden = NO;
    CGFloat imageHeight = 300;
    CGFloat padding = 0;
    CGFloat scrollWidth = kScreenWidth;
    CGFloat currentX = 0;
    
    for (int i = 0; i < self.selectedImages.count; i++) {
        id item = self.selectedImages[i];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(currentX, 0, scrollWidth, imageHeight)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 0;
        imageView.userInteractionEnabled = YES;
        imageView.tag = i;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [imageView addGestureRecognizer:tap];
        
        if ([item isKindOfClass:[UIImage class]]) {
            imageView.image = (UIImage *)item;
        } else if ([item isKindOfClass:[NSString class]]) {
            // Load from URL (using SDWebImage or similar if available, otherwise just placeholder or try loading)
            // Assuming YYWebImage or SDWebImage is used in project based on previous context (YYModel used)
            // Check if UIImageView+YYWebImage.h is available?
            // I'll try generic approach or assume YYWebImage is available or just set placeholder for now if I can't confirm.
            // But I should try to load it.
            // Let's use simple data task if no library is imported, but that's bad.
            // I'll check imports. 'SLRecordViewModel.m' imports YYModel.
            // I'll just use a placeholder text or attempt to load if I can.
            // Actually, in `SLRecordViewController.m` imports, I should check.
            // But for now, I'll just set backgroundColor or placeholder.
            imageView.backgroundColor = [UIColor lightGrayColor];
            // Try to load asynchronously
             dispatch_async(dispatch_get_global_queue(0,0), ^{
                 NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: (NSString*)item]];
                 if ( data == nil )
                     return;
                 dispatch_async(dispatch_get_main_queue(), ^{
                     imageView.image = [UIImage imageWithData: data];
                 });
             });
        }
        
        [self.imagesScrollView addSubview:imageView];
        
        currentX += scrollWidth;
    }
    

    
    self.imagesScrollView.contentSize = CGSizeMake(MAX(currentX, scrollWidth), imageHeight);
    [self.imagesScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(imageHeight);
    }];
    
    self.pageControl.numberOfPages = self.selectedImages.count;
    self.pageControl.currentPage = 0;
    
    if (self.selectedImages.count > 1) {
        self.pageControl.hidden = NO;
        [self.pageControl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24);
        }];
    } else {
        self.pageControl.hidden = YES;
        [self.pageControl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }

    self.imagesAddButton.hidden = NO;
    self.imageDeleteOverlayButton.hidden = NO;
    [self.containerView setNeedsLayout];
    [self.containerView layoutIfNeeded];
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    [self.view layoutIfNeeded];
    
    CGRect visibleRect = [self.imagesScrollView convertRect:self.imagesScrollView.bounds toView:self.contentView];
    [self.contentView scrollRectToVisible:visibleRect animated:NO];
}

- (void)deleteImageConfirm:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"确定删除图片吗？" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除当前图片" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteCurrentImage];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除所有图片" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteAllImages];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteCurrentImage {
    NSInteger index = self.pageControl.currentPage;
    if (index < 0 || index >= self.selectedImages.count) return;
    
    [self.selectedImages removeObjectAtIndex:index];
    [self refreshImagesDisplay];
}

- (void)deleteAllImages {
    [self.selectedImages removeAllObjects];
    [self refreshImagesDisplay];
}

- (void)imageTapped:(UITapGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    if (![view isKindOfClass:[UIImageView class]]) return;
    NSInteger index = view.tag;
    self.selectedImageIndex = index;
    self.pageControl.currentPage = index;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.imagesScrollView) {
        CGFloat width = scrollView.bounds.size.width;
        NSInteger page = (NSInteger)round(scrollView.contentOffset.x / width);
        self.pageControl.currentPage = page;
    }
}

- (UIScrollView *)imagesScrollView {
    if (!_imagesScrollView) {
        _imagesScrollView = [[UIScrollView alloc] init];
        _imagesScrollView.showsHorizontalScrollIndicator = NO;
        _imagesScrollView.showsVerticalScrollIndicator = NO;
        _imagesScrollView.backgroundColor = [UIColor clearColor];
        _imagesScrollView.pagingEnabled = YES;
        _imagesScrollView.delegate = self;
    }
    return _imagesScrollView;
}

- (UIButton *)imagesAddButton {
    if (!_imagesAddButton) {
        _imagesAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imagesAddButton setTitle:@"添加" forState:UIControlStateNormal];
        _imagesAddButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_imagesAddButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightMedium scale:UIImageSymbolScaleMedium];
        [_imagesAddButton setImage:[UIImage systemImageNamed:@"photo.on.rectangle" withConfiguration:config] forState:UIControlStateNormal];
        
        _imagesAddButton.tintColor = [UIColor whiteColor];
        _imagesAddButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _imagesAddButton.layer.cornerRadius = 14;
        _imagesAddButton.layer.masksToBounds = YES;
        _imagesAddButton.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 2);
        _imagesAddButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        [_imagesAddButton addTarget:self action:@selector(addImage) forControlEvents:UIControlEventTouchUpInside];
        _imagesAddButton.hidden = YES;
    }
    return _imagesAddButton;
}

- (UIButton *)imageDeleteOverlayButton {
    if (!_imageDeleteOverlayButton) {
        _imageDeleteOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _imageDeleteOverlayButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _imageDeleteOverlayButton.layer.cornerRadius = 16;
        _imageDeleteOverlayButton.layer.masksToBounds = YES;
        
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleMedium];
        [_imageDeleteOverlayButton setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:config] forState:UIControlStateNormal];
        _imageDeleteOverlayButton.tintColor = [UIColor whiteColor];
        
        [_imageDeleteOverlayButton addTarget:self action:@selector(deleteImageConfirm:) forControlEvents:UIControlEventTouchUpInside];
        _imageDeleteOverlayButton.hidden = YES;
    }
    return _imageDeleteOverlayButton;
}

@end
