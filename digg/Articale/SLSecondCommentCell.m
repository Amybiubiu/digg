//
//  SLSecondCommentCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLSecondCommentCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import <SDWebImage/SDWebImage.h>
#import "SLArticleEntity.h"

@interface SLSecondCommentCell () <SLSimpleInteractionBarDelegate>

@property (nonatomic, strong) NSString* authorId;

@end

@implementation SLSecondCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        self.contentView.backgroundColor = UIColor.clearColor;
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.layer.cornerRadius = 15;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.clipsToBounds = YES;
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
}

- (void)setupConstraints {
    // 设置约束
    [self.avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(44);
        make.top.equalTo(self.contentView).offset(16);
        make.size.mas_equalTo(CGSizeMake(30, 30)).priorityHigh;
    }];
    
    [self.usernameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.top.equalTo(self.contentView).offset(18);
    }];
    
    [self.tagView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.usernameLabel);
        make.left.equalTo(self.usernameLabel.mas_right).offset(4);
    }];
    
    [self.timeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(1);
    }];
    
    [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(8);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_greaterThanOrEqualTo(0);
    }];
    
    [self.interactionBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(16);
        make.left.equalTo(self.avatarImageView);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];
}

- (void)updateWithComment:(SLCommentEntity *)comment authorId:(NSString *)authorId contentWidth:(CGFloat)width {

    self.comment = comment;
    self.authorId = authorId;
    
    // 设置头像
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:comment.avatar]
                            placeholderImage:[UIImage imageNamed:@"default_avatar"]];

    // 设置用户名
    self.usernameLabel.text = comment.username;
    CGSize size = [self.usernameLabel sizeThatFits:CGSizeZero];
    [self.usernameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(size.width);
    }];
    self.tagView.hidden = !(comment.userId == authorId);
    
    // 设置时间
    NSDate *commentDate = [NSDate dateWithTimeIntervalSince1970:[comment.gmtCreate doubleValue]/1000];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    self.timeLabel.text = [dateFormatter stringFromDate:commentDate];
    
    // 设置内容
    if (comment.replyToArticle || comment.replyToComment) {
        self.contentLabel.text = comment.content;
    } else if (comment.replyToSecondComment) {
        if (comment.replyUsername.length > 0) {
            self.contentLabel.text = [NSString stringWithFormat:@"回复:%@ : %@", comment.replyUsername, comment.content];
        } else {
            self.contentLabel.text = comment.content;
        }
    }
    [self.contentLabel sizeToFit];
    CGFloat contentHeight = [self heightForText:self.contentLabel.text
                                       withFont:[UIFont pingFangRegularWithSize:14] width:width];
    [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(contentHeight);
    }];
    
    [self.interactionBar updateLikeNumber:comment.likeCount];
    [self.interactionBar updateDislikeNumber:comment.dislikeCount];
    [self.interactionBar setLikeSelected:[comment.disliked isEqualToString:@"true"]];
    [self.interactionBar setDislikeSelected:[comment.disliked isEqualToString:@"false"]];

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (CGFloat)heightForText:(NSString *)text withFont:(UIFont *)font width:(CGFloat)width {
    if (!text || text.length == 0) {
        return 0;
    }
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName: font}
                                     context:nil];
    return ceil(rect.size.height);
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
