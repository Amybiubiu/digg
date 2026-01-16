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
#import <objc/runtime.h>

#define FIELD_DEFAULT_HEIGHT 28
#define TAG_DEFAULT_HEIGHT 32
#define HORIZONTAL_PADDING 16
#define VERTICAL_SPACING 18

@interface SLRecordViewController () <UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIView* navigationView;
@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *clearButton; // 清空按钮
@property (nonatomic, strong) UIButton *commitButton;

@property (nonatomic, strong) UIScrollView* contentView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextView *titleField; // 标题输入框（改为 UITextView 支持多行）
@property (nonatomic, strong) UITextView *linkField;  // 链接输入框（改为 UITextView 支持多行）
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
@property (nonatomic, assign) CGFloat titleFieldContentHeight; // 记录标题输入框高度
@property (nonatomic, assign) CGFloat linkFieldContentHeight; // 记录链接输入框高度

@property (nonatomic, strong) UILabel *titleCountLabel; // 标题字数提示标签
@property (nonatomic, strong) UILabel *linkWarningLabel; // 链接警告标签
@property (nonatomic, strong) NSTimer *linkValidationTimer; // 链接验证延迟定时器
@property (nonatomic, assign) BOOL linkFieldVisible;
@property (nonatomic, strong) UIButton *linkCloseButton;
@property (nonatomic, strong) UIButton *imagesAddButton;
@property (nonatomic, strong) UIButton *imageDeleteOverlayButton;
@property (nonatomic, assign) NSInteger selectedImageIndex;
@property (nonatomic, strong) SLPageControlView *pageControl;
@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, copy) NSString *draftKey;
@property (nonatomic, strong) UIToolbar *keyboardToolbar;
@property (nonatomic, strong) UIActivityIndicatorView *commitLoadingIndicator;
@property (nonatomic, copy) NSString *commitButtonOriginalTitle;
@property (nonatomic, strong) NSTimer *commitTimeoutTimer; // 提交超时定时器
@property (nonatomic, assign) BOOL isCommitTimeout; // 提交是否超时
@property (nonatomic, strong) MASConstraint *commitButtonWidthConstraint; // 按钮宽度约束
@property (nonatomic, strong) UIButton *dismissKeyboardButton; // 收起键盘按钮
@property (nonatomic, assign) BOOL isCommitting; // 是否正在提交中（防抖标志）

@end

@implementation SLRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    self.navigationController.navigationBar.hidden = YES;
    [self.leftBackButton setHidden:NO];
    self.tags = [NSMutableArray array];
    self.selectedImages = [NSMutableArray array];
    self.textViewContentHeight = 300;
    self.titleFieldContentHeight = FIELD_DEFAULT_HEIGHT;
    self.linkFieldContentHeight = FIELD_DEFAULT_HEIGHT;
    [self setupUI];
    [self setupKeyboardToolbar];
    [self setupAccessoryView];
    self.tagInputField.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // 设置左边按钮 - 所有模式下都显示关闭图标
    [self.leftBackButton setTitle:nil forState:UIControlStateNormal];
    UIImageSymbolConfiguration *closeConfig = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    UIImage *closeIcon = [UIImage systemImageNamed:@"xmark" withConfiguration:closeConfig];
    [self.leftBackButton setImage:closeIcon forState:UIControlStateNormal];
    [self.leftBackButton setTintColor:[SLColorManager recorderTextColor]];

    // 如果是编辑模式，加载编辑数据
    if (self.isEdit) {
        self.titleField.text = self.titleText;
        [self textViewDidChange:self.titleField]; // Update count label

        self.linkField.text = self.url;
        if (self.url.length > 0) {
            [self textViewDidChange:self.linkField];
            [self showLinkField];
        }

        self.textView.text = self.content;
        UILabel *textViewPlaceholder = [self.textView viewWithTag:997];
        textViewPlaceholder.hidden = self.content.length > 0;

        [self.tags addObjectsFromArray:self.labels];

        // Load existing images if any
        if (self.imageUrls.count > 0) {
            for (NSString *url in self.imageUrls) {
                NSMutableDictionary *item = [@{@"url": url} mutableCopy];
                [self.selectedImages addObject:item];
            }
            [self refreshImagesDisplay];
        }
    }
    [self refreshTagsDisplay];
    [self updateTagsLayout];
    [self loadDraft];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 自动弹起正文输入框的键盘
    [self.textView becomeFirstResponder];
}

