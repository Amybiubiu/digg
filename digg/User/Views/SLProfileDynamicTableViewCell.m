//
//  SLProfileDynamicTableViewCell.m
//  digg
//
//  Created by Tim Bao on 2025/1/8.
//

#import "SLProfileDynamicTableViewCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLHomeTagView.h"
#import "SDWebImage.h"
#import "SLColorManager.h"
#import "SLInteractionBar.h"

@interface SLProfileDynamicTableViewCell () <SLInteractionBarDelegate>

@property (nonatomic, strong) UIImageView* avatarImageView;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) SLInteractionBar *interactionBar;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) SLArticleTodayEntity *entity;
@property (nonatomic, assign) BOOL isSelected;

@end

@implementation SLProfileDynamicTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self){
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        self.contentView.backgroundColor = [SLColorManager primaryBackgroundColor];
        [self createViews];
    }
    return self;
}

- (void)updateWithEntity:(SLArticleTodayEntity *)entiy{
    self.entity = entiy;
    if (entiy.avatar) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:entiy.avatar]];
    } else if (entiy.userAvatar) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:entiy.userAvatar]];
    }
    self.nickNameLabel.text = entiy.username;
    if ([entiy.actionName length] > 0) {
        //格式化时间
        NSDate *detailDate = [NSDate dateWithTimeIntervalSince1970:entiy.gmtCreate/1000];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSString *dateStr = [dateFormatter stringFromDate: detailDate];
        self.timeLabel.text = [NSString stringWithFormat:@"%@ · %@", dateStr, entiy.actionName];
    }

    self.titleLabel.text = entiy.title;
    CGFloat lineSpacing = 3;
    CGFloat offset = 16;
    
    // 判断内容是否为空
    BOOL hasContent = entiy.content != nil && entiy.content.length > 0;
    
    if (hasContent) {
        // 有内容时显示contentLabel
        self.contentLabel.hidden = NO;
        
        NSString *contentStr = [entiy.content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = lineSpacing;
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[UIFont pingFangLightWithSize:14] forKey:NSFontAttributeName];
        [attributes setObject:[SLColorManager cellContentColor] forKey:NSForegroundColorAttributeName];
        [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
        self.contentLabel.attributedText = [[NSAttributedString alloc] initWithString:contentStr attributes:attributes];

        [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(offset);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(CELL_CONTENT_V_SPACE);
            make.right.equalTo(self.contentView).offset(-offset);
        }];
        
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.top.equalTo(self.contentLabel.mas_bottom);
            make.left.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.contentView).offset(-offset);
            make.bottom.equalTo(self.contentView);
        }];
    } else {
        // 内容为空时隐藏contentLabel并调整interactionBar位置
        self.contentLabel.hidden = YES;
        self.contentLabel.attributedText = nil;
        
        // 移除contentLabel的所有约束
        [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
        
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.top.equalTo(self.titleLabel.mas_bottom);
            make.left.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.contentView).offset(-offset);
            make.bottom.equalTo(self.contentView);
        }];
    }
    
    // 根据数据更新交互栏
    [self.interactionBar updateNumber:entiy.likeCnt forType:SLInteractionTypeLike];
    [self.interactionBar updateNumber:entiy.dislikeCnt forType:SLInteractionTypeDislike];
    [self.interactionBar updateNumber:entiy.commentsCnt forType:SLInteractionTypeComment];
    
    // 设置选中状态
    [self.interactionBar setSelected:entiy.liked forType:SLInteractionTypeLike];
    [self.interactionBar setSelected:entiy.disliked forType:SLInteractionTypeDislike];
}

- (void)createViews {
    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.interactionBar];
    [self.contentView addSubview:self.lineView];
    
    CGFloat offset = 16;

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
        make.size.mas_equalTo(CGSizeMake(26, 26));
    }];
    
    [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.centerY.equalTo(self.avatarImageView);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nickNameLabel.mas_right).offset(8);
        make.centerY.equalTo(self.avatarImageView);
        make.right.lessThanOrEqualTo(self.contentView).offset(-offset);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(CELL_CONTENT_V_SPACE);
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
    }];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(CELL_CONTENT_V_SPACE);
        make.right.equalTo(self.contentView).offset(-offset);
    }];
    
    [self.interactionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(48);
        make.top.equalTo(self.contentLabel.mas_bottom);
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.bottom.equalTo(self.contentView);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
}

#pragma mark - SLInteractionBarDelegate

- (void)interactionBar:(SLInteractionBar *)interactionBar didTapItemWithType:(SLInteractionType)type selected:(BOOL)selected {
    switch (type) {
        case SLInteractionTypeLike:
            if (selected) {
                if (self.likeClick) {
                    self.likeClick(self.entity);
                }
                [interactionBar updateNumber:self.entity.likeCnt + 1 forType:SLInteractionTypeLike];
                [interactionBar updateNumber:self.entity.dislikeCnt forType:SLInteractionTypeDislike];
                [interactionBar setSelected:NO forType:SLInteractionTypeDislike];
            } else {
                if (self.cancelLikeClick) {
                    self.cancelLikeClick(self.entity);
                }
                [interactionBar updateNumber:self.entity.likeCnt forType:SLInteractionTypeLike];
            }
            break;
        case SLInteractionTypeDislike:
            if (selected) {
                if (self.dislikeClick) {
                    self.dislikeClick(self.entity);
                }
                
                [interactionBar updateNumber:self.entity.likeCnt forType:SLInteractionTypeLike];
                [interactionBar updateNumber:self.entity.dislikeCnt + 1 forType:SLInteractionTypeDislike];
                [interactionBar setSelected:NO forType:SLInteractionTypeLike];
            } else {
                if (self.cancelDisLikeClick) {
                    self.cancelDisLikeClick(self.entity);
                }
                
                [interactionBar updateNumber:self.entity.dislikeCnt forType:SLInteractionTypeDislike];
            }
            break;
        case SLInteractionTypeComment:
            if (self.showDetailClick) {
                self.showDetailClick(self.entity);
            }
            break;
        case SLInteractionTypeCustom:
            if (self.checkDetailClick) {
                self.checkDetailClick(self.entity);
            }
            break;
        default:
            break;
    }
}

#pragma mark - Property
- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.backgroundColor = UIColor.lightGrayColor;
        _avatarImageView.layer.cornerRadius = 13;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UILabel *)nickNameLabel {
    if(!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont pingFangRegularWithSize:14];
        _nickNameLabel.textColor = [SLColorManager cellNickNameColor];
    }
    return _nickNameLabel;
}

- (UILabel *)timeLabel {
    if(!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont pingFangRegularWithSize:12];
        _timeLabel.textColor = Color16(0xB6B6B6);
        [_timeLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        _timeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _timeLabel;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont pingFangSemiboldWithSize:16];
        _titleLabel.textColor = [SLColorManager cellTitleColor];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if(!_contentLabel){
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont pingFangLightWithSize:14];
        _contentLabel.numberOfLines = 2;
        _contentLabel.textColor = [SLColorManager cellContentColor];
    }
    return _contentLabel;
}

- (SLInteractionBar *)interactionBar {
    if (!_interactionBar) {
        _interactionBar = [[SLInteractionBar alloc] initWithFrame:CGRectZero
                                            interactionTypes:@[
                                                @(SLInteractionTypeLike),
                                                @(SLInteractionTypeDislike),
                                                @(SLInteractionTypeComment),
                                                @(SLInteractionTypeCustom)
                                            ]];
        _interactionBar.delegate = self;
    }
    return _interactionBar;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _lineView;
}

@end
