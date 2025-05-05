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

@interface SLCommentCell () <SLSimpleInteractionBarDelegate>

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
    self.avatarImageView.layer.cornerRadius = 15;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.avatarImageView];
    
    // 用户名
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.font = [UIFont pingFangMediumWithSize:12];
    self.usernameLabel.textColor = Color16(0x666666);
    [self.contentView addSubview:self.usernameLabel];
    
    // 标签列表视图
    self.tagView = [[SLHomeTagViewV2 alloc] init];
    self.tagView.tagLabel.font = [UIFont pingFangRegularWithSize:10];
    [self.tagView updateWithLabelBySmall:@"作者"];
    [self.contentView addSubview:self.tagView];
    
    // 时间
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont pingFangMediumWithSize:12];
    self.timeLabel.textColor = Color16(0xC6C6C6);
    [self.contentView addSubview:self.timeLabel];
    
    // 内容
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont pingFangRegularWithSize:14];
    self.contentLabel.textColor = Color16(0x313131);
    self.contentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.contentLabel];
    
    // 创建交互栏
    self.interactionBar = [[SLSimpleInteractionBar alloc] initWithFrame:CGRectZero];
    self.interactionBar.delegate = self;
    [self.contentView addSubview:self.interactionBar];
    
    // 设置约束
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.contentView).offset(19);
        make.width.height.equalTo(@30);
    }];
    
    [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.top.equalTo(self.contentView).offset(18);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.usernameLabel);
        make.left.equalTo(self.usernameLabel.mas_right).offset(4);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(1);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.timeLabel.mas_bottom).offset(8);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [self.interactionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(16);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];
}

- (void)updateWithComment:(SLCommentEntity *)comment authorId:(NSString *)authorId {
    self.comment = comment;
    
    // 设置头像
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:comment.avatar]
                            placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    
    // 设置用户名
    self.usernameLabel.text = comment.username;
    self.tagView.hidden = !(comment.userId == authorId);
    
    // 设置时间
    NSDate *commentDate = [NSDate dateWithTimeIntervalSince1970:[comment.gmtCreate doubleValue]/1000];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    self.timeLabel.text = [dateFormatter stringFromDate:commentDate];
    
    // 设置内容
    self.contentLabel.text = comment.content;
    
    [self.interactionBar updateLikeNumber:comment.likeCount];
    [self.interactionBar updateDislikeNumber:comment.dislikeCount];
    [self.interactionBar setLikeSelected:[comment.disliked isEqualToString:@"true"]];
    [self.interactionBar setDislikeSelected:[comment.disliked isEqualToString:@"false"]];
    [self updateConstraints];
}

- (void)updateRepliesWithList:(NSArray<SLCommentEntity *> *)replyList isCollapsed:(BOOL)isCollapsed totalCount:(NSInteger)totalCount {
    
    // 添加回复视图
    [self addReplyViews:replyList];
    
    [self updateConstraints];
}

- (void)addReplyViews:(NSArray<SLCommentEntity *> *)replyList {
    // 为每条回复创建视图
    CGFloat topOffset = 8;
    UIView *lastView = self.contentLabel;
    
    for (SLCommentEntity *reply in replyList) {
        // 创建回复视图容器
        UIView *replyView = [[UIView alloc] init];
        replyView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.5];
        replyView.layer.cornerRadius = 4;
        [self.contentView addSubview:replyView];
        
        // 创建回复内容标签
        UILabel *replyLabel = [[UILabel alloc] init];
        replyLabel.font = [UIFont pingFangRegularWithSize:13];
        replyLabel.textColor = [SLColorManager primaryTextColor];
        replyLabel.numberOfLines = 0;
        
        // 设置回复内容，格式为"用户名: 内容"
        NSString *replyText = [NSString stringWithFormat:@"%@: %@", reply.username, reply.content];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:replyText];
        
        // 设置用户名为粗体
        NSRange usernameRange = [replyText rangeOfString:[NSString stringWithFormat:@"%@:", reply.username]];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont pingFangMediumWithSize:13] range:usernameRange];
        
        replyLabel.attributedText = attributedString;
        [replyView addSubview:replyLabel];
        
        // 设置约束
        [replyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastView.mas_bottom).offset(topOffset);
            make.left.equalTo(self.contentView).offset(60); // 缩进，与主评论区分
            make.right.equalTo(self.contentView).offset(-16);
        }];
        
        [replyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(replyView).insets(UIEdgeInsetsMake(8, 8, 8, 8));
        }];
        
        
        // 更新最后一个视图引用
        lastView = replyView;
    }
}


- (void)expandButtonTapped {
    if (self.expandHandler) {
        self.expandHandler();
    }
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

#pragma mark - SLSimpleInteractionBarDelegate

- (void)interactionBar:(SLSimpleInteractionBar *)interactionBar didTapLikeWithSelected:(BOOL)selected {
    // 处理点赞事件
}

- (void)interactionBar:(SLSimpleInteractionBar *)interactionBar didTapDislikeWithSelected:(BOOL)selected {
    // 处理不喜欢事件
}

- (void)interactionBarDidTapReply:(SLSimpleInteractionBar *)interactionBar {
    // 处理回复事件
}

@end