#pragma mark - Keyboard Toolbar Setup
- (void)setupKeyboardToolbar {
    // 使用空的 UIView 作为 inputAccessoryView，完全隐藏键盘顶部附件栏
    UIView *emptyAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyAccessoryView.backgroundColor = [UIColor clearColor];

    self.titleField.inputAccessoryView = emptyAccessoryView;
    self.linkField.inputAccessoryView = emptyAccessoryView;
    self.textView.inputAccessoryView = emptyAccessoryView;
    self.tagInputField.inputAccessoryView = emptyAccessoryView;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
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
        make.left.equalTo(self.navigationView).offset(HORIZONTAL_PADDING);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.height.mas_equalTo(32);
    }];
    
    [self.navigationView addSubview:self.clearButton];
    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationView).offset(-90);
        make.top.equalTo(self.navigationView).offset(5 + STATUSBAR_HEIGHT);
        make.height.mas_equalTo(32);
        make.width.mas_equalTo(32);
    }];

    [self.navigationView addSubview:self.commitButton];
    [self.commitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationView).offset(-HORIZONTAL_PADDING);
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
        make.top.equalTo(self.containerView).offset(8);
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING - 60); // 为字数标签留出空间
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];

    // 添加字数提示标签 - 与 titleField 并排显示
    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    countLabel.textColor = Color16(0X646566);
    countLabel.textAlignment = NSTextAlignmentRight;
    countLabel.hidden = YES;
    self.titleCountLabel = countLabel;
    [self.containerView addSubview:countLabel];
    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleField.mas_right).offset(8);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
        make.bottom.equalTo(self.titleField.mas_bottom);
        make.height.mas_equalTo(20);
    }];

    [self.containerView addSubview:self.tagContainerView];
    [self.tagContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom).offset(VERTICAL_SPACING);
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
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
        make.top.equalTo(self.tagContainerView.mas_bottom).offset(0); // 初始隐藏，上边距为0
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING - 32); // 为关闭按钮留出空间
        make.height.mas_equalTo(0);
    }];
    self.linkField.hidden = YES;

    // 添加链接关闭按钮 - 与 linkField 并排显示
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[[UIImage systemImageNamed:@"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [closeButton setTintColor:[UIColor lightGrayColor]];
    [closeButton addTarget:self action:@selector(closeLinkField:) forControlEvents:UIControlEventTouchUpInside];
    closeButton.hidden = YES;
    self.linkCloseButton = closeButton;
    [self.containerView addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.linkField.mas_right).offset(8);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
        make.bottom.equalTo(self.linkField.mas_bottom);
        make.width.height.mas_equalTo(24);
    }];

    // 添加链接警告标签 - 位于输入框下方
    UILabel *warningLabel = [[UILabel alloc] init];
    warningLabel.text = @"  糟糕，此链接无效。请仔细检查，然后重试。";
    warningLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    warningLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0]; // #666666 深灰色
    warningLabel.backgroundColor = [UIColor colorWithRed:249.0/255.0 green:248.0/255.0 blue:246.0/255.0 alpha:1.0]; // #F9F8F6 米白色背景
    warningLabel.layer.cornerRadius = 8;
    warningLabel.layer.masksToBounds = YES;
    warningLabel.textAlignment = NSTextAlignmentLeft;
    warningLabel.numberOfLines = 0;
    warningLabel.hidden = YES;
    self.linkWarningLabel = warningLabel;
    [self.containerView addSubview:warningLabel];
    [warningLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom).offset(0); // 初始隐藏，紧贴输入框
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
        make.height.mas_equalTo(0); // 初始高度为0
    }];

    // Images ScrollView
    [self.containerView addSubview:self.imagesScrollView];
    [self.imagesScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(warningLabel.mas_bottom).offset(0); // 相对于警告标签，初始隐藏，上边距为0
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0); // Initially 0, update when images added
    }];
    
    [self.containerView addSubview:self.imagesAddButton];
    [self.imagesAddButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.imagesScrollView.mas_bottom).offset(-8);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
        make.size.mas_equalTo(CGSizeMake(64, 28));
    }];

    [self.containerView addSubview:self.imageDeleteOverlayButton];
    [self.imageDeleteOverlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesScrollView.mas_top).offset(8);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
        make.width.height.mas_equalTo(28);
    }];
    
    self.pageControl = [[SLPageControlView alloc] init];
    self.pageControl.hidden = YES;
    self.pageControl.dotDiameter = 5.0; // 更小的圆点
    self.pageControl.dotSpacing = 8.0; // 更紧凑的间距
    self.pageControl.contentInsets = UIEdgeInsetsMake(4, 10, 4, 10); // 更小的内边距
    self.pageControl.dotColor = [UIColor colorWithWhite:1 alpha:0.5]; // 提高不透明度
    self.pageControl.currentDotColor = [UIColor whiteColor];
    self.pageControl.backgroundFillColor = [UIColor colorWithWhite:0 alpha:0.65]; // 更深的背景
    [self.containerView addSubview:self.pageControl];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.imagesScrollView.mas_bottom).offset(-8);
        make.centerX.equalTo(self.imagesScrollView);
        make.height.mas_equalTo(18); // 更小的高度
    }];
    
    [self.containerView addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesScrollView.mas_bottom).offset(VERTICAL_SPACING);
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING);
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

    // 显示标题 placeholder
    UILabel *titlePlaceholder = [self.titleField viewWithTag:998];
    titlePlaceholder.hidden = NO;
    
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
        make.left.equalTo(self.contentView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.contentView).offset(-HORIZONTAL_PADDING);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];
    [self clearDraft];
    [self updateClearButtonVisibility];
}

- (void)clearAllContent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"清空当前内容？"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"确认清空"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self clearAll];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateClearButtonVisibility {
    // 检查是否有任何内容
    BOOL hasContent = (self.titleField.text.length > 0 ||
                      self.textView.text.length > 0 ||
                      self.linkField.text.length > 0 ||
                      self.selectedImages.count > 0 ||
                      self.tags.count > 0);

    self.clearButton.hidden = !hasContent;
}



// 更新标题输入框高度的方法
- (void)updateTitleFieldHeight {
    // 计算内容高度
    CGSize contentSize = [self.titleField sizeThatFits:CGSizeMake(self.titleField.frame.size.width, MAXFLOAT)];
    CGFloat newHeight = MAX(FIELD_DEFAULT_HEIGHT, contentSize.height); // 最小高度为默认高度

    // 只有当高度变化时才更新约束
    if (newHeight != self.titleFieldContentHeight) {
        self.titleFieldContentHeight = newHeight;

        [self.titleField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(newHeight);
        }];

        // 强制布局更新
        [self.view layoutIfNeeded];
    }
}

- (void)updateLinkFieldHeight {
    CGFloat fixedWidth = self.linkField.frame.size.width > 0 ? self.linkField.frame.size.width : [UIScreen.mainScreen bounds].size.width - 40;
    // 计算内容高度
    CGSize contentSize = [self.linkField sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGFloat baseHeight = MAX(FIELD_DEFAULT_HEIGHT, contentSize.height);

    // 只有当高度变化时才更新约束
    if (baseHeight != self.linkFieldContentHeight) {
        self.linkFieldContentHeight = baseHeight;

        // 更新linkField高度
        [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(baseHeight);
        }];

        // 强制布局更新
        [self.view layoutIfNeeded];
    }

    // 更新警告标签的高度和间距
    if (!self.linkWarningLabel.hidden) {
        [self.linkWarningLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(32);
            make.top.equalTo(self.linkField.mas_bottom).offset(8);
        }];
    } else {
        [self.linkWarningLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
            make.top.equalTo(self.linkField.mas_bottom).offset(0);
        }];
    }

    // 强制布局更新
    [self.view layoutIfNeeded];
}

