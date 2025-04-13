//
//  CaocaoLoadDataDefaultView.m
//  Pods
//
//  Created by luminary on 2017/8/29.
//
//

#import "CaocaoLoadDataDefaultView.h"
#import "UIView+CommonKit.h"
#import "SLGeneralMacro.h"
#import "UIImage+CommonKit.h"
#import "NSString+UXing.h"
#import "SLColorManager.h"

#define ANIMA_VIEW_WIDTH        44.f
#define ANIMA_VIEW_TOP          200.f
#define ANIMA_VIEW_LARGE_TOP    50.f
#define ANIMA_VIEW_LARGE_WIDTH  150.f


#define TEXTLABEL_MIDDLE_MARGIN      12.f
#define TEXTLABEL_WIDTH              ([UIScreen mainScreen].bounds.size.width-48.f)
#define ACTION_BUTTON_BORDER_COLOR   RGBA(170,170,179,0.5)
#define ACTION_BUTTON_WIDTH          180.f
#define ACTION_BUTTON_HEIGHT         44.f
#define ACTION_BUTTON_LARGE_HEIGHT   52.f
#define ACTION_BUTTON_MIDDLE_MARGIN  24.f
#define OTHER_BUTTON_MIDDLE_MARGIN   12.f



@interface CaocaoLoadDataDefaultView ()

@property (nonatomic, strong) UIImage *backgroundImg;

@end

@implementation CaocaoLoadDataDefaultView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.largeMode = NO;
    }
    return self;
}

- (YYAnimatedImageView *)animationView {
    if (!_animationView) {
        _animationView = [[YYAnimatedImageView alloc] init];
    }
    return _animationView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [SLColorManager cellTitleColor];
        _textLabel.numberOfLines = 0;
    }
    return _textLabel;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionButton.backgroundColor = [UIColor whiteColor];
        [_actionButton setTitleColor:[SLColorManager cellTitleColor] forState:UIControlStateNormal];
        [_actionButton addTarget:self action:@selector(actionTouchUpInsideHandler:) forControlEvents:UIControlEventTouchUpInside];
        _actionButton.layer.cornerRadius = 8.f;
    }
    return _actionButton;
}


- (UIButton *)otherButton {
    if (!_otherButton) {
        _otherButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _otherButton.backgroundColor = [UIColor whiteColor];
        [_otherButton setTitleColor:[SLColorManager cellTitleColor] forState:UIControlStateNormal];
        [_otherButton addTarget:self action:@selector(otherTouchUpInsideHandler:) forControlEvents:UIControlEventTouchUpInside];
        _otherButton.layer.cornerRadius = 8.f;
        _otherButton.hidden = YES;
    }
    return _otherButton;
}

- (UIImage *)backgroundImg {
    if (!_backgroundImg) {
        _backgroundImg = [[UIImage imageWithColor:[SLColorManager tagBackgroundTextColor] size:CGSizeMake(ACTION_BUTTON_WIDTH, ACTION_BUTTON_LARGE_HEIGHT)] imageWithCornerRadius:8.f];
    }
    return _backgroundImg;
}

#pragma mark - load

- (void)loadStateText:(NSString *)text mode:(CaocaoDataMode)mode {
    if (stringIsEmpty(text)) text = @"";
    [self addSubview:self.animationView];
    [self addSubview:self.textLabel];
    self.textLabel.text = text;
    self.textLabel.font = [UIFont systemFontOfSize:13];
    if (mode == CaocaoDataModeLoading) {
        [self.actionButton removeFromSuperview];
        [self.otherButton removeFromSuperview];
        self.otherButton.hidden = YES;
        [self setLoadingMode];
    } else if (mode == CaocaoDataModeDone) {
        [self addSubview:self.actionButton];
        [self addSubview:self.otherButton];
        [self setDoneMode];
    } else if (mode == CaocaoDataModeEmpty) {
        [self.actionButton removeFromSuperview];
        [self.otherButton removeFromSuperview];
        self.otherButton.hidden = YES;
        [self setEmptyMode];
    }
}

- (void)loadCallbackText:(NSString *)text otherCallbackText:(NSString *)otherCallbackText {
    if (stringIsEmpty(text)) return;
    if (_actionButton) {
        [_actionButton setTitle:text forState:UIControlStateNormal];
    }
    if (stringIsEmpty(otherCallbackText)) return;
    if (_otherButton) {
        _otherButton.hidden = NO;
        [_otherButton setTitle:otherCallbackText forState:UIControlStateNormal];
        [self resetOtherButtonState];
    }
}

#pragma mark - layout
- (void)setLoadingMode {
    self.animationView.backgroundColor = [UIColor clearColor];
    self.animationView.frame = CGRectMake((self.width - ANIMA_VIEW_WIDTH) / 2.f, ANIMA_VIEW_TOP, ANIMA_VIEW_WIDTH, ANIMA_VIEW_WIDTH);
    NSBundle *mainBundle = [NSBundle mainBundle];
    UIImage *image = [UIImage imageNamed:self.imgUrl inBundle:mainBundle compatibleWithTraitCollection:nil];
    
    //大图模式,调整图片显示的大小
    if ((image.size.width == 450.f) || (image.size.width == 150.f)) {
        self.animationView.frame = CGRectMake((self.width - ANIMA_VIEW_LARGE_WIDTH) / 2.f, ANIMA_VIEW_LARGE_TOP, ANIMA_VIEW_LARGE_WIDTH, ANIMA_VIEW_LARGE_WIDTH);
    }
    self.textLabel.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width -TEXTLABEL_WIDTH) / 2.f, self.animationView.bottom + TEXTLABEL_MIDDLE_MARGIN, TEXTLABEL_WIDTH, ceil([self.textLabel.text heightForFont:self.textLabel.font width:TEXTLABEL_WIDTH]));
    self.animationView.image = image;
}

