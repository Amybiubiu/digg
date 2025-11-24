//  SLSimpleInteractionBar.m
//  digg
//
//  Created by Tim Bao on 2025/5/20.
//

#import "SLSimpleInteractionBar.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"

@interface SLSimpleInteractionBar ()

@property (nonatomic, strong) UIButton *likeButton;        // 点赞按钮
@property (nonatomic, strong) UILabel *likeLabel;          // 点赞数量标签
@property (nonatomic, strong) UIButton *dislikeButton;     // 不喜欢按钮
@property (nonatomic, strong) UILabel *dislikeLabel;       // 不喜欢数量标签
@property (nonatomic, strong) UIStackView *likeStackView;  // 点赞容器
@property (nonatomic, strong) UIStackView *dislikeStackView; // 不喜欢容器
@property (nonatomic, strong) UIStackView *mainStackView;  // 主容器

@property (nonatomic, assign) NSInteger likeNumber;
@property (nonatomic, assign) NSInteger dislikeNumber;
@property (nonatomic, assign) BOOL likeSelected;
@property (nonatomic, assign) BOOL dislikeSelected;

@end

@implementation SLSimpleInteractionBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _likeNumber = 0;
        _dislikeNumber = 0;
        _likeSelected = NO;
        _dislikeSelected = NO;
        
        [self setupViews];
        [self setupConstraints];
    }
    return self;
}

- (void)setupViews {
    // 创建点赞按钮
    _likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_likeButton setImage:[UIImage imageNamed:@"like_unselected_icon"] forState:UIControlStateNormal];
    [_likeButton setImage:[UIImage imageNamed:@"like_selected_icon"] forState:UIControlStateSelected];
    _likeButton.userInteractionEnabled = NO;
//    [_likeButton addTarget:self action:@selector(likeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // 创建点赞数量标签
    _likeLabel = [[UILabel alloc] init];
    _likeLabel.text = @"赞";
    _likeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _likeLabel.textColor = Color16A(0x333333, 0.8);
    _likeLabel.textAlignment = NSTextAlignmentLeft;
    
    // 创建点赞容器
    _likeStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_likeButton, _likeLabel]];
    _likeStackView.axis = UILayoutConstraintAxisHorizontal;
    _likeStackView.spacing = 2;
    _likeStackView.alignment = UIStackViewAlignmentCenter;
    _likeStackView.distribution = UIStackViewDistributionFill;
    _likeStackView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(likeButtonTapped)];
    [_likeStackView addGestureRecognizer:tap];
    
    // 创建不喜欢按钮
    _dislikeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_dislikeButton setImage:[UIImage imageNamed:@"reply-icon"] forState:UIControlStateNormal];
    _dislikeButton.userInteractionEnabled = NO;
//    [_dislikeButton addTarget:self action:@selector(dislikeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // 创建不喜欢数量标签
    _dislikeLabel = [[UILabel alloc] init];
    _dislikeLabel.text = @"回复";
    _dislikeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _dislikeLabel.textColor = Color16A(0x333333, 0.8);
    _dislikeLabel.textAlignment = NSTextAlignmentLeft;
    
    // 创建不喜欢容器
    _dislikeStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_dislikeButton, _dislikeLabel]];
    _dislikeStackView.axis = UILayoutConstraintAxisHorizontal;
    _dislikeStackView.spacing = 2;
    _dislikeStackView.alignment = UIStackViewAlignmentCenter;
    _dislikeStackView.distribution = UIStackViewDistributionFill;
    _dislikeStackView.userInteractionEnabled = YES;
    UITapGestureRecognizer* dislikeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dislikeButtonTapped)];
    [_dislikeStackView addGestureRecognizer:dislikeTap];
    
    // 创建主容器
    _mainStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_likeStackView, _dislikeStackView]];
    _mainStackView.axis = UILayoutConstraintAxisHorizontal;
    _mainStackView.spacing = 16.0;
    _mainStackView.alignment = UIStackViewAlignmentCenter;
    _mainStackView.distribution = UIStackViewDistributionFill;
    
    [self addSubview:_mainStackView];
}

- (void)setupConstraints {
    [_mainStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self);
        make.right.lessThanOrEqualTo(self);
    }];
    
    // 设置按钮尺寸
    [_likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@16);
    }];
    
    [_dislikeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@16);
    }];
}

#pragma mark - Actions

- (void)likeButtonTapped {
    self.likeSelected = !self.likeSelected;
    
    // 如果点赞被选中，取消不喜欢的选中状态
    if (self.likeSelected) {
        self.dislikeSelected = NO;
    }
    
    [self updateButtonStates];
    
    if ([self.delegate respondsToSelector:@selector(interactionBar:didTapLikeWithSelected:)]) {
        [self.delegate interactionBar:self didTapLikeWithSelected:self.likeSelected];
    }
}

- (void)dislikeButtonTapped {
    self.dislikeSelected = !self.dislikeSelected;
    
    // 如果不喜欢被选中，取消点赞的选中状态
    if (self.dislikeSelected) {
        self.likeSelected = NO;
    }
    
    [self updateButtonStates];
    
    if ([self.delegate respondsToSelector:@selector(interactionBarDidTapReply:)]) {
        [self.delegate interactionBarDidTapReply:self];
    }
}

- (void)updateButtonStates {
    _likeButton.selected = self.likeSelected;
//    _dislikeButton.selected = self.dislikeSelected;

    UIColor *selectedColor = Color16(0x333333);
    UIColor *normalColor = Color16A(0x333333, 0.8);
    
    _likeButton.tintColor = self.likeSelected ? selectedColor : normalColor;
    _likeLabel.textColor = self.likeSelected ? selectedColor : normalColor;
    
//    _dislikeButton.tintColor = self.dislikeSelected ? selectedColor : normalColor;
//    _dislikeLabel.textColor = self.dislikeSelected ? selectedColor : normalColor;
}

#pragma mark - Public Methods

- (void)updateLikeNumber:(NSInteger)number {
    self.likeNumber = number;
    if (number > 0) {
        _likeLabel.text = [NSString stringWithFormat:@"%ld", (long)number];
    } else {
        _likeLabel.text = @"赞";
    }
}

- (void)updateDislikeNumber:(NSInteger)number {
    self.dislikeNumber = number;
    // 对于回复按钮，保持显示"回复"文本而不是数字
    // 如果需要显示数字，可以取消下面的注释
    // _dislikeLabel.text = [NSString stringWithFormat:@"%ld", (long)number];
}

- (void)setLikeSelected:(BOOL)selected {
    _likeSelected = selected;
    [self updateButtonStates];
}

- (void)setDislikeSelected:(BOOL)selected {
    _dislikeSelected = selected;
    [self updateButtonStates];
}

- (BOOL)isLikeSelected {
    return self.likeSelected;
}

- (BOOL)isDislikeSelected {
    return self.dislikeSelected;
}

@end