- (void)gotoH5Page:(NSString *)articleId {
    NSString *url = [NSString stringWithFormat:@"%@%@", ARTICAL_PAGE_DETAIL_URL, articleId];
    SLWebViewController *webVC = [[SLWebViewController alloc] init];
    [webVC startLoadRequestWithUrl:url];
    webVC.hidesBottomBarWhenPushed = YES;

    // 判断是否是 modal 展示还是 navigation 展示
    if (self.presentingViewController) {
        // Modal 模式：先关闭当前页面，然后从 presenting controller 的 navigation controller push 详情页
        UIViewController *presentingVC = self.presentingViewController;
        [self dismissViewControllerAnimated:YES completion:^{
            // 找到 presenting controller 的 navigation controller
            UINavigationController *navController = nil;
            if ([presentingVC isKindOfClass:[UINavigationController class]]) {
                navController = (UINavigationController *)presentingVC;
            } else if ([presentingVC isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tabBarController = (UITabBarController *)presentingVC;
                if ([tabBarController.selectedViewController isKindOfClass:[UINavigationController class]]) {
                    navController = (UINavigationController *)tabBarController.selectedViewController;
                }
            } else if (presentingVC.navigationController) {
                navController = presentingVC.navigationController;
            }

            if (navController) {
                [navController pushViewController:webVC animated:YES];
            }
        }];
    } else if (self.navigationController) {
        // Navigation 模式：直接 push
        [self.navigationController pushViewController:webVC animated:YES];
    }
}

#pragma mark - Actions
- (void)backPage {
    // 判断是否是modal展示
    if (self.presentingViewController) {
        // Modal模式下，关闭页面
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.navigationController) {
        // 如果有导航控制器，执行pop
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Commit Button Loading State

- (void)showCommitButtonLoading {
    // 重置超时标志
    self.isCommitTimeout = NO;

    // 禁用按钮（但保持外观不变）
    self.commitButton.enabled = NO;

    // 保存原始标题
    self.commitButtonOriginalTitle = self.commitButton.titleLabel.text;

    // 保存按钮当前宽度，添加宽度约束防止按钮收缩
    CGFloat buttonWidth = self.commitButton.frame.size.width;
    [self.commitButton mas_updateConstraints:^(MASConstraintMaker *make) {
        self.commitButtonWidthConstraint = make.width.mas_equalTo(buttonWidth);
    }];

    // 隐藏文字
    [self.commitButton setTitle:@"" forState:UIControlStateNormal];

    // 创建并添加loading指示器 - 使用Medium样式
    if (!self.commitLoadingIndicator) {
        self.commitLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.commitLoadingIndicator.color = [UIColor whiteColor];
        self.commitLoadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    }

    [self.commitButton addSubview:self.commitLoadingIndicator];

    // 使用约束居中，确保位置准确
    [NSLayoutConstraint activateConstraints:@[
        [self.commitLoadingIndicator.centerXAnchor constraintEqualToAnchor:self.commitButton.centerXAnchor],
        [self.commitLoadingIndicator.centerYAnchor constraintEqualToAnchor:self.commitButton.centerYAnchor]
    ]];

    [self.commitLoadingIndicator startAnimating];

    // 启动2秒超时定时器
    [self.commitTimeoutTimer invalidate];
    self.commitTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(handleCommitTimeout) userInfo:nil repeats:NO];
}

- (void)hideCommitButtonLoading {
    // 取消超时定时器
    [self.commitTimeoutTimer invalidate];
    self.commitTimeoutTimer = nil;

    // 移除loading指示器
    [self.commitLoadingIndicator stopAnimating];
    [self.commitLoadingIndicator removeFromSuperview];

    // 恢复按钮文字和状态
    [self.commitButton setTitle:self.commitButtonOriginalTitle forState:UIControlStateNormal];
    self.commitButton.enabled = YES;

    // 移除宽度约束，让按钮恢复自适应
    if (self.commitButtonWidthConstraint) {
        [self.commitButtonWidthConstraint uninstall];
        self.commitButtonWidthConstraint = nil;
    }
}

- (void)handleCommitTimeout {
    // 标记为超时
    self.isCommitTimeout = YES;

    // 重置防抖标志
    self.isCommitting = NO;

    // 超时处理
    [self hideCommitButtonLoading];
    [self.view sl_showToast:@"发布超时，请重试"];
}

- (void)commitBtnClick {
    // 防抖：如果正在提交中，直接返回
    if (self.isCommitting) {
        return;
    }

    NSString* title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (title.length == 0 && content.length == 0) {
        [self.view sl_showToast:@"请添加标题或正文"];
        return;
    }

    // 设置提交中标志
    self.isCommitting = YES;

    // 显示按钮loading状态
    [self showCommitButtonLoading];

    // Gather urls; upload any remaining images without url
    NSMutableArray *imagesToUpload = [NSMutableArray array];
    NSMutableArray *finalImageUrls = [NSMutableArray array];
    for (NSDictionary *dict in self.selectedImages) {
        NSString *url = dict[@"url"];
        UIImage *img = dict[@"image"];
        if (url.length > 0) {
            [finalImageUrls addObject:url];
        } else if (img) {
            [imagesToUpload addObject:img];
        }
    }

    if (imagesToUpload.count > 0) {
        [self uploadImages:imagesToUpload completion:^(NSArray *urls) {
            [finalImageUrls addObjectsFromArray:urls];
            [self submitWithImageUrls:finalImageUrls];
        }];
    } else {
        [self submitWithImageUrls:finalImageUrls];
    }
    // 注意：不要在这里清空草稿，应该在提交成功后清空
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
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0); // 100% 最高清质量

    @weakobj(self)
    [self.viewModel updateImage:imageData progress:nil resultHandler:^(BOOL isSuccess, NSString *url) {
        @strongobj(self)
        if (isSuccess && url) {
            [result addObject:url];
        } else {
            // 图片上传失败，显示提示并恢复按钮状态
            self.isCommitting = NO; // 重置防抖标志
            [self hideCommitButtonLoading];
            [self.view sl_showToast:@"图片上传失败，请重试"];
            return;
        }
        [self uploadNextImage:images index:index+1 result:result completion:completion];
    }];
}

- (void)uploadPendingImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0); // 100% 最高清质量

    @weakobj(self)
    [self.viewModel updateImage:imageData progress:nil resultHandler:^(BOOL isSuccess, NSString *url) {
        @strongobj(self)
        if (isSuccess && url) {
            NSUInteger index = [self.selectedImages indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                return obj[@"image"] == image;
            }];
            if (index != NSNotFound) {
                NSMutableDictionary *item = [self.selectedImages[index] mutableCopy];
                item[@"url"] = url;
                self.selectedImages[index] = item;
                [self refreshImagesDisplay];
                [self saveDraft];
            }
        }
    }];
}

