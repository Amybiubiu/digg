//
//  SLAddLinkViewController.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLAddLinkViewController.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "UIView+SLToast.h"
#import "SLGeneralMacro.h"

@interface SLAddLinkViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UITextField *linkTextField;
@property (nonatomic, strong) UIView *inputSeparator;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *buttonSeparator;
@property (nonatomic, strong) UIView *verticalSeparator;

@end

@implementation SLAddLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = Color16(0xF2F2F2);
    self.containerView.layer.cornerRadius = 12.0;
    self.containerView.clipsToBounds = YES;
    [self.view addSubview:self.containerView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"添加链接";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.containerView addSubview:self.titleLabel];
    
    // 输入框容器视图 - 修改背景色为输入框颜色
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.backgroundColor = [UIColor whiteColor];
    self.inputContainerView.layer.cornerRadius = 8.0;
    self.inputContainerView.clipsToBounds = YES;
    self.inputContainerView.layer.borderColor = Color16(0xDFDFDF).CGColor;
    self.inputContainerView.layer.borderWidth = 1;
    [self.containerView addSubview:self.inputContainerView];
    
    // 标题输入框 - 设置白色背景
    self.titleTextField = [[UITextField alloc] init];
    self.titleTextField.placeholder = @"标题";
    self.titleTextField.borderStyle = UITextBorderStyleNone;
    self.titleTextField.font = [UIFont systemFontOfSize:16];
    self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.titleTextField.backgroundColor = [UIColor clearColor];
    self.titleTextField.layer.cornerRadius = 6.0;
    self.titleTextField.clipsToBounds = YES;
    [self.inputContainerView addSubview:self.titleTextField];
    
    // 输入框分隔线
    self.inputSeparator = [[UIView alloc] init];
    self.inputSeparator.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [self.inputContainerView addSubview:self.inputSeparator];
    
    // 链接输入框 - 设置白色背景
    self.linkTextField = [[UITextField alloc] init];
    self.linkTextField.placeholder = @"链接";
    self.linkTextField.borderStyle = UITextBorderStyleNone;
    self.linkTextField.font = [UIFont systemFontOfSize:16];
    self.linkTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.linkTextField.keyboardType = UIKeyboardTypeURL;
    self.linkTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.linkTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.linkTextField.backgroundColor = [UIColor clearColor];
    self.linkTextField.layer.cornerRadius = 6.0;
    self.linkTextField.clipsToBounds = YES;
    [self.inputContainerView addSubview:self.linkTextField];
    
    // 按钮分隔线
    self.buttonSeparator = [[UIView alloc] init];
    self.buttonSeparator.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:self.buttonSeparator];
    
    // 确认按钮
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.confirmButton];
    
    // 取消按钮
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.cancelButton];

    // 按钮之间的垂直分割线
    self.verticalSeparator = [[UIView alloc] init];
    self.verticalSeparator.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:self.verticalSeparator];
    
    // 设置约束
    [self setupConstraints];
    
    // 添加点击背景关闭的手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)setupConstraints {
    // 容器视图约束 - 增加高度以适应更高的按钮
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.8);
        make.height.mas_equalTo(200);
    }];
    
    // 标题约束
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(15);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(20);
    }];
    
    // 输入框容器约束
    [self.inputContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(15);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(88); // 增加高度以适应圆角输入框
    }];
    
    // 标题输入框约束 - 调整边距以适应圆角
    [self.titleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputContainerView);
        make.left.equalTo(self.inputContainerView).offset(5);
        make.right.equalTo(self.inputContainerView).offset(-5);
        make.height.mas_equalTo(42.5);
    }];
    
    // 输入框分隔线约束
    [self.inputSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleTextField.mas_bottom);
        make.left.equalTo(self.inputContainerView);
        make.right.equalTo(self.inputContainerView);
        make.height.mas_equalTo(0.5);
    }];
    
    // 链接输入框约束 - 调整边距以适应圆角
    [self.linkTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputSeparator.mas_bottom);
        make.left.equalTo(self.inputContainerView).offset(5);
        make.right.equalTo(self.inputContainerView).offset(-5);
        make.height.mas_equalTo(42.5);
    }];
    
    // 按钮分隔线约束
    [self.buttonSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputContainerView.mas_bottom).offset(15);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0.5);
    }];
    
    // 按钮约束 - 增加按钮高度
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonSeparator.mas_bottom);
        make.left.equalTo(self.containerView);
        make.right.equalTo(self.containerView.mas_centerX).offset(-0.5);
        make.bottom.equalTo(self.containerView);
        make.height.mas_equalTo(50);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonSeparator.mas_bottom);
        make.left.equalTo(self.containerView.mas_centerX).offset(0.5);
        make.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView);
        make.height.mas_equalTo(50);
    }];
    
    // 垂直分割线约束
    [self.verticalSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonSeparator.mas_bottom);
        make.centerX.equalTo(self.containerView);
        make.width.mas_equalTo(0.5);
        make.bottom.equalTo(self.containerView);
    }];
}

#pragma mark - Actions

- (void)confirmButtonTapped {
    NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *link = [self.linkTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (title.length == 0) {
        [self.view sl_showToast:@"请输入标题"];
        return;
    }
    
    if (link.length == 0) {
        [self.view sl_showToast:@"请输入链接"];
        return;
    }
    
    // 验证链接格式
    if (![self isValidURL:link]) {
        [self.view sl_showToast:@"请输入有效的链接"];
        return;
    }
    
    if (self.submitHandler) {
        self.submitHandler(title, link);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.view];
    if (!CGRectContainsPoint(self.containerView.frame, point)) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Helper Methods

- (BOOL)isValidURL:(NSString *)urlString {
    // 简单的URL验证
    NSURL *url = [NSURL URLWithString:urlString];
    return (url && url.scheme && url.host);
}

#pragma mark - Public Methods

- (void)showInViewController:(UIViewController *)viewController {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [viewController presentViewController:self animated:YES completion:nil];
}

@end
