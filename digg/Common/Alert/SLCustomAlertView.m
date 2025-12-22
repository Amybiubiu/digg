//
//  SLCustomAlertView.m
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import "SLCustomAlertView.h"
#import "SLColorManager.h"
#import "Masonry.h"

@interface SLCustomAlertView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *secondaryButton; // 中间按钮（浏览器打开）
@property (nonatomic, strong) UIView *buttonSeparator;
@property (nonatomic, strong) UIView *horizontalSeparator;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;

@property (nonatomic, copy) SLCustomAlertActionHandler confirmHandler;
@property (nonatomic, copy) SLCustomAlertActionHandler cancelHandler;
@property (nonatomic, copy) SLCustomAlertActionHandler browserHandler;

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

// 系统风格弹窗：标题+URL+三个纵向按钮
+ (instancetype)showSystemPopupForURL:(NSURL *)url
                       openInReader:(SLCustomAlertActionHandler)readerHandler
                      openInBrowser:(SLCustomAlertActionHandler)browserHandler
                        cancelHandler:(SLCustomAlertActionHandler)cancelHandler {
    // 作为包装方法，调用通用接口
    return [SLCustomAlertView showSystemStylePopupWithTitle:@"您确定要打开此链接吗？"
                                                       url:url
                                                   urlText:url.absoluteString
                                        primaryButtonTitle:@"阅读器打开"
                                      secondaryButtonTitle:@"浏览器打开"
                                           primaryHandler:readerHandler
                                         secondaryHandler:browserHandler
                                           cancelHandler:cancelHandler];
}

// 通用系统风格弹窗实现
 + (instancetype)showSystemStylePopupWithTitle:(NSString *)title
                                          url:(NSURL *)url
                                      urlText:(NSString *)urlText
                           primaryButtonTitle:(NSString *)primaryTitle
                         secondaryButtonTitle:(NSString *)secondaryTitle
                              primaryHandler:(SLCustomAlertActionHandler)primaryHandler
                            secondaryHandler:(SLCustomAlertActionHandler)secondaryHandler
                              cancelHandler:(SLCustomAlertActionHandler)cancelHandler {
    SLCustomAlertView *alertView = [[SLCustomAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    if (!alertView) { return nil; }

    alertView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    alertView.confirmHandler = primaryHandler;
    alertView.browserHandler = secondaryHandler;
    alertView.cancelHandler = cancelHandler;

    // 容器
    [alertView setupContainerView];

    // 标题
    [alertView setupTitleLabelWithText:title];

    // URL 文本（蓝色）
    [alertView setupMessageLabelWithText:nil];
    if (urlText.length > 0 || url) {
        NSString *text = urlText ?: (url.absoluteString ?: @"");
        [alertView setURL:url ?: [NSURL URLWithString:text] withText:text];
    }

    // 纵向按钮（文案可配置，取消默认“取消”）
    [alertView setupSystemStyleButtonsWithPrimaryTitle:primaryTitle secondaryTitle:secondaryTitle cancelTitle:@"取消"]; 

    // 点击背景关闭
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:alertView action:@selector(handleBackgroundTap:)];
//    tapGesture.delegate = alertView;
//    [alertView addGestureRecognizer:tapGesture];

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
        self.confirmOnRight = YES; // 默认确认按钮在右侧
        
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
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(270);
        make.height.mas_greaterThanOrEqualTo(100);
    }];
}

- (void)setupTitleLabelWithText:(NSString *)title {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 0;
    [self.containerView addSubview:self.titleLabel];
    
    // 设置标题标签约束
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(20);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    }];
}

- (void)setupMessageLabelWithText:(NSString *)message {
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.text = message;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.messageLabel.textColor = [UIColor systemBlueColor];
    self.messageLabel.numberOfLines = 0;
    [self.containerView addSubview:self.messageLabel];
    
    // 设置消息标签约束
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    }];
    
    // 添加长按手势以支持复制
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.messageLabel addGestureRecognizer:longPressGesture];
    self.messageLabel.userInteractionEnabled = YES;
}

- (void)setupButtonsWithConfirmTitle:(NSString *)confirmTitle cancelTitle:(NSString *)cancelTitle {
    // 水平分隔线
    self.horizontalSeparator = [[UIView alloc] init];
    self.horizontalSeparator.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:self.horizontalSeparator];
    
    self.horizontalSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.horizontalSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.messageLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0.5);
    }];
    
    // 确认按钮
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.confirmButton];
    
    // 取消按钮
    if (cancelTitle) {
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
        self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:self.cancelButton];
        
        // 按钮分隔线
        self.buttonSeparator = [[UIView alloc] init];
        self.buttonSeparator.backgroundColor = [UIColor separatorColor];
        [self.containerView addSubview:self.buttonSeparator];
        
        self.buttonSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    // 更新按钮布局
    [self updateButtonLayout];
    
    // 设置容器视图底部约束
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.confirmButton.mas_bottom).offset(8);
    }];
}

