//
//  SLCommentInputViewController.m
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import "SLCommentInputViewController.h"
#import <Masonry/Masonry.h>
#import "SLColorManager.h"

@interface SLCommentInputViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UIButton *submitButton;

@end

@implementation SLCommentInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    // 创建白色背景视图
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.backgroundView];
    
    // 创建顶部分割线
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = [UIColor separatorColor];
    [self.backgroundView addSubview:self.separatorLine];
    
    // 创建灰色输入容器视图
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.backgroundColor = [SLColorManager textViewBgColor];
    self.inputContainerView.layer.cornerRadius = 8.0;
    [self.backgroundView addSubview:self.inputContainerView];
    
    // 创建文本输入框
    self.textView = [[UITextView alloc] init];
    self.textView.font = [UIFont pingFangRegularWithSize:12.0];
    self.textView.textColor = [SLColorManager textViewTextColor];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.scrollEnabled = YES;
    // 确保可以选择和编辑文本
    self.textView.selectable = YES;
    self.textView.editable = YES;

    self.textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.textView.textContainer.lineFragmentPadding = 0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 2.0; // 设置行间距
    self.textView.typingAttributes = @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: [UIFont pingFangRegularWithSize:12.0], NSForegroundColorAttributeName: [SLColorManager textViewTextColor]};
    // 添加键盘工具栏
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.barStyle = UIBarStyleDefault;
    [toolbar sizeToFit];
    
    // 创建完成按钮
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" 
                                                                   style:UIBarButtonItemStyleDone 
                                                                  target:self 
                                                                  action:@selector(doneButtonTapped)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil 
                                                                                   action:nil];
    toolbar.items = @[flexibleSpace, doneButton];
    self.textView.inputAccessoryView = toolbar;
    [self.inputContainerView addSubview:self.textView];
    
    // 创建占位符标签
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.font = [UIFont pingFangRegularWithSize:12.0];
    self.placeholderLabel.textColor = [SLColorManager textViewPlaceholderColor];
    self.placeholderLabel.text = self.placeholder ?: @"写回复";
    [self.inputContainerView addSubview:self.placeholderLabel];
    
    // 创建提交按钮
    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.submitButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.submitButton setTitleColor:[UIColor systemGrayColor] forState:UIControlStateDisabled];
    self.submitButton.titleLabel.font = [UIFont pingFangRegularWithSize:12.0];
    self.submitButton.hidden = YES; // 初始状态隐藏
    [self.submitButton addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.submitButton];
    
    // 设置约束
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.greaterThanOrEqualTo(@100);
    }];
    
    [self.separatorLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.backgroundView);
        make.height.equalTo(@0.5);
    }];
    
    [self.inputContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backgroundView).offset(10);
        make.right.equalTo(self.backgroundView).offset(-10);
        make.top.equalTo(self.backgroundView).offset(10);
        make.bottom.equalTo(self.backgroundView).offset(-10);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputContainerView).offset(5);
        make.right.equalTo(self.inputContainerView).offset(-5);
        make.top.equalTo(self.inputContainerView).offset(5);
        make.bottom.equalTo(self.submitButton.mas_top).offset(-5);
        make.height.greaterThanOrEqualTo(@45);
    }];
    
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textView).offset(1);
        make.top.equalTo(self.textView).offset(1);
        make.right.lessThanOrEqualTo(self.textView);
    }];
    
    // 修改发送按钮约束，使其位于输入框下方
    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.inputContainerView).offset(-8);
        make.bottom.equalTo(self.inputContainerView).offset(-8);
        make.width.equalTo(@40);
        make.height.equalTo(@25);
    }];
    
    // 添加键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // 添加点击背景关闭键盘的手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.textView setHidden:NO];
    [self.textView becomeFirstResponder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
}

#pragma mark - Public Methods

- (void)showInViewController:(UIViewController *)viewController {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [viewController presentViewController:self animated:YES completion:nil];
}

#pragma mark - Actions

- (void)doneButtonTapped {
    [self dismissKeyboard];
}

- (void)submitButtonTapped {
    if (self.submitHandler) {
        NSString *trimmedText = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.submitHandler(trimmedText);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.textView resignFirstResponder];
    if (self.cancelHandler) {
        self.cancelHandler(self.textView.text);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.backgroundView.transform = CGAffineTransformMakeTranslation(0, -keyboardFrame.size.height);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.backgroundView.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    BOOL hasText = textView.text.length > 0;
    self.placeholderLabel.hidden = hasText;
    self.submitButton.hidden = !hasText; // 根据是否有文本内容来显示或隐藏按钮
    
    // 自动调整高度
    CGFloat maxHeight = 200.0;
    CGSize size = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)];
    CGFloat newHeight = MIN(size.height, maxHeight);
    CGFloat minHeight = 45.0;
    newHeight = MAX(newHeight, minHeight);
    [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.greaterThanOrEqualTo(@(newHeight));
    }];
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self dismissKeyboard];
        return NO;
    }
    return YES;
}

@end