- (void)submitWithImageUrls:(NSArray *)imageUrls {
    NSString* title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* url = [self.linkField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* htmlContent = [self htmlFromText:content];

    @weakobj(self)
    if (self.isEdit) {
        [self.viewModel updateRecord:title link:url content:content imageUrls:imageUrls labels:self.tags htmlContent:htmlContent articleId:self.articleId resultHandler:^(BOOL isSuccess, NSString * _Nonnull articleId) {
            @strongobj(self)
            // 如果已经超时，不再处理结果
            if (self.isCommitTimeout) {
                self.isCommitting = NO; // 重置防抖标志
                return;
            }

            // 重置防抖标志
            self.isCommitting = NO;
            [self hideCommitButtonLoading];
            if (isSuccess) {
                // 编辑成功，清空草稿并跳转
                [self clearDraft];
                [self backPage];
            } else {
                // 编辑失败，显示错误提示
                [self.view sl_showToast:@"更新失败，请重试"];
            }
        }];
    } else {
        [self.viewModel subimtRecord:title link:url content:content imageUrls:imageUrls labels:self.tags htmlContent:htmlContent resultHandler:^(BOOL isSuccess, NSString * articleId) {
            @strongobj(self)
            // 如果已经超时，不再处理结果
            if (self.isCommitTimeout) {
                self.isCommitting = NO; // 重置防抖标志
                return;
            }

            // 重置防抖标志
            self.isCommitting = NO;
            [self hideCommitButtonLoading];
            if (isSuccess) {
                // 发布成功，清空草稿和内容，跳转到详情页
                [self clearDraft];
                [self gotoH5Page:articleId];
                [self clearAll];
            } else {
                // 发布失败，显示错误提示
                [self.view sl_showToast:@"发布失败，请重试"];
            }
        }];
    }
}

- (NSString *)htmlFromText:(NSString *)text {
    NSString *s = text ?: @"";
    if (s.length == 0) {
        return @"";
    }
    s = [s stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSArray<NSString *> *lines = [s componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *paragraphs = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString *line in lines) {
        NSString *escaped = line ?: @"";
        escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        escaped = [escaped stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        escaped = [escaped stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        if (escaped.length == 0) {
            [paragraphs addObject:@"<p><br/></p>"];
        } else {
            [paragraphs addObject:[NSString stringWithFormat:@"<p>%@</p>", escaped]];
        }
    }
    return [paragraphs componentsJoinedByString:@""];
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
    [self saveDraft];
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
    CGFloat tagInsetSpacing = 12;
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (HORIZONTAL_PADDING * 2); // 屏幕宽度减去左右边距
    
    // 根据标签数量更新按钮文案 - 统一显示"标签"
    NSString *buttonTitle = @"标签";
    [self.addTagButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    // 计算按钮宽度 - 文本宽度 + 图标宽度 + 间距 + 左右各10像素的间距
    UIFont *buttonFont = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    CGSize buttonTextSize = [buttonTitle sizeWithAttributes:@{NSFontAttributeName: buttonFont}];
    CGFloat iconWidth = 14; // 图标宽度
    CGFloat iconSpacing = 8; // 图标和文字之间的总间距 (左右各4)
    CGFloat buttonWidth = buttonTextSize.width + iconWidth + iconSpacing + (tagInsetSpacing * 2); // 文本 + 图标 + 图标间距 + 左右各tagInsetSpacing像素的间距

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
        tagView.backgroundColor = [UIColor colorWithRed:218.0/255.0 green:129.0/255.0 blue:68.0/255.0 alpha:0.08];
        tagView.layer.cornerRadius = TAG_DEFAULT_HEIGHT / 2;
        tagView.layer.borderColor = [UIColor colorWithRed:218.0/255.0 green:129.0/255.0 blue:68.0/255.0 alpha:1.0].CGColor;
        tagView.layer.borderWidth = 1;

        // 创建标签文本
        UILabel *tagLabel = [[UILabel alloc] init];
        tagLabel.text = tagName;
        tagLabel.font = font;
        tagLabel.textColor = [UIColor colorWithRed:218.0/255.0 green:129.0/255.0 blue:68.0/255.0 alpha:1.0];
        
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
        [deleteButton setTintColor:[UIColor colorWithRed:218.0/255.0 green:129.0/255.0 blue:68.0/255.0 alpha:1.0]];
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
    [self updateClearButtonVisibility];
}

// 删除标签
- (void)deleteTag:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.tags.count) {
        [self.tags removeObjectAtIndex:index];
        [self refreshTagsDisplay]; // 刷新标签显示
        [self saveDraft];
    }
}

// 更新标签布局
- (void)updateTagsLayout {
    [self.tagContainerView layoutIfNeeded];

    // 如果链接输入框已经显示，确保它与标签容器保持正确的间距
    if (self.linkFieldVisible && !self.linkField.hidden) {
        [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagContainerView.mas_bottom).offset(VERTICAL_SPACING);
        }];
    }
}

- (void)gotoLoginPage {
    SLWebViewController *dvc = [[SLWebViewController alloc] init];
    [dvc startLoadRequestWithUrl:LOGIN_PAGE_URL];
    dvc.hidesBottomBarWhenPushed = YES;
    dvc.isLoginPage = YES;
    [self presentViewController:dvc animated:YES completion:nil];
}

#pragma mark - Link Validation
// 验证链接的方法
- (void)validateLinkField {
    NSString *linkText = [self.linkField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL isValidLink = [self isValidURL:linkText];

    // Show/Hide Warning
    self.linkWarningLabel.hidden = (linkText.length == 0 || isValidLink);

    [self updateLinkFieldHeight];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.textView) {
        [self updateTextViewHeight];

        UILabel *placeholderLabel = [self.textView viewWithTag:997];
        placeholderLabel.hidden = textView.text.length > 0;
        [self saveDraft];
        [self updateClearButtonVisibility];
    } else if (textView == self.titleField) {
        // 标题输入框
        [self updateTitleFieldHeight];

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

        // 更新 placeholder 显示
        UILabel *placeholderLabel = [textView viewWithTag:998];
        placeholderLabel.hidden = textView.text.length > 0;

        [self saveDraft];
        [self updateClearButtonVisibility];
    } else if (textView == self.linkField) {
        // 链接输入框
        [self updateLinkFieldHeight];

        // 取消之前的定时器
        [self.linkValidationTimer invalidate];
        self.linkValidationTimer = nil;

        // 如果输入框为空，立即隐藏警告
        NSString *linkText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (linkText.length == 0) {
            self.linkWarningLabel.hidden = YES;
            [self updateLinkFieldHeight];
        } else {
            // 延迟0.8秒后再验证链接
            self.linkValidationTimer = [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(validateLinkField) userInfo:nil repeats:NO];
        }

        // 更新 placeholder 显示
        UILabel *placeholderLabel = [textView viewWithTag:996];
        placeholderLabel.hidden = textView.text.length > 0;

        [self saveDraft];
        [self updateClearButtonVisibility];
    }
}

#pragma mark - UITextField Delegate (仅用于标签输入)
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // 标签输入框
}

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