// 系统风格：三个纵向按钮（文案可配置）
- (void)setupSystemStyleButtonsWithPrimaryTitle:(NSString *)primaryTitle
                               secondaryTitle:(NSString *)secondaryTitle
                                   cancelTitle:(NSString *)cancelTitle {
    // 清理可能遗留的竖向分割线，避免与系统风格的水平分割线重叠
    if (self.buttonSeparator) {
        [self.buttonSeparator removeFromSuperview];
        self.buttonSeparator = nil;
    }

    // 第一条水平分隔线在 URL 下方
    self.horizontalSeparator = [[UIView alloc] init];
    self.horizontalSeparator.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:self.horizontalSeparator];
    self.horizontalSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.horizontalSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.messageLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0.5);
    }];

    // 按钮样式统一
    UIButton *(^makeButton)(NSString *) = ^UIButton *(NSString *title) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        return btn;
    };

    // 第一按钮
    self.confirmButton = makeButton(primaryTitle ?: @"");
    [self.confirmButton addTarget:self action:@selector(readerButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.confirmButton];
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.horizontalSeparator.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(48);
    }];

    // 第二条分隔线
    UIView *sep2 = [[UIView alloc] init];
    sep2.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:sep2];
    sep2.translatesAutoresizingMaskIntoConstraints = NO;
    [sep2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.confirmButton.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0.5);
    }];

    // 第二按钮
    self.secondaryButton = makeButton(secondaryTitle ?: @"");
    [self.secondaryButton addTarget:self action:@selector(browserButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.secondaryButton];
    self.secondaryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.secondaryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sep2.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(48);
    }];

    // 第三条分隔线
    UIView *sep3 = [[UIView alloc] init];
    sep3.backgroundColor = [UIColor separatorColor];
    [self.containerView addSubview:sep3];
    sep3.translatesAutoresizingMaskIntoConstraints = NO;
    [sep3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.secondaryButton.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(0.5);
    }];

    // 取消
    self.cancelButton = makeButton(cancelTitle ?: @"取消");
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.cancelButton];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sep3.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(48);
    }];

    // 容器底部：取消按钮下不额外留白，保证三行视觉高度一致
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.cancelButton.mas_bottom);
    }];
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
        [self.buttonSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.horizontalSeparator.mas_bottom);
            make.bottom.equalTo(self.containerView);
            make.width.mas_equalTo(0.5);
            make.centerX.equalTo(self.containerView);
        }];
        
        // 根据确认按钮位置设置约束
        if (self.confirmOnRight) {
            // 确认按钮在右侧
            [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.horizontalSeparator.mas_bottom);
                make.left.equalTo(self.buttonSeparator.mas_right);
                make.right.equalTo(self.containerView);
                make.height.mas_equalTo(38);
            }];
            [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.horizontalSeparator.mas_bottom);
                make.left.equalTo(self.containerView);
                make.right.equalTo(self.buttonSeparator.mas_left);
                make.height.mas_equalTo(38);
            }];
        } else {
            // 确认按钮在左侧
            [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.horizontalSeparator.mas_bottom);
                make.left.equalTo(self.containerView);
                make.right.equalTo(self.buttonSeparator.mas_left);
                make.height.mas_equalTo(38);
            }];
            [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.horizontalSeparator.mas_bottom);
                make.left.equalTo(self.buttonSeparator.mas_right);
                make.right.equalTo(self.containerView);
                make.height.mas_equalTo(38);
            }];
        }
    } else {
        // 只有确认按钮
        [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.horizontalSeparator.mas_bottom);
            make.left.right.equalTo(self.containerView);
            make.height.mas_equalTo(38);
        }];
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
    // 系统风格（三个纵向按钮）不使用左右并排布局，避免误触发导致分割线叠加
    if (self.secondaryButton) {
        return;
    }
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
    self.containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    
    [UIView animateWithDuration:0.2 
                          delay:0 
         usingSpringWithDamping:0.8 
          initialSpringVelocity:0.5 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
        self.alpha = 1;
        self.containerView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.15 
                     animations:^{
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.95, 0.95);
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

// 新增：阅读器打开按钮事件（与原 confirmHandler 绑定）
- (void)readerButtonTapped {
    [self confirmButtonTapped];
}

// 新增：浏览器打开按钮事件
- (void)browserButtonTapped {
    [self dismiss];
    if (self.browserHandler) {
        self.browserHandler();
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