- (void)setDoneMode {
    self.animationView.frame = CGRectMake((self.width - ANIMA_VIEW_LARGE_WIDTH) / 2.f, ANIMA_VIEW_LARGE_TOP, ANIMA_VIEW_LARGE_WIDTH, ANIMA_VIEW_LARGE_WIDTH);
    self.textLabel.frame = CGRectMake((self.frame.size.width -TEXTLABEL_WIDTH) / 2.f, self.animationView.bottom + TEXTLABEL_MIDDLE_MARGIN, TEXTLABEL_WIDTH, ceil([self.textLabel.text heightForFont:self.textLabel.font width:TEXTLABEL_WIDTH]));
    self.animationView.image = [UIImage imageNamed:self.imgUrl];
    [self resetActionButtonState];
}

- (void)setEmptyMode {
    self.animationView.frame = CGRectMake((self.width - ANIMA_VIEW_LARGE_WIDTH) / 2.f, ANIMA_VIEW_LARGE_TOP, ANIMA_VIEW_LARGE_WIDTH, ANIMA_VIEW_LARGE_WIDTH);
    self.textLabel.frame = CGRectMake((kScreenWidth -TEXTLABEL_WIDTH) / 2.f, self.animationView.bottom + TEXTLABEL_MIDDLE_MARGIN, TEXTLABEL_WIDTH, ceil([self.textLabel.text heightForFont:self.textLabel.font width:TEXTLABEL_WIDTH]));
    self.animationView.image =[UIImage imageNamed:self.imgUrl];
}

- (void)resetActionButtonState {
    if (!self.largeMode) {
        //非大字体模式
        self.actionButton.layer.borderColor = [SLColorManager cellDivideLineColor].CGColor;
        self.actionButton.layer.borderWidth = 1;
        self.actionButton.titleLabel.font = [UIFont systemFontOfSize:14];
        self.actionButton.frame = CGRectMake((self.width - ACTION_BUTTON_WIDTH) / 2.f, self.textLabel.bottom + ACTION_BUTTON_MIDDLE_MARGIN, ACTION_BUTTON_WIDTH, ACTION_BUTTON_HEIGHT);
        return;
    };
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:20];
    self.actionButton.layer.shadowColor = [SLColorManager cellDivideLineColor].CGColor;
    self.actionButton.layer.shadowOpacity = .2f;
    self.actionButton.layer.shadowOffset = CGSizeMake(0.f,2.f);
    self.actionButton.layer.shadowRadius = 12.f;
    [self.actionButton setBackgroundImage:self.backgroundImg forState:UIControlStateHighlighted];
    self.actionButton.frame = CGRectMake((self.width - ACTION_BUTTON_WIDTH) / 2.f, self.textLabel.bottom + ACTION_BUTTON_MIDDLE_MARGIN, ACTION_BUTTON_WIDTH, ACTION_BUTTON_LARGE_HEIGHT);
}

- (void)resetOtherButtonState {
    if (!self.largeMode) {
        //非大字体模式
        self.otherButton.layer.borderColor = [SLColorManager cellDivideLineColor].CGColor;
        self.otherButton.layer.borderWidth = 1;
        self.otherButton.titleLabel.font = [UIFont systemFontOfSize:14];
        self.otherButton.frame = CGRectMake((self.width - ACTION_BUTTON_WIDTH) / 2.f, self.actionButton.bottom + ACTION_BUTTON_MIDDLE_MARGIN, ACTION_BUTTON_WIDTH, ACTION_BUTTON_HEIGHT);
        return;
    };
    self.otherButton.titleLabel.font = [UIFont systemFontOfSize:20];
    self.otherButton.layer.shadowColor = [SLColorManager cellDivideLineColor].CGColor;
    self.otherButton.layer.shadowOpacity = .2f;
    self.otherButton.layer.shadowOffset = CGSizeMake(0.f,2.f);
    self.otherButton.layer.shadowRadius = 12.f;
    [self.otherButton setBackgroundImage:self.backgroundImg forState:UIControlStateHighlighted];
    self.otherButton.frame = CGRectMake((self.width - ACTION_BUTTON_WIDTH) / 2.f, self.actionButton.bottom + ACTION_BUTTON_MIDDLE_MARGIN, ACTION_BUTTON_WIDTH, ACTION_BUTTON_LARGE_HEIGHT);
}

#pragma mark - handler

- (void)actionTouchUpInsideHandler:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(dataLoadActionCallback)]) {
        [self.delegate dataLoadActionCallback];
    }
}

- (void)otherTouchUpInsideHandler:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(dataOtherActionCallback)]) {
        [self.delegate dataOtherActionCallback];
    }
}

@end
