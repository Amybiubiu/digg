//
//  SLCustomAlertView.m
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import "SLCustomAlertView.h"
#import "SLColorManager.h"

@interface SLCustomAlertView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *buttonSeparator;
@property (nonatomic, strong) UIView *horizontalSeparator;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;

@property (nonatomic, copy) SLCustomAlertActionHandler confirmHandler;
@property (nonatomic, copy) SLCustomAlertActionHandler cancelHandler;

@property (nonatomic, assign) BOOL confirmOnRight;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *urlText;

@end

@implementation SLCustomAlertView

#pragma mark - 初始化方法

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                      confirmTitle:(NSString *)confirmTitle
                       cancelTitle:(NSString *)cancelTitle
                    confirmHandler:(SLCustomAlertActionHandler)confirmHandler
                     cancelHandler:(SLCustomAlertActionHandler)cancelHandler {
    
    SLCustomAlertView *alertView = [[SLCustomAlertView alloc] initWithTitle:title
                                                                    message:message
                                                               confirmTitle:confirmTitle
                                                                cancelTitle:cancelTitle
                                                             confirmHandler:confirmHandler
                                                              cancelHandler:cancelHandler];
    [alertView show];
    return alertView;
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                 confirmTitle:(NSString *)confirmTitle
                  cancelTitle:(NSString *)cancelTitle
               confirmHandler:(SLCustomAlertActionHandler)confirmHandler
                cancelHandler:(SLCustomAlertActionHandler)cancelHandler {
    
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.confirmHandler = confirmHandler;
        self.cancelHandler = cancelHandler;
        self.confirmOnRight = NO; // 默认确认按钮在右侧
        
        // 设置容器视图
        [self setupContainerView];
        
        // 设置标题
        [self setupTitleLabelWithText:title];
        
        // 设置消息
        [self setupMessageLabelWithText:message];
        
        // 设置按钮
        [self setupButtonsWithConfirmTitle:confirmTitle cancelTitle:cancelTitle];
        
        // 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
        tapGesture.delegate = self;
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

#pragma mark - 视图设置

- (void)setupContainerView {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor systemBackgroundColor];
    self.containerView.layer.cornerRadius = 16.0;
    self.containerView.layer.masksToBounds = YES;
    [self addSubview:self.containerView];
    
    // 设置容器视图约束
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.containerView.widthAnchor constraintEqualToConstant:270],
        [self.containerView.heightAnchor constraintGreaterThanOrEqualToConstant:100]
    ]];
}

- (void)setupTitleLabelWithText:(NSString *)title {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont pingFangBoldWithSize:15];
    self.titleLabel.textColor = [SLColorManager primaryTextColor];
    self.titleLabel.numberOfLines = 0;
    [self.containerView addSubview:self.titleLabel];
    
    // 设置标题标签约束
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:20],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16]
    ]];
}

- (void)setupMessageLabelWithText:(NSString *)message {
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.text = message;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.font = [UIFont pingFangRegularWithSize:14];
    self.messageLabel.textColor = [UIColor systemBlueColor];
    self.messageLabel.numberOfLines = 0;
    [self.containerView addSubview:self.messageLabel];
    
    // 设置消息标签约束
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.messageLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16]
    ]];
    
    // 添加长按手势以支持复制
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.messageLabel addGestureRecognizer:longPressGesture];
    self.messageLabel.userInteractionEnabled = YES;
}

- (void)setupButtonsWithConfirmTitle:(NSString *)confirmTitle cancelTitle:(NSString *)cancelTitle {
    // 水平分隔线
    self.horizontalSeparator = [[UIView alloc] init];
    self.horizontalSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.containerView addSubview:self.horizontalSeparator];
    
    self.horizontalSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.horizontalSeparator.topAnchor constraintEqualToAnchor:self.messageLabel.bottomAnchor constant:20],
        [self.horizontalSeparator.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.horizontalSeparator.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.horizontalSeparator.heightAnchor constraintEqualToConstant:0.5]
    ]];
    
    // 确认按钮
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont pingFangRegularWithSize:16];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.confirmButton];
    
    // 取消按钮
    if (cancelTitle) {
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        self.cancelButton.titleLabel.font = [UIFont pingFangRegularWithSize:16];
        [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:self.cancelButton];
        
        // 按钮分隔线
        self.buttonSeparator = [[UIView alloc] init];
        self.buttonSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [self.containerView addSubview:self.buttonSeparator];
        
        self.buttonSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    // 更新按钮布局
    [self updateButtonLayout];
    
    // 设置容器视图底部约束
    NSLayoutConstraint *bottomConstraint = [self.containerView.bottomAnchor constraintEqualToAnchor:self.confirmButton.bottomAnchor constant:8];
    [NSLayoutConstraint activateConstraints:@[bottomConstraint]];
}