- (UIButton *)clearButton {
    if (!_clearButton) {
        _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageSymbolConfiguration *trashConfig = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        UIImage *trashIcon = [UIImage systemImageNamed:@"trash" withConfiguration:trashConfig];
        [_clearButton setImage:trashIcon forState:UIControlStateNormal];
        [_clearButton setTintColor:[SLColorManager recorderTextColor]];
        [_clearButton addTarget:self action:@selector(clearAllContent) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.hidden = YES; // 初始隐藏
    }
    return _clearButton;
}

- (UIButton *)commitButton {
    if (!_commitButton) {
        _commitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_commitButton setTitle:@"发帖" forState:UIControlStateNormal];
        _commitButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        [_commitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _commitButton.backgroundColor = [UIColor colorWithRed:73.0/255.0 green:119.0/255.0 blue:73.0/255.0 alpha:1.0];
        _commitButton.layer.cornerRadius = 16;
        _commitButton.layer.masksToBounds = YES;
        _commitButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        [_commitButton addTarget:self action:@selector(commitBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commitButton;
}

- (UIScrollView *)contentView {
    if (!_contentView) {
        _contentView = [[UIScrollView alloc] init];
        _contentView.backgroundColor = UIColor.clearColor;
        _contentView.showsVerticalScrollIndicator = NO;
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


- (UITextView *)titleField {
    if (!_titleField) {
        _titleField = [[UITextView alloc] init];
        _titleField.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        _titleField.textColor = [SLColorManager recorderTextColor];
        _titleField.tintColor = [SLColorManager themeColor]; // 光标颜色改为主题绿色
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.delegate = self;
        _titleField.returnKeyType = UIReturnKeyNext;
        _titleField.scrollEnabled = NO; // 禁用滚动，让高度自动增长

        // 移除默认内边距
        _titleField.textContainerInset = UIEdgeInsetsZero;
        _titleField.textContainer.lineFragmentPadding = 0;

        // 添加 placeholder - 使用 UILabel
        UILabel *placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.text = @"添加标题";
        placeholderLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        placeholderLabel.textColor = [UIColor lightGrayColor];
        placeholderLabel.tag = 998; // 使用 tag 标识
        [_titleField addSubview:placeholderLabel];
        [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(_titleField);
        }];
    }
    return _titleField;
}

- (UITextView *)linkField {
    if (!_linkField) {
        _linkField = [[UITextView alloc] init];
        _linkField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _linkField.textColor = [UIColor colorWithRed:46.0/255.0 green:92.0/255.0 blue:184.0/255.0 alpha:1.0]; // #2E5CB8
        _linkField.backgroundColor = [UIColor clearColor];
        _linkField.delegate = self;
        _linkField.returnKeyType = UIReturnKeyGo;
        _linkField.keyboardType = UIKeyboardTypeASCIICapable; // 强制英文键盘
        _linkField.autocapitalizationType = UITextAutocapitalizationTypeNone; // 不自动大写
        _linkField.autocorrectionType = UITextAutocorrectionTypeNo; // 不自动纠错
        _linkField.scrollEnabled = NO;
        _linkField.tintColor = [SLColorManager themeColor];

        // 移除默认内边距
        _linkField.textContainerInset = UIEdgeInsetsZero;
        _linkField.textContainer.lineFragmentPadding = 0;

        // 添加 placeholder
        UILabel *placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.text = @"链接";
        placeholderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        placeholderLabel.textColor = [UIColor lightGrayColor];
        placeholderLabel.tag = 996;
        [_linkField addSubview:placeholderLabel];
        [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(_linkField);
        }];
    }
    return _linkField;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _textView.tintColor = [SLColorManager themeColor]; // 光标颜色改为主题绿色
        _textView.delegate = self;
        _textView.scrollEnabled = NO;
        _textView.returnKeyType = UIReturnKeyDefault;

        // 设置字体排印：字号17pt
        UIFont *contentFont = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 8; // 行间距
        paragraphStyle.paragraphSpacing = 16; // 段落间距（换行后的额外间距）

        _textView.font = contentFont;
        _textView.textColor = [SLColorManager cellTitleColor];
        _textView.typingAttributes = @{
            NSFontAttributeName: contentFont,
            NSForegroundColorAttributeName: [SLColorManager cellTitleColor],
            NSParagraphStyleAttributeName: paragraphStyle
        };

        // 移除默认内边距，使文字位置与标题输入框对齐
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;

        [self setupContentPlaceholder];
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
        [_addTagButton setTitle:@"标签" forState:UIControlStateNormal];
        [_addTagButton setTitleColor:[UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0] forState:UIControlStateNormal]; // #666666 深灰色
        _addTagButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _addTagButton.backgroundColor = [UIColor colorWithRed:249.0/255.0 green:248.0/255.0 blue:246.0/255.0 alpha:1.0]; // #F9F8F6 米白色背景
        _addTagButton.layer.cornerRadius = TAG_DEFAULT_HEIGHT / 2;
        _addTagButton.layer.borderWidth = 1.0;
        _addTagButton.layer.borderColor = [UIColor colorWithRed:224.0/255.0 green:224.0/255.0 blue:224.0/255.0 alpha:1.0].CGColor; // #E0E0E0 淡灰边框

        // 设置 SF Symbol plus 图标
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
        UIImage *plusIcon = [UIImage systemImageNamed:@"plus" withConfiguration:config];
        [_addTagButton setImage:plusIcon forState:UIControlStateNormal];
        _addTagButton.tintColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0]; // #666666 深灰色

        // 设置图标和文字之间的间距
        _addTagButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 4);
        _addTagButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);

        [_addTagButton addTarget:self action:@selector(showTagInput) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addTagButton;
}

- (UITextField *)tagInputField {
    if (!_tagInputField) {
        _tagInputField = [[UITextField alloc] init];
        _tagInputField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _tagInputField.textColor = [SLColorManager recorderTagTextColor];
        _tagInputField.tintColor = [SLColorManager themeColor]; // 光标颜色改为主题绿色
        _tagInputField.backgroundColor = UIColor.clearColor;
        _tagInputField.returnKeyType = UIReturnKeyDone;
        _tagInputField.delegate = self;
        _tagInputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, TAG_DEFAULT_HEIGHT)];
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
    placeholderLabel.text = @"写文字";
    placeholderLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular]; // 与正文字号保持一致
    placeholderLabel.textColor = [UIColor lightGrayColor];
    placeholderLabel.hidden = NO;
    placeholderLabel.tag = 997;
    [self.textView addSubview:placeholderLabel];
    [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView);
        make.left.equalTo(self.textView);
    }];
}

