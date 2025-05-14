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
#import "SLSecondCommentCell.h"
#import "NSString+UXing.h"

@interface SLCommentCell () <SLSimpleInteractionBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *sectionSegment;
@property (nonatomic, strong) UITableView *secondaryCommentsTableView;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIButton *showMoreButton;
@property (nonatomic, strong) NSMutableArray<SLCommentEntity *> *secondaryComments;
@property (nonatomic, strong) NSMutableArray<SLCommentEntity *> *displayedSecondaryComments;
@property (nonatomic, strong) NSString* authorId;

@end

@implementation SLCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        self.contentView.backgroundColor = UIColor.clearColor;
        self.secondaryComments = [NSMutableArray array];
        self.displayedSecondaryComments = [NSMutableArray array];
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    //分割条
    self.sectionSegment = [UIView new];
    self.sectionSegment.backgroundColor = Color16(0xF6F6F6);
    [self.contentView addSubview:self.sectionSegment];
    
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

    // 创建二级评论表格视图
    self.secondaryCommentsTableView = [[UITableView alloc] init];
    self.secondaryCommentsTableView.delegate = self;
    self.secondaryCommentsTableView.dataSource = self;
    self.secondaryCommentsTableView.scrollEnabled = NO;
    self.secondaryCommentsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.secondaryCommentsTableView.backgroundColor = [UIColor clearColor];
    self.secondaryCommentsTableView.estimatedRowHeight = 80;
    self.secondaryCommentsTableView.rowHeight = UITableViewAutomaticDimension;
    [self.secondaryCommentsTableView registerClass:[SLSecondCommentCell class] forCellReuseIdentifier:@"SecondaryCommentCell"];
    self.secondaryCommentsTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (@available(iOS 15.0, *)) {
        self.secondaryCommentsTableView.sectionHeaderTopPadding = 0;
    }
    self.secondaryCommentsTableView.hidden = YES;
    [self.contentView addSubview:self.secondaryCommentsTableView];
    
    self.line = [UIView new];
    self.line.backgroundColor = Color16(0xEEEEEE);
    self.line.hidden = YES;
    [self.contentView addSubview:self.line];
    
    // 创建"展开更多评论"按钮
    self.showMoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showMoreButton setTitle:@"展开更多评论" forState:UIControlStateNormal];
    self.showMoreButton.titleLabel.font = [UIFont pingFangRegularWithSize:14];
    [self.showMoreButton setTitleColor:Color16(0x14932A) forState:UIControlStateNormal];
    [self.showMoreButton addTarget:self action:@selector(showMoreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.showMoreButton.hidden = YES;
    [self.contentView addSubview:self.showMoreButton];
}

- (void)setupConstraints {
    // 设置约束
    [self.sectionSegment mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(7);
    }];
    
    [self.avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionSegment.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(16);
        make.size.mas_equalTo(CGSizeMake(30, 30));
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
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(1);
    }];
    
    [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(0);
    }];
    
    [self.interactionBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(16);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [self.secondaryCommentsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.interactionBar.mas_bottom).offset(8);
        make.left.equalTo(self.contentView);
        make.right.equalTo(self.contentView);
        make.height.mas_equalTo(0);
    }];
    
    [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(44);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];
    
    [self.line mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.centerY.equalTo(self.showMoreButton);
        make.height.mas_equalTo(1);
        make.width.mas_equalTo(20);
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
    if (comment.content.length > 0) {
        self.contentLabel.attributedText = [comment.content attributedStringFromHTML];
        CGFloat contentHeight = [self heightForAttributedString:self.contentLabel.attributedText withWidth:width];
        [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(contentHeight);
        }];
//        [self.contentLabel sizeToFit];
    } else { // 处理内容为空的情况，确保高度为0
        self.contentLabel.text = nil; // 清空文本
        [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }
    
    [self.interactionBar updateLikeNumber:comment.likeCount];
    [self.interactionBar updateDislikeNumber:comment.dislikeCount];
    [self.interactionBar setLikeSelected:[comment.disliked isEqualToString:@"true"]];
    [self.interactionBar setDislikeSelected:[comment.disliked isEqualToString:@"false"]];

    // 处理二级评论
    [self.secondaryComments removeAllObjects];
    [self.displayedSecondaryComments removeAllObjects];
    if (comment.replyList && comment.replyList.count > 0) {
        self.secondaryCommentsTableView.hidden = NO;
        // 更新二级评论列表
        [self updateRepliesWithList:comment.replyList 
                        expandCount:comment.expandedRepliesCount];
    } else {
        self.secondaryCommentsTableView.hidden = YES;
        self.showMoreButton.hidden = YES;
        self.line.hidden = YES;
        
        [self.secondaryCommentsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.interactionBar.mas_bottom).offset(0);
            make.left.equalTo(self.contentView);
            make.right.equalTo(self.contentView);
            make.height.mas_equalTo(0);
        }];
        
        [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(0);
            make.left.equalTo(self.contentView).offset(44);
            make.height.mas_equalTo(0);
            make.bottom.equalTo(self.contentView).offset(-8);
        }];
    }

     [self setNeedsLayout];
     [self layoutIfNeeded];
     self.contentLabel.preferredMaxLayoutWidth = self.contentLabel.frame.size.width;
}

