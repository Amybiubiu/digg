//
//  SLCommentCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLCommentCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import <SDWebImage/SDWebImage.h>
#import "SLArticleEntity.h"

@interface SLCommentCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, strong) SLCommentEntity *comment;

@end

@implementation SLCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.layer.cornerRadius = 20;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.avatarImageView];
    
    // 用户名
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.font = [UIFont pingFangMediumWithSize:14];
    self.usernameLabel.textColor = [SLColorManager primaryTextColor];
    [self.contentView addSubview:self.usernameLabel];
    
    // 时间
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont pingFangRegularWithSize:12];
    self.timeLabel.textColor = [SLColorManager cellContentColor];
    [self.contentView addSubview:self.timeLabel];
    
    // 内容
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont pingFangRegularWithSize:14];
    self.contentLabel.textColor = [SLColorManager primaryTextColor];
    self.contentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.contentLabel];
    
    // 回复按钮
    self.replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.replyButton setImage:[UIImage imageNamed:@"comment_reply"] forState:UIControlStateNormal];
    [self.replyButton addTarget:self action:@selector(replyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.replyButton];
    
    // 点赞按钮
    self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"like_selected"] forState:UIControlStateSelected];
    [self.likeButton addTarget:self action:@selector(likeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.likeButton];
    
    // 点赞数
    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.font = [UIFont pingFangRegularWithSize:12];
    self.likeCountLabel.textColor = [SLColorManager cellContentColor];
    [self.contentView addSubview:self.likeCountLabel];
    
    // 分隔线
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = [SLColorManager cellDivideLineColor];
    [self.contentView addSubview:self.separatorLine];
    
    // 设置约束
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.contentView).offset(12);
        make.width.height.equalTo(@40);
    }];
    
    [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(10);
        make.top.equalTo(self.avatarImageView);
        make.right.lessThanOrEqualTo(self.contentView).offset(-80);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(4);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.timeLabel.mas_bottom).offset(8);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.contentLabel.mas_bottom).offset(8);
        make.width.height.equalTo(@24);
        make.bottom.equalTo(self.contentView).offset(-12);
    }];
    
    [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.replyButton.mas_right).offset(16);
        make.centerY.equalTo(self.replyButton);
        make.width.height.equalTo(@24);
    }];
    
    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.likeButton.mas_right).offset(4);
        make.centerY.equalTo(self.likeButton);
    }];
    
    [self.separatorLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView);
        make.height.equalTo(@0.5);
    }];
}

- (void)updateWithComment:(SLCommentEntity *)comment {
    self.comment = comment;
    
    // 更新头像
    if (comment.avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:comment.avatar]
                                placeholderImage:[UIImage imageNamed:@"avatar_default_icon"]];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"avatar_default_icon"];
    }
    
    // 更新用户名
    self.usernameLabel.text = comment.username ?: @"匿名用户";
    
    // 更新时间
    if (comment.gmtCreate > 0) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:comment.gmtCreate.integerValue / 1000.0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        self.timeLabel.text = [formatter stringFromDate:date];
    } else {
        self.timeLabel.text = @"";
    }
    
    // 更新内容
    self.contentLabel.text = comment.content;
    
    // 更新点赞状态和数量
    self.likeButton.selected = comment.disliked;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)comment.likeCount];
}

#pragma mark - Actions

- (void)replyButtonTapped {
    if (self.replyHandler) {
        self.replyHandler(self.comment);
    }
}

- (void)likeButtonTapped {
    if (self.likeHandler) {
        self.likeHandler(self.comment);
    }
}

@end
