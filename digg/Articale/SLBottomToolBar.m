//
//  SLBottomToolBar.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLBottomToolBar.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@implementation SLBottomToolBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    // 添加顶部分割线
    UIView *topLine = [[UIView alloc] init];
    topLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(0.5);
    }];
    
    // 点赞按钮
    _likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_likeButton setImage:[UIImage imageNamed:@"article_like_normal"] forState:UIControlStateNormal];
    [_likeButton setImage:[UIImage imageNamed:@"article_like_selected"] forState:UIControlStateSelected];
    [_likeButton setTitle:@"0" forState:UIControlStateNormal];
    [_likeButton setTitleColor:[SLColorManager secondaryTextColor] forState:UIControlStateNormal];
    [_likeButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    _likeButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [_likeButton addTarget:self action:@selector(likeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_likeButton];
    
    // 评论按钮
    _commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_commentButton setImage:[UIImage imageNamed:@"article_comment"] forState:UIControlStateNormal];
    [_commentButton setTitle:@"0" forState:UIControlStateNormal];
    [_commentButton setTitleColor:[SLColorManager secondaryTextColor] forState:UIControlStateNormal];
    _commentButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [_commentButton addTarget:self action:@selector(commentButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_commentButton];
    
    // AI按钮
    _aiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_aiButton setImage:[UIImage imageNamed:@"article_ai"] forState:UIControlStateNormal];
    [_aiButton setTitle:@"AI" forState:UIControlStateNormal];
    [_aiButton setTitleColor:[SLColorManager secondaryTextColor] forState:UIControlStateNormal];
    _aiButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [_aiButton addTarget:self action:@selector(aiButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_aiButton];
    
    // 分享按钮
    _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shareButton setImage:[UIImage imageNamed:@"article_share"] forState:UIControlStateNormal];
    [_shareButton setTitle:@"0" forState:UIControlStateNormal];
    [_shareButton setTitleColor:[SLColorManager secondaryTextColor] forState:UIControlStateNormal];
    _shareButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [_shareButton addTarget:self action:@selector(shareButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shareButton];
    
    // 设置按钮内部图文布局
    [self setButtonImageTitleLayout:_likeButton];
    [self setButtonImageTitleLayout:_commentButton];
    [self setButtonImageTitleLayout:_aiButton];
    [self setButtonImageTitleLayout:_shareButton];
    
    // 布局按钮
    CGFloat buttonWidth = kScreenWidth / 4;
    [_likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self).offset(5);
        make.bottom.equalTo(self).offset(-5);
        make.width.mas_equalTo(buttonWidth);
    }];
    
    [_commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_likeButton.mas_right);
        make.top.bottom.width.equalTo(_likeButton);
    }];
    
    [_aiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_commentButton.mas_right);
        make.top.bottom.width.equalTo(_likeButton);
    }];
    
    [_shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_aiButton.mas_right);
        make.top.bottom.width.equalTo(_likeButton);
        make.right.equalTo(self);
    }];
}

- (void)setButtonImageTitleLayout:(UIButton *)button {
    // 设置图片和文字上下布局
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    // 设置图片在上，文字在下
    CGFloat spacing = 5.0;
    button.imageEdgeInsets = UIEdgeInsetsMake(-spacing, 0, 0, -button.titleLabel.bounds.size.width);
    button.titleEdgeInsets = UIEdgeInsetsMake(button.currentImage.size.height + spacing, -button.currentImage.size.width, 0, 0);
}

#pragma mark - Actions

- (void)likeButtonClicked:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickLikeButton:)]) {
        [self.delegate toolBar:self didClickLikeButton:button];
    }
}

- (void)commentButtonClicked:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickCommentButton:)]) {
        [self.delegate toolBar:self didClickCommentButton:button];
    }
}

- (void)aiButtonClicked:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickAIButton:)]) {
        [self.delegate toolBar:self didClickAIButton:button];
    }
}

- (void)shareButtonClicked:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(toolBar:didClickShareButton:)]) {
        [self.delegate toolBar:self didClickShareButton:button];
    }
}

#pragma mark - Public Methods

- (void)updateLikeStatus:(BOOL)isLiked count:(NSInteger)count {
    self.likeButton.selected = isLiked;
    [self.likeButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
}

- (void)updateCommentCount:(NSInteger)count {
    [self.commentButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
}

- (void)updateShareCount:(NSInteger)count {
    [self.shareButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新底部工具栏位置
    [self.likeButton.imageView layoutIfNeeded];
    [self.likeButton.titleLabel layoutIfNeeded];
    [self.commentButton.imageView layoutIfNeeded];
    [self.commentButton.titleLabel layoutIfNeeded];
    [self.aiButton.imageView layoutIfNeeded];
    [self.aiButton.titleLabel layoutIfNeeded];
    [self.shareButton.imageView layoutIfNeeded];
    [self.shareButton.titleLabel layoutIfNeeded];
    
    // 重新设置按钮内部布局
    [self setButtonImageTitleLayout:self.likeButton];
    [self setButtonImageTitleLayout:self.commentButton];
    [self setButtonImageTitleLayout:self.aiButton];
    [self setButtonImageTitleLayout:self.shareButton];
}

@end
