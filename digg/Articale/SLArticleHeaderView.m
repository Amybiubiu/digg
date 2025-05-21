//
//  SLArticleHeaderView.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleHeaderView.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import <SDWebImage/SDWebImage.h>

@interface SLArticleHeaderView ()

@property (nonatomic, strong) UILabel *sourceUrlLabel;
@property (nonatomic, strong) UIButton *readOriginalButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UILabel *publishTimeLabel;
@property (nonatomic, strong) UIView *dividingView;

@end

@implementation SLArticleHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    // 网站来源标签
    self.sourceUrlLabel = [[UILabel alloc] init];
    self.sourceUrlLabel.font = [UIFont pingFangMediumWithSize:10];
    self.sourceUrlLabel.textColor = Color16(0xD2D2D2); //TODO: 暗黑模式
    self.sourceUrlLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.sourceUrlLabel];
    
    // 阅读原文按钮
    self.readOriginalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.readOriginalButton setTitle:@"阅读原文" forState:UIControlStateNormal];
    [self.readOriginalButton setTitleColor:Color16(0x2592DB) forState:UIControlStateNormal]; //TODO: 暗黑模式
    self.readOriginalButton.titleLabel.font = [UIFont pingFangSemiboldWithSize:10];
    [self.readOriginalButton addTarget:self action:@selector(readOriginalButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.readOriginalButton.hidden = YES;
    [self addSubview:self.readOriginalButton];
    
    // 文章标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont pingFangBoldWithSize:24];
    self.titleLabel.textColor = Color16(0x222222); //TODO: 暗黑模式
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.preferredMaxLayoutWidth = kScreenWidth - (16 * 2);
    [self addSubview:self.titleLabel];
    
    // 作者头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.layer.cornerRadius = 15;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.userInteractionEnabled = YES;  // 启用用户交互
     UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageTapped)];
    [self.avatarImageView addGestureRecognizer:tapGesture];
    [self addSubview:self.avatarImageView];
    
    // 作者名称
    self.authorNameLabel = [[UILabel alloc] init];
    self.authorNameLabel.font = [UIFont pingFangMediumWithSize:12];
    self.authorNameLabel.textColor = Color16(0x666666); //TODO: 暗黑模式
    [self addSubview:self.authorNameLabel];
    
    // 发布时间
    self.publishTimeLabel = [[UILabel alloc] init];
    self.publishTimeLabel.font = [UIFont pingFangMediumWithSize:12];
    self.publishTimeLabel.textColor = Color16(0xC6C6C6); //TODO: 暗黑模式
    [self addSubview:self.publishTimeLabel];
    
    //分割线
    self.dividingView = [[UIView alloc] init];
    self.dividingView.backgroundColor = Color16(0xEEEEEE); //TODO: 暗黑模式
    [self addSubview:self.dividingView];
    
    // 设置约束
    CGFloat topMargin = 16.0;
    CGFloat leftMargin = 16.0;
    
    [self.sourceUrlLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(topMargin);
        make.left.equalTo(self).offset(leftMargin);
    }];
    
    [self.readOriginalButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.sourceUrlLabel);
        make.right.equalTo(self).offset(-leftMargin);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sourceUrlLabel.mas_bottom).offset(7);
        make.left.equalTo(self).offset(leftMargin);
        make.right.equalTo(self).offset(-leftMargin);
    }];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(topMargin);
        make.left.equalTo(self).offset(leftMargin);
        make.width.height.equalTo(@30);
        make.bottom.equalTo(self).offset(-17);
    }];
    
    [self.authorNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.top.equalTo(self.avatarImageView).offset(-2);
    }];
    
    [self.publishTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.authorNameLabel);
        make.bottom.equalTo(self.avatarImageView).offset(2);
    }];
    
    [self.dividingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(1);
        make.bottom.equalTo(self);
    }];
}

- (void)setupWithTitle:(NSString *)title
                source:(NSString *)source
           avatarImage:(NSString *)avatarImage
            authorName:(NSString *)authorName
           publishTime:(NSString *)publishTime
                 url:(NSString *)url {
    self.titleLabel.text = title;
    self.sourceUrlLabel.text = source;
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarImage] placeholderImage:[UIImage imageNamed:@"avatar_default_icon"]];
    self.authorNameLabel.text = authorName ?: source;
    self.publishTimeLabel.text = publishTime;
    self.readOriginalButton.hidden = url.length == 0 ? YES : NO;
}

- (void)readOriginalButtonTapped {
    if (self.readOriginalHandler) {
        self.readOriginalHandler();
    }
}

- (void)avatarImageTapped {
    if (self.avatarClickHandler) {
        self.avatarClickHandler();
    }
}

- (CGFloat)getContentHeight {
    // 计算标题实际高度
    CGFloat titleWidth = kScreenWidth - 32; // 左右各16点边距
    CGFloat titleHeight = [self.titleLabel sizeThatFits:CGSizeMake(titleWidth, CGFLOAT_MAX)].height;
    
    CGFloat sourceHeight = [self.sourceUrlLabel sizeThatFits:CGSizeZero].height;
    
    // 计算总高度
    CGFloat topMargin = 16.0; // 顶部边距
    CGFloat titleTopMargin = 7.0; // 标题上方边距
    CGFloat avatarTopMargin = 16.0; // 头像上方边距
    CGFloat avatarHeight = 30.0; // 头像高度
    CGFloat bottomMargin = 17.0; // 底部边距
    
    CGFloat totalHeight = topMargin + sourceHeight + titleTopMargin + titleHeight + avatarTopMargin + avatarHeight + bottomMargin;
    
    return MAX(totalHeight, 135);
}

@end
