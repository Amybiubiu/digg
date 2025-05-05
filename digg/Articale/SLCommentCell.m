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

@end

@implementation SLCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        _replyViews = [NSMutableArray array];
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
        make.top.equalTo(self.contentView).offset(19);
        make.width.height.equalTo(@30);
    }];
    
    [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.top.equalTo(self.contentView).offset(18);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(1);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.timeLabel.mas_bottom).offset(4);
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
    
    // 设置头像
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:comment.avatar]
                            placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    
    // 设置用户名
    self.usernameLabel.text = comment.username;
    
    // 设置时间
    NSDate *commentDate = [NSDate dateWithTimeIntervalSince1970:[comment.gmtCreate doubleValue]/1000];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    self.timeLabel.text = [dateFormatter stringFromDate:commentDate];
    
    // 设置内容
    self.contentLabel.text = comment.content;
    
    // 设置点赞状态
    self.likeButton.selected = comment.disliked;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)comment.likeCount];
    
    // 如果有回复，更新回复视图
    if (comment.replyList.count > 0) {
        [self updateRepliesWithList:comment.replyList isCollapsed:YES totalCount:comment.replyList.count];
    } else {
        // 清除现有回复视图
        for (UIView *view in self.replyViews) {
            [view removeFromSuperview];
        }
        [self.replyViews removeAllObjects];
    }
}

- (void)updateRepliesWithList:(NSArray<SLCommentEntity *> *)replyList isCollapsed:(BOOL)isCollapsed totalCount:(NSInteger)totalCount {
    // 清除现有回复视图
    for (UIView *view in self.replyViews) {
        [view removeFromSuperview];
    }
    [self.replyViews removeAllObjects];
    
    // 添加回复视图
    [self addReplyViews:replyList];
    
    // 如果回复数量超过2条且处于收起状态，添加"展开x条评论"按钮
    if (totalCount > 2 && isCollapsed) {
        [self addExpandButton:totalCount];
    } 
    // 如果已展开，添加"收起评论"按钮
    else if (totalCount > 2 && !isCollapsed) {
        [self addCollapseButton];
    }
    
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
        
        // 添加到回复视图数组
        [self.replyViews addObject:replyView];
        
        // 更新最后一个视图引用
        lastView = replyView;
    }
}

- (void)addExpandButton:(NSInteger)totalCount {
    UIButton *expandButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [expandButton setTitle:[NSString stringWithFormat:@"展开%ld条评论", (long)totalCount - 2] forState:UIControlStateNormal];
    expandButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [expandButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [expandButton addTarget:self action:@selector(expandButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:expandButton];
    
    // 设置约束
    [expandButton mas_makeConstraints:^(MASConstraintMaker *make) {
        UIView *lastView = [self.replyViews lastObject] ?: self.contentLabel;
        make.top.equalTo(lastView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(60); // 与回复内容对齐
        make.height.equalTo(@30);
    }];
    
    [self.replyViews addObject:expandButton];
}

- (void)addCollapseButton {
    UIButton *collapseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [collapseButton setTitle:@"收起评论" forState:UIControlStateNormal];
    collapseButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [collapseButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [collapseButton addTarget:self action:@selector(collapseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:collapseButton];
    
    // 设置约束
    [collapseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        UIView *lastView = [self.replyViews lastObject] ?: self.contentLabel;
        make.top.equalTo(lastView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(60); // 与回复内容对齐
        make.height.equalTo(@30);
    }];
    
    [self.replyViews addObject:collapseButton];
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

@end