- (void)updateButtonLayout {
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (self.cancelButton) {
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 清除现有约束
        [self.confirmButton removeFromSuperview];
        [self.cancelButton removeFromSuperview];
        [self.buttonSeparator removeFromSuperview];
        
        // 重新添加视图
        [self.containerView addSubview:self.confirmButton];
        [self.containerView addSubview:self.cancelButton];
        [self.containerView addSubview:self.buttonSeparator];
        
        // 设置按钮分隔线约束
        [NSLayoutConstraint activateConstraints:@[
            [self.buttonSeparator.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
            [self.buttonSeparator.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
            [self.buttonSeparator.widthAnchor constraintEqualToConstant:0.5],
            [self.buttonSeparator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor]
        ]];
        
        // 根据确认按钮位置设置约束
        if (self.confirmOnRight) {
            // 确认按钮在右侧
            [NSLayoutConstraint activateConstraints:@[
                [self.confirmButton.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
                [self.confirmButton.leadingAnchor constraintEqualToAnchor:self.buttonSeparator.trailingAnchor],
                [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
                [self.confirmButton.heightAnchor constraintEqualToConstant:38],
                
                [self.cancelButton.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
                [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
                [self.cancelButton.trailingAnchor constraintEqualToAnchor:self.buttonSeparator.leadingAnchor],
                [self.cancelButton.heightAnchor constraintEqualToConstant:38]
            ]];
        } else {
            // 确认按钮在左侧
            [NSLayoutConstraint activateConstraints:@[
                [self.confirmButton.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
                [self.confirmButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
                [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.buttonSeparator.leadingAnchor],
                [self.confirmButton.heightAnchor constraintEqualToConstant:38],
                
                [self.cancelButton.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
                [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.buttonSeparator.trailingAnchor],
                [self.cancelButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
                [self.cancelButton.heightAnchor constraintEqualToConstant:38]
            ]];
        }
    } else {
        // 只有确认按钮
        [NSLayoutConstraint activateConstraints:@[
            [self.confirmButton.topAnchor constraintEqualToAnchor:self.horizontalSeparator.bottomAnchor],
            [self.confirmButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
            [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
            [self.confirmButton.heightAnchor constraintEqualToConstant:38]
        ]];
    }
}

#pragma mark - 公共方法

- (void)setTitleFont:(UIFont *)font color:(UIColor *)color {
    self.titleLabel.font = font;
    self.titleLabel.textColor = color;
}

- (void)setMessageFont:(UIFont *)font color:(UIColor *)color {
    self.messageLabel.font = font;
    self.messageLabel.textColor = color;
}

- (void)setConfirmButtonFont:(UIFont *)font color:(UIColor *)color {
    self.confirmButton.titleLabel.font = font;
    [self.confirmButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)setCancelButtonFont:(UIFont *)font color:(UIColor *)color {
    self.cancelButton.titleLabel.font = font;
    [self.cancelButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)setConfirmButtonOnRight:(BOOL)onRight {
    self.confirmOnRight = onRight;
    [self updateButtonLayout];
}

- (void)setBackgroundColor:(UIColor *)color withAlpha:(CGFloat)alpha {
    self.backgroundColor = [color colorWithAlphaComponent:alpha];
}

- (void)setBackgroundBlurWithStyle:(UIBlurEffectStyle)style {
    if (self.blurEffectView) {
        [self.blurEffectView removeFromSuperview];
    }
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.frame = self.bounds;
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:self.blurEffectView atIndex:0];
}

- (void)setURL:(NSURL *)url withText:(NSString *)text {
    self.url = url;
    self.urlText = text;
    
    if (url && text) {
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:self.messageLabel.text ? self.messageLabel.text : @""];
        
        // 添加换行和URL文本
        if (self.messageLabel.text && self.messageLabel.text.length > 0) {
            [attributedMessage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
        }
        
        NSMutableAttributedString *urlString = [[NSMutableAttributedString alloc] initWithString:text];
        [urlString addAttribute:NSLinkAttributeName value:url range:NSMakeRange(0, text.length)];
        [urlString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(0, text.length)];
        
        [attributedMessage appendAttributedString:urlString];
        
        self.messageLabel.attributedText = attributedMessage;
    }
}

- (void)show {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    // 添加动画效果
    self.alpha = 0;
    self.containerView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
        self.containerView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - 事件处理

- (void)confirmButtonTapped {
    [self dismiss];
    if (self.confirmHandler) {
        self.confirmHandler();
    }
}

- (void)cancelButtonTapped {
    [self dismiss];
    if (self.cancelHandler) {
        self.cancelHandler();
    }
}

- (void)handleBackgroundTap:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    if (!CGRectContainsPoint(self.containerView.frame, location)) {
        [self dismiss];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        CGRect targetRect = [gesture.view convertRect:gesture.view.bounds toView:self];
        
        [menuController setTargetRect:targetRect inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.containerView]) {
        return NO;
    }
    return YES;
}

#pragma mark - 复制功能支持

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)copy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.messageLabel.text;
}

@end