- (void)setupAccessoryView {
    self.accessoryView = [[UIView alloc] init];
    self.accessoryView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.accessoryView];

    [self.accessoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.view).offset(-HORIZONTAL_PADDING);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-8);
        make.height.mas_equalTo(44);
    }];

    // 添加顶部分割线 - 细且淡的设计，横跨整个屏幕宽度
    UIView *topSeparator = [[UIView alloc] init];
    topSeparator.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.6]; // 淡灰色，半透明
    [self.view addSubview:topSeparator];
    [topSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view); // 横跨整个屏幕宽度
        make.top.equalTo(self.accessoryView.mas_top);
        make.height.mas_equalTo(0.5); // 0.5pt 细线
    }];

    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.accessoryView.mas_top);
    }];

    UIButton *linkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *linkConfig = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    [linkBtn setImage:[UIImage systemImageNamed:@"link" withConfiguration:linkConfig] forState:UIControlStateNormal];
    [linkBtn setTintColor:Color16(0x333333)];
    linkBtn.imageView.contentMode = UIViewContentModeScaleAspectFit; // 保持等比例缩放
    [linkBtn addTarget:self action:@selector(showLinkField) forControlEvents:UIControlEventTouchUpInside];
    [self.accessoryView addSubview:linkBtn];
    [linkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.accessoryView).offset(3);
        make.centerY.equalTo(self.accessoryView);
        make.width.height.mas_equalTo(22);
    }];

    UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    [imageBtn setImage:[UIImage systemImageNamed:@"photo" withConfiguration:imageConfig] forState:UIControlStateNormal];
    [imageBtn setTintColor:Color16(0x333333)];
    imageBtn.imageView.contentMode = UIViewContentModeScaleAspectFit; // 保持等比例缩放
    [imageBtn addTarget:self action:@selector(addImage) forControlEvents:UIControlEventTouchUpInside];
    [self.accessoryView addSubview:imageBtn];
    [imageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(linkBtn.mas_right).offset(24);
        make.centerY.equalTo(self.accessoryView);
        make.width.height.mas_equalTo(22);
    }];

    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneBtn setTitle:@"收起" forState:UIControlStateNormal];
    doneBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [doneBtn setTitleColor:Color16(0x333333) forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
    doneBtn.hidden = YES; // 初始隐藏
    self.dismissKeyboardButton = doneBtn;
    [self.accessoryView addSubview:doneBtn];
    [doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.accessoryView).offset(4);
        make.centerY.equalTo(self.accessoryView).offset(2);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(44);
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGFloat keyboardHeight = keyboardFrame.size.height;
    CGFloat safeAreaBottom = self.view.safeAreaInsets.bottom;
    CGFloat offset = -(keyboardHeight - safeAreaBottom);

    [self.accessoryView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(offset);
    }];

    // 显示收起按钮
    self.dismissKeyboardButton.hidden = NO;

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.accessoryView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-8);
    }];

    // 隐藏收起按钮
    self.dismissKeyboardButton.hidden = YES;

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)showLinkField {
    // 切换逻辑：如果已显示则隐藏
    if (self.linkFieldVisible) {
        [self hideLinkField];
        return;
    }

    self.linkFieldVisible = YES;
    self.linkField.hidden = NO;
    self.linkCloseButton.hidden = NO;
    self.linkFieldContentHeight = FIELD_DEFAULT_HEIGHT;

    // 先聚焦，让键盘开始弹起
    [self.linkField becomeFirstResponder];

    // 使用 mas_updateConstraints 只更新需要变化的约束，性能更好
    [self.linkField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagContainerView.mas_bottom).offset(VERTICAL_SPACING);
        make.height.mas_equalTo(FIELD_DEFAULT_HEIGHT);
    }];

    // 使用动画让过渡更平滑
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // 滚动到 linkField 可见位置
        CGRect frameInScrollView = [self.linkField.superview convertRect:self.linkField.frame toView:self.contentView];
        [self.contentView scrollRectToVisible:frameInScrollView animated:YES];
    }];
}

- (void)hideLinkField {
    self.linkFieldVisible = NO;
    self.linkField.hidden = YES;
    self.linkCloseButton.hidden = YES;
    self.linkWarningLabel.hidden = YES;
    [self.linkField resignFirstResponder];
    self.linkField.text = @"";

    // 显示 placeholder
    UILabel *placeholderLabel = [self.linkField viewWithTag:996];
    placeholderLabel.hidden = NO;

    // 恢复初始约束
    [self.linkField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagContainerView.mas_bottom).offset(0);
        make.left.equalTo(self.containerView).offset(HORIZONTAL_PADDING);
        make.right.equalTo(self.containerView).offset(-HORIZONTAL_PADDING - 32); // 为关闭按钮留出空间
        make.height.mas_equalTo(0);
    }];

    [self.linkWarningLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
        make.top.equalTo(self.linkField.mas_bottom).offset(0);
    }];

    [self.view layoutIfNeeded];
}

