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
#import "NSString+UXing.h"

@interface SLSecondCommentCell () <SLSimpleInteractionBarDelegate, UITextViewDelegate>

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
    self.contentLabel = [[UITextView alloc] init];
    self.contentLabel.font = [UIFont pingFangRegularWithSize:14];
    self.contentLabel.textColor = Color16(0x313131);
    self.contentLabel.editable = NO; // 设置为不可编辑
    self.contentLabel.scrollEnabled = NO; // 禁用滚动
    self.contentLabel.backgroundColor = [UIColor clearColor]; // 背景透明
    self.contentLabel.textContainerInset = UIEdgeInsetsZero; // 移除内边距
    self.contentLabel.textContainer.lineFragmentPadding = 0; // 移除行间距内边距
    self.contentLabel.delegate = self; // 设置代理
    self.contentLabel.dataDetectorTypes = UIDataDetectorTypeLink; // 启用链接检测
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
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [self.usernameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(18);
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
    }];
    
    [self.tagView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.usernameLabel);
        make.left.equalTo(self.usernameLabel.mas_right).offset(4);
    }];
    
    [self.timeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(1);
        make.left.equalTo(self.usernameLabel);
    }];
    
    [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(44);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [self.interactionBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(16);
        make.left.equalTo(self.contentView).offset(44);
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
    if (comment.replyToSecondComment && comment.replyUsername.length > 0) {
        // 1. 转换 HTML 内容为富文本
        NSAttributedString *htmlAttributedString = [comment.content attributedStringFromHTML];

        // 2. 构建完整文本
        NSString *prefixString = [NSString stringWithFormat:@"回复@%@ : ", comment.replyUsername];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:prefixString];

        // 3. 设置前缀文本的样式
        // 设置整体颜色
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:Color16(0x313131)
                                 range:NSMakeRange(0, prefixString.length)];

        // 4. 设置 @username 的特殊颜色
        NSString *atString = [NSString stringWithFormat:@"@%@", comment.replyUsername];
        NSRange atRange = [prefixString rangeOfString:atString];
        if (atRange.location != NSNotFound) {
            [attributedString addAttribute:NSForegroundColorAttributeName
                                     value:Color16(0x666666)
                                     range:atRange];
        }

        // 5. 拼接 HTML 内容
        if (htmlAttributedString) {
            [attributedString appendAttributedString:htmlAttributedString];
        }

        // 6. 设置统一字体（覆盖HTML可能携带的字体）
        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont pingFangRegularWithSize:14]
                                 range:NSMakeRange(0, attributedString.length)];

        // 7. 设置行间距
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:4.0];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        [attributedString addAttribute:NSParagraphStyleAttributeName 
                                 value:paragraphStyle 
                                 range:NSMakeRange(0, attributedString.length)];

        self.contentLabel.attributedText = attributedString;        
    } else {
        self.contentLabel.attributedText = [comment.content attributedStringFromHTML];
    }
    
    // 调整 UITextView 的大小
    CGSize contentSize = [self.contentLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    [self.contentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(contentSize.height);
    }];
    
    [self.interactionBar updateLikeNumber:comment.likeCount];
    [self.interactionBar updateDislikeNumber:comment.dislikeCount];
    [self.interactionBar setLikeSelected:[comment.disliked isEqualToString:@"true"]];
    [self.interactionBar setDislikeSelected:[comment.disliked isEqualToString:@"false"]];
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

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    // 处理链接点击事件
    if (URL) {
        // 可以在这里添加自定义处理逻辑，例如打开内部浏览器
        // 如果有专门的处理方法，可以调用它
        if (self.linkTapHandler) {
            self.linkTapHandler(URL);
            return NO; // 返回 NO 表示我们自己处理，不使用系统默认行为
        }
        
        // 如果没有自定义处理，使用系统默认行为打开链接
        return YES;
    }
    return YES;
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