- (void)updateRepliesWithList:(NSArray<SLCommentEntity *> *)replyList expandCount:(NSInteger)expandCount {
    // 保存所有二级评论
    if (replyList && replyList.count > 0) {
        [self.secondaryComments addObjectsFromArray:replyList];
        
        // 初始只显示第一条评论
        NSInteger count = MIN(expandCount, replyList.count);
        for (NSInteger i = 0; i < count; i++) {
            [self.displayedSecondaryComments addObject:replyList[i]];
        }
        
        if (self.displayedSecondaryComments.count == 0) {
            [self.displayedSecondaryComments addObject:replyList[0]];
        }
        
        // 更新UI
        self.secondaryCommentsTableView.hidden = NO;
        self.line.hidden = self.showMoreButton.hidden = (self.displayedSecondaryComments.count >= self.secondaryComments.count);
        [self.secondaryCommentsTableView reloadData];
        // 更新表格视图高度
        [self updateSecondaryCommentsTableViewHeight];
    } else {
        self.secondaryCommentsTableView.hidden = YES;
        self.showMoreButton.hidden = YES;
        self.line.hidden = YES;
        
        [self.secondaryCommentsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.interactionBar.mas_bottom).offset(0);
            make.left.equalTo(self.contentView);
            make.right.equalTo(self.contentView);
            make.height.mas_equalTo(0);
        }];
        
        [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(0);
            make.left.equalTo(self.contentView).offset(44);
            make.height.mas_equalTo(0);
            make.bottom.equalTo(self.contentView).offset(-8);
        }];
    }
}

- (void)updateSecondaryCommentsTableViewHeight {
    // 计算表格视图的高度
    // [self.secondaryCommentsTableView layoutIfNeeded];
    CGFloat totalHeight = 0;
    // for (NSInteger i = 0; i < self.displayedSecondaryComments.count; i++) {
    //     CGFloat cellHeight = [self tableView:self.secondaryCommentsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    //     totalHeight += cellHeight;
    // }
    NSInteger numberOfRows = 0;
    if (self.secondaryCommentsTableView.dataSource && [self.secondaryCommentsTableView.dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        numberOfRows = [self.secondaryCommentsTableView.dataSource tableView:self.secondaryCommentsTableView numberOfRowsInSection:0];
    }
    for (NSInteger i = 0; i < numberOfRows; i++) {
        CGFloat cellHeight = 0;
        // 使用 delegate 获取准确的行高
        if (self.secondaryCommentsTableView.delegate && [self.secondaryCommentsTableView.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            cellHeight = [self.secondaryCommentsTableView.delegate tableView:self.secondaryCommentsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        totalHeight += cellHeight;
    }
    
    // 更新表格视图高度约束
    [self.secondaryCommentsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.interactionBar.mas_bottom).offset(8);
        make.left.equalTo(self.contentView);
        make.right.equalTo(self.contentView);
        make.height.mas_equalTo(totalHeight);
    }];
    
    if (!self.showMoreButton.hidden) {
        [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(8);
            make.left.equalTo(self.contentView).offset(44);
            make.height.mas_equalTo(20);
            make.bottom.equalTo(self.contentView).offset(-24);
        }];
    } else {
        [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(0);
            make.left.equalTo(self.contentView).offset(44);
            make.height.mas_equalTo(0);
            make.bottom.equalTo(self.contentView).offset(-8);
        }];
    }
}