- (void)addImage {
    TZImagePickerController *picker = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:nil];
    picker.allowPickingVideo = NO;
    picker.allowTakePicture = NO;
    picker.allowPreview = YES;
    picker.allowPickingOriginalPhoto = NO; // 隐藏原图选项
    picker.isSelectOriginalPhoto = YES; // 默认选择原图（高清图）
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    @weakobj(self)
    [picker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        @strongobj(self)
        if (photos.count > 0) {
            for (UIImage *img in photos) {
                NSMutableDictionary *item = [@{@"image": img} mutableCopy];
                [self.selectedImages addObject:item];
            }
            [self refreshImagesDisplay];

            for (UIImage *img in photos) {
                [self uploadPendingImage:img];
            }
        }
    }];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)refreshImagesDisplay {
    // Clear existing image views
    [self.imagesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (self.selectedImages.count == 0) {
        self.imagesScrollView.hidden = YES;
        [self.imagesScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
            make.top.equalTo(self.linkField.mas_bottom).offset(0); // 隐藏时上边距为0
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

    // 恢复上边距，保证与前一个元素的间距为 24px
    [self.imagesScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.linkField.mas_bottom).offset(VERTICAL_SPACING);
    }];
    CGFloat imageHeight = 300;
    CGFloat padding = 0;
    CGFloat scrollWidth = kScreenWidth;
    CGFloat currentX = 0;
    
    for (int i = 0; i < self.selectedImages.count; i++) {
        NSDictionary *item = self.selectedImages[i];
        UIImage *displayImage = item[@"image"];
        NSString *urlString = item[@"url"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(currentX, 0, scrollWidth, imageHeight)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 0;
        imageView.userInteractionEnabled = YES;
        imageView.tag = i;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [imageView addGestureRecognizer:tap];
        
        if (displayImage) {
            imageView.image = displayImage;
            if (urlString.length == 0) {
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                spinner.center = CGPointMake(scrollWidth / 2, imageHeight / 2);
                spinner.color = [UIColor whiteColor];
                [spinner startAnimating];
                [imageView addSubview:spinner];
            }
        } else if (urlString.length > 0) {
            imageView.backgroundColor = [UIColor lightGrayColor];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
                if (!data) return;
                UIImage *downloaded = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = downloaded;
                    NSMutableDictionary *updated = [item mutableCopy];
                    if (downloaded) {
                        updated[@"image"] = downloaded;
                        self.selectedImages[i] = updated;
                    }
                });
            });
        } else {
            imageView.backgroundColor = [UIColor lightGrayColor];
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
            make.height.mas_equalTo(18); // 更小的高度
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
    [self updateClearButtonVisibility];
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
    [self saveDraft];
}

- (void)deleteAllImages {
    [self.selectedImages removeAllObjects];
    [self refreshImagesDisplay];
    [self saveDraft];
}

- (void)imageTapped:(UITapGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    if (![view isKindOfClass:[UIImageView class]]) return;
    NSInteger index = view.tag;
    self.selectedImageIndex = index;
    self.pageControl.currentPage = index;

    // 打开图片预览
    [self previewImageAtIndex:index];
}

- (void)previewImageAtIndex:(NSInteger)index {
    // 收集所有图片
    NSMutableArray *photos = [NSMutableArray array];
    for (NSDictionary *item in self.selectedImages) {
        UIImage *image = item[@"image"];
        if (image) {
            [photos addObject:image];
        }
    }

    if (photos.count == 0) return;

    // 创建一个简单的全屏预览控制器
    UIViewController *previewVC = [[UIViewController alloc] init];
    previewVC.view.backgroundColor = [UIColor blackColor];
    previewVC.modalPresentationStyle = UIModalPresentationFullScreen;

    // 创建滚动视图
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [previewVC.view addSubview:scrollView];

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

    // 添加所有图片
    for (int i = 0; i < photos.count; i++) {
        UIImage *image = photos[i];

        // 创建滚动容器（用于缩放）
        UIScrollView *zoomScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(i * screenWidth, 0, screenWidth, screenHeight)];
        zoomScrollView.minimumZoomScale = 1.0;
        zoomScrollView.maximumZoomScale = 3.0;
        zoomScrollView.showsVerticalScrollIndicator = NO;
        zoomScrollView.showsHorizontalScrollIndicator = NO;
        zoomScrollView.delegate = self;

        // 创建图片视图
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.tag = 1000 + i; // 用于在delegate中识别

        // 计算图片尺寸以适应屏幕
        CGSize imageSize = image.size;
        CGFloat aspectRatio = imageSize.width / imageSize.height;
        CGFloat displayWidth, displayHeight;

        if (aspectRatio > screenWidth / screenHeight) {
            // 横图
            displayWidth = screenWidth;
            displayHeight = screenWidth / aspectRatio;
        } else {
            // 竖图或方图
            displayHeight = screenHeight;
            displayWidth = screenHeight * aspectRatio;
        }

        imageView.frame = CGRectMake((screenWidth - displayWidth) / 2,
                                     (screenHeight - displayHeight) / 2,
                                     displayWidth,
                                     displayHeight);

        [zoomScrollView addSubview:imageView];
        zoomScrollView.contentSize = imageView.frame.size;
        [scrollView addSubview:zoomScrollView];
    }

    scrollView.contentSize = CGSizeMake(screenWidth * photos.count, screenHeight);

    // 滚动到当前选中的图片
    if (index < photos.count) {
        [scrollView setContentOffset:CGPointMake(index * screenWidth, 0) animated:NO];
    }

    // 添加关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageSymbolConfiguration *closeConfig = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
    [closeButton setImage:[[UIImage systemImageNamed:@"xmark" withConfiguration:closeConfig] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [closeButton setTintColor:[UIColor whiteColor]];
    closeButton.frame = CGRectMake(16, 50, 40, 40);
    [closeButton addTarget:self action:@selector(dismissPreview) forControlEvents:UIControlEventTouchUpInside];
    [previewVC.view addSubview:closeButton];

    // 添加页码指示器（如果有多张图片）
    if (photos.count > 1) {
        UILabel *pageLabel = [[UILabel alloc] init];
        pageLabel.textColor = [UIColor whiteColor];
        pageLabel.font = [UIFont systemFontOfSize:14];
        pageLabel.textAlignment = NSTextAlignmentCenter;
        pageLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)(index + 1), (long)photos.count];
        pageLabel.frame = CGRectMake(0, 50, screenWidth, 40);
        pageLabel.tag = 2000; // 用于更新页码
        [previewVC.view addSubview:pageLabel];

        // 监听滚动以更新页码
        scrollView.delegate = self;
        objc_setAssociatedObject(scrollView, "pageLabel", pageLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(scrollView, "photosCount", @(photos.count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // 添加点击手势关闭
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPreview)];
    [scrollView addGestureRecognizer:tapGesture];

    [self presentViewController:previewVC animated:YES completion:nil];
}

- (void)dismissPreview {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.imagesScrollView) {
        CGFloat width = scrollView.bounds.size.width;
        if (width > 0) {
            NSInteger page = (NSInteger)round(scrollView.contentOffset.x / width);
            if (page >= 0 && page < self.selectedImages.count) {
                self.pageControl.currentPage = page;
            }
        }
    } else {
        // 图片预览页面的滚动
        UILabel *pageLabel = objc_getAssociatedObject(scrollView, "pageLabel");
        NSNumber *photosCount = objc_getAssociatedObject(scrollView, "photosCount");

        if (pageLabel && photosCount) {
            CGFloat width = scrollView.bounds.size.width;
            if (width > 0) {
                NSInteger currentPage = (NSInteger)round(scrollView.contentOffset.x / width);
                pageLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)(currentPage + 1), (long)[photosCount integerValue]];
            }
        }
    }
}

