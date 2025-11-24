//
//  SLBottomToolBar.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLBottomToolBar.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@interface SLButtonWithCountView : UIView

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, copy) void (^buttonAction)(void);

- (instancetype)initWithImage:(NSString *)normalImage selectedImage:(NSString *)selectedImage;
- (void)updateCount:(NSInteger)count;
- (void)updateCountColor:(UIColor *)color;
- (void)setButtonSelected:(BOOL)selected;
- (BOOL)isButtonSelected;

@end

@implementation SLButtonWithCountView

- (instancetype)initWithImage:(NSString *)normalImage selectedImage:(NSString *)selectedImage {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;

        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button setImage:[UIImage imageNamed:normalImage] forState:UIControlStateNormal];
        [self.button setImage:[UIImage imageNamed:selectedImage] forState:UIControlStateSelected];
        self.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.button.userInteractionEnabled = NO; // 确保按钮可以交
        [self addSubview:self.button];
        
        self.countLabel = [[UILabel alloc] init];
        self.countLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.countLabel.textColor = Color16(0x222222);
        self.countLabel.text = @"";
        [self addSubview:self.countLabel];
        
        [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self).offset(-10);
            make.centerY.equalTo(self);
            make.width.height.equalTo(@24);
        }];
        
        [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.button.mas_right).offset(8);
            make.centerY.equalTo(self.button);
        }];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)buttonTapped {
    if (self.buttonAction) {
        self.buttonAction();
    }
}

- (void)updateCount:(NSInteger)count {
    if (count > 0) {
        self.countLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    } else {
        self.countLabel.text = @"";
    }
}

- (void)updateCountColor:(UIColor *)color {
    self.countLabel.textColor = color;
}

- (void)setButtonSelected:(BOOL)selected {
    self.button.selected = selected;
}

- (BOOL)isButtonSelected {
    return self.button.selected;
}

@end

@interface SLBottomToolBar()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) SLButtonWithCountView *likeView;
@property (nonatomic, strong) SLButtonWithCountView *commentView;
@property (nonatomic, strong) SLButtonWithCountView *aiView;
@property (nonatomic, strong) SLButtonWithCountView *shareView;
@property (nonatomic, strong) UIView *topLineView;

@end

@implementation SLBottomToolBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [SLColorManager primaryBackgroundColor]; //Color16(0xFCFCFC);
    self.topLineView = [[UIView alloc] initWithFrame:CGRectZero];
    self.topLineView.backgroundColor = Color16A(0x000000, 0.08);
    [self addSubview:self.topLineView];
    
    // 创建UIStackView
    self.stackView = [[UIStackView alloc] init];
    self.stackView.axis = UILayoutConstraintAxisHorizontal;
    self.stackView.distribution = UIStackViewDistributionFillEqually;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.spacing = 0;
    [self addSubview:self.stackView];
    
    // 创建点赞按钮和计数视图
    self.likeView = [[SLButtonWithCountView alloc] initWithImage:@"like_icon" selectedImage:@"liked_icon"];
    __weak typeof(self) weakSelf = self;
    self.likeView.buttonAction = ^{
        [weakSelf likeButtonTapped];
    };
    [self.stackView addArrangedSubview:self.likeView];
    [self.likeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.stackView);
    }];
    
    // 创建评论按钮和计数视图
    self.commentView = [[SLButtonWithCountView alloc] initWithImage:@"comment_icon" selectedImage:@"comment_icon"];
    self.commentView.buttonAction = ^{
        [weakSelf commentButtonTapped];
    };
    [self.stackView addArrangedSubview:self.commentView];
    [self.commentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.stackView);
    }];
    
    // 创建AI按钮视图
    self.aiView = [[SLButtonWithCountView alloc] initWithImage:@"ai_icon" selectedImage:@"ai_icon"];
    self.aiView.buttonAction = ^{
        [weakSelf aiButtonTapped];
    };
    [self.stackView addArrangedSubview:self.aiView];
    [self.aiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.stackView);
    }];
    
    // 创建分享按钮和计数视图
    self.shareView = [[SLButtonWithCountView alloc] initWithImage:@"share_icon" selectedImage:@"share_icon"];
    self.shareView.buttonAction = ^{
        [weakSelf shareButtonTapped];
    };
    [self.stackView addArrangedSubview:self.shareView];
    [self.shareView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.stackView);
    }];
    
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topLineView.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self).offset(-kiPhoneXBottomMargin);
    }];
    
    [self.topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(0.5);
    }];
}

#pragma mark - Action Methods

- (void)likeButtonTapped {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickLikeButton:)]) {
        [self.delegate toolBar:self didClickLikeButton:self.likeView.button];
    }
}

- (void)commentButtonTapped {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickCommentButton:)]) {
        [self.delegate toolBar:self didClickCommentButton:self.commentView.button];
    }
}

- (void)aiButtonTapped {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickAIButton:)]) {
        [self.delegate toolBar:self didClickAIButton:self.aiView.button];
    }
}

- (void)shareButtonTapped {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickShareButton:)]) {
        [self.delegate toolBar:self didClickShareButton:self.shareView.button];
    }
}

#pragma mark - Public Methods

- (void)updateLikeStatus:(BOOL)isLiked count:(NSInteger)count {
    [self.likeView setButtonSelected:isLiked];
    [self.likeView updateCount:count];
    
//    if (isLiked) {
//        [self.likeView updateCountColor:[UIColor redColor]];
//    } else {
//        [self.likeView updateCountColor:[UIColor darkGrayColor]];
//    }
}

- (void)updateCommentCount:(NSInteger)count {
    [self.commentView updateCount:count];
}

- (void)updateShareCount:(NSInteger)count {
    [self.shareView updateCount:count];
}

@end