- (void)showMoreButtonTapped {
    // 计算还有多少评论可以加载
    NSInteger remainingComments = self.secondaryComments.count - self.displayedSecondaryComments.count;
    NSInteger commentsToAdd = MIN(5, remainingComments);
    
    NSMutableArray * insertNodeRows = [NSMutableArray array];
    if (commentsToAdd > 0) {
        [self.secondaryCommentsTableView beginUpdates];

        // 添加下一批评论
        NSInteger startIndex = self.displayedSecondaryComments.count;
        for (NSInteger i = 0; i < commentsToAdd; i++) {
            if (startIndex + i < self.secondaryComments.count) {
                [self.displayedSecondaryComments insertObject:self.secondaryComments[startIndex + i] atIndex:startIndex + i];
                [insertNodeRows addObject:[NSIndexPath indexPathForRow:startIndex + i inSection:0]];
            }
        }
        
        // 使用 UITableViewRowAnimationAutomatic 以获得更平滑的视觉效果，如果需要无动画，则用 UITableViewRowAnimationNone
        [self.secondaryCommentsTableView insertRowsAtIndexPaths:[NSArray arrayWithArray:insertNodeRows] withRowAnimation:UITableViewRowAnimationBottom];

        [self.secondaryCommentsTableView endUpdates];
        
        // 如果所有评论都已加载，隐藏"展开更多评论"按钮
        if (self.displayedSecondaryComments.count >= self.secondaryComments.count) {
            self.showMoreButton.hidden = YES;
            self.line.hidden = YES;
            [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(0);
                make.left.equalTo(self.contentView).offset(44);
                make.height.mas_equalTo(0);
                make.bottom.equalTo(self.contentView).offset(-8);
            }];
        } else {
            self.showMoreButton.hidden = NO;
            self.line.hidden = NO;
            [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.secondaryCommentsTableView.mas_bottom).offset(8);
                make.left.equalTo(self.contentView).offset(44);
                make.height.mas_equalTo(20);
                make.bottom.equalTo(self.contentView).offset(-24);
            }];
        }
        
        // [self.secondaryCommentsTableView layoutIfNeeded];
        CGFloat totalHeight = 0;
        for (NSInteger i = 0; i < self.displayedSecondaryComments.count; i++) {
            CGFloat cellHeight = [self tableView:self.secondaryCommentsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            totalHeight += cellHeight;
        }
        [self.secondaryCommentsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(totalHeight);
        }];
        
        // 更新 comment 中的展开数量
        self.comment.expandedRepliesCount = self.displayedSecondaryComments.count;
        if (self.expandHandler) {
            self.expandHandler(self.comment, self.index);
        }
    }
}

- (UITableView *)findParentTableView {
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UITableView class]]) {
            return (UITableView *)superview;
        }
        superview = superview.superview;
    }
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedSecondaryComments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.displayedSecondaryComments.count) {
        return nil;
    }
    SLCommentEntity *secondaryComment = self.displayedSecondaryComments[indexPath.row];
    SLSecondCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SecondaryCommentCell"];
    if (!cell) {
        cell = [[SLSecondCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SecondaryCommentCell"];
    }
    [cell prepareForReuse];
    // 配置二级评论单元格
    [cell updateWithComment:secondaryComment authorId:self.authorId contentWidth:tableView.frame.size.width - 60];
        
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 根据内容动态计算高度
    if (indexPath.row >= self.displayedSecondaryComments.count) {
        return 0;
    }
    SLCommentEntity *secondaryComment = self.displayedSecondaryComments[indexPath.row];
    
    CGFloat baseHeight = 16 + 30 + 8;
    CGFloat contentWidth = tableView.frame.size.width - 60;
    
    CGFloat contentHeight = 0;
    if (secondaryComment.replyToSecondComment && secondaryComment.replyUsername.length > 0) {
        NSAttributedString *htmlAttributedString = [secondaryComment.content attributedStringFromHTML];

        NSString *prefixString = [NSString stringWithFormat:@"回复@%@ : ", secondaryComment.replyUsername];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:prefixString];

        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:Color16(0x313131)
                                 range:NSMakeRange(0, prefixString.length)];

        NSString *atString = [NSString stringWithFormat:@"@%@", secondaryComment.replyUsername];
        NSRange atRange = [prefixString rangeOfString:atString];
        if (atRange.location != NSNotFound) {
            [attributedString addAttribute:NSForegroundColorAttributeName
                                     value:Color16(0x666666)
                                     range:atRange];
        }
        if (htmlAttributedString) {
            [attributedString appendAttributedString:htmlAttributedString];
        }

        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont pingFangRegularWithSize:14]
                                 range:NSMakeRange(0, attributedString.length)];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:8.0];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        [attributedString addAttribute:NSParagraphStyleAttributeName
                                 value:paragraphStyle
                                 range:NSMakeRange(0, attributedString.length)];
        contentHeight = [self heightForAttributedString:attributedString withWidth:contentWidth];
    } else {
        contentHeight = [self heightForAttributedString:[secondaryComment.content attributedStringFromHTML] withWidth:contentWidth];
    }

    return baseHeight + contentHeight + 12 + 16 + 8;
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString
                          withWidth:(CGFloat)width {
    if (!attributedString) return 0;
    
    // 计算尺寸的约束
    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
    
    // 计算矩形
    CGRect boundingRect = [attributedString boundingRectWithSize:constraintSize
                                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                         context:nil];
    
    // 返回向上取整的高度
    return ceil(boundingRect.size.height);
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