// 支持图片缩放
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // 返回需要缩放的视图（图片视图）
    for (UIView *subview in scrollView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            return subview;
        }
    }
    return nil;
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
        _imageDeleteOverlayButton.layer.cornerRadius = 14;
        _imageDeleteOverlayButton.layer.masksToBounds = YES;

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleMedium];
        [_imageDeleteOverlayButton setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:config] forState:UIControlStateNormal];
        _imageDeleteOverlayButton.tintColor = [UIColor whiteColor];

        [_imageDeleteOverlayButton addTarget:self action:@selector(deleteCurrentImage) forControlEvents:UIControlEventTouchUpInside];
        _imageDeleteOverlayButton.hidden = YES;
    }
    return _imageDeleteOverlayButton;
}

- (NSString *)currentDraftKey {
    if (self.isEdit && self.articleId.length > 0) {
        return [NSString stringWithFormat:@"SLRecordDraft_Update_%@", self.articleId];
    }
    return @"SLRecordDraft_Create";
}

- (NSString *)draftImagesDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = paths.firstObject;
    NSString *dir = [cacheDir stringByAppendingPathComponent:@"RecordDraftImages"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (NSString *)saveImageToCache:(UIImage *)image {
    if (!image) return nil;
    NSData *data = UIImageJPEGRepresentation(image, 0.85);
    if (!data) return nil;
    NSString *filename = [[NSUUID UUID].UUIDString stringByAppendingString:@".jpg"];
    NSString *path = [[self draftImagesDir] stringByAppendingPathComponent:filename];
    [data writeToFile:path atomically:YES];
    return path;
}

- (void)saveDraft {
    NSMutableDictionary *draft = [NSMutableDictionary dictionary];
    draft[@"title"] = self.titleField.text ?: @"";
    draft[@"link"] = self.linkField.text ?: @"";
    draft[@"content"] = self.textView.text ?: @"";
    draft[@"tags"] = self.tags ?: @[];
    
    NSMutableArray *imageItems = [NSMutableArray array];
    for (NSDictionary *item in self.selectedImages) {
        NSString *url = item[@"url"];
        UIImage *img = item[@"image"];
        NSMutableDictionary *store = [NSMutableDictionary dictionary];
        if (url.length > 0) {
            store[@"url"] = url;
        }
        if (img && url.length == 0) {
            NSString *path = [self saveImageToCache:img];
            if (path) {
                store[@"localPath"] = path;
            }
        }
        if (store.count > 0) {
            [imageItems addObject:store];
        }
    }
    draft[@"images"] = imageItems;
    
    NSString *key = [self currentDraftKey];
    [[NSUserDefaults standardUserDefaults] setObject:draft forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadDraft {
    NSString *key = [self currentDraftKey];
    NSDictionary *draft = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!draft) return;
    
    NSString *title = draft[@"title"];
    NSString *link = draft[@"link"];
    NSString *content = draft[@"content"];
    NSArray *tags = draft[@"tags"];
    NSArray *images = draft[@"images"];
    
    if (title.length > 0) {
        self.titleField.text = title;
        [self textViewDidChange:self.titleField];
    }
    if (link.length > 0) {
        self.linkField.text = link;
        [self showLinkField];
        [self textViewDidChange:self.linkField];
    }
    if (content.length > 0) {
        self.textView.text = content;
        UILabel *textViewPlaceholder = [self.textView viewWithTag:997];
        textViewPlaceholder.hidden = content.length > 0;
    }
    
    if (tags.count > 0) {
        [self.tags removeAllObjects];
        [self.tags addObjectsFromArray:tags];
        [self refreshTagsDisplay];
        [self updateTagsLayout];
    }
    
    if (images.count > 0) {
        for (NSDictionary *it in images) {
            NSString *url = it[@"url"];
            NSString *localPath = it[@"localPath"];
            NSMutableDictionary *compose = [NSMutableDictionary dictionary];
            if (url.length > 0) compose[@"url"] = url;
            if (localPath.length > 0) {
                UIImage *img = [UIImage imageWithContentsOfFile:localPath];
                if (img) compose[@"image"] = img;
            }
            if (compose.count > 0) {
                [self.selectedImages addObject:compose];
            }
        }
        [self refreshImagesDisplay];
        for (NSDictionary *it in self.selectedImages) {
            UIImage *img = it[@"image"];
            NSString *url = it[@"url"];
            if (img && url.length == 0) {
                [self uploadPendingImage:img];
            }
        }
    }
    [self updateClearButtonVisibility];
}

- (void)clearDraft {
    NSString *key = [self currentDraftKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)appDidEnterBackground {
    [self saveDraft];
}

- (void)dealloc {
    // 清理定时器
    [self.linkValidationTimer invalidate];
    self.linkValidationTimer = nil;

    [self.commitTimeoutTimer invalidate];
    self.commitTimeoutTimer = nil;
}

@end
