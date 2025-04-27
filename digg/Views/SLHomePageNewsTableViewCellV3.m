//
//  SLHomePageNewsTableViewCellV2.m
//  digg
//
//  Created by Tim Bao on 2025/4/14.
//

#import "SLHomePageNewsTableViewCellV3.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLHomeTagViewV2.h"
#import "SLColorManager.h"
#import "SLInteractionBar.h"
#import "SDWebImage/SDWebImage.h"

@interface SLHomePageNewsTableViewCellV3 () <SLInteractionBarDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) SLInteractionBar *interactionBar;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) SLHomeTagViewV2 *tagView;
@property (nonatomic, strong) SLArticleTodayEntity *entity;
@property (nonatomic, strong) UIImageView* smallImageView;
@property (nonatomic, strong) UIImageView* bigImageView;

@end

@implementation SLHomePageNewsTableViewCellV3

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
    self.smallImageView.hidden = YES;
    self.bigImageView.hidden = YES;
    self.contentLabel.hidden = YES;

    self.titleLabel.text = entiy.title;
    self.contentLabel.text = nil;
    self.contentLabel.attributedText = nil;

    CGFloat lineSpacing = 4;
    CGFloat offset = 16;
    
    if (stringIsEmpty(entiy.label)) {
        self.tagView.hidden = YES;
        
        if (entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
            [self.smallImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
            [self.bigImageView setHidden:YES];
            [self.smallImageView setHidden:NO];
            
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView).offset(offset);
                make.right.equalTo(self.smallImageView.mas_left).offset(-offset);
                make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
            }];
        } else if (entiy.picSize == 1 && entiy.mainPicUrl.length > 0) {
            [self.bigImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
            [self.smallImageView setHidden:YES];
            [self.bigImageView setHidden:NO];
            
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView).offset(offset);
                make.top.equalTo(self.bigImageView.mas_bottom).offset(offset);
                make.right.equalTo(self.contentView).offset(-offset);
            }];
        } else {
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView).offset(offset);
                make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
                make.right.equalTo(self.contentView).offset(-offset);
            }];
        }
    } else {
        self.tagView.hidden = NO;
        [self.tagView updateWithLabel:entiy.label];

        if (entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
            [self.smallImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
            [self.bigImageView setHidden:YES];
            [self.smallImageView setHidden:NO];
            
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
                make.left.equalTo(self.tagView.mas_right).offset(8);
                make.right.equalTo(self.smallImageView.mas_left).offset(-offset);
            }];
        } else if (entiy.picSize == 1 && entiy.mainPicUrl.length > 0) {
            [self.bigImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
            [self.smallImageView setHidden:YES];
            [self.bigImageView setHidden:NO];
            
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.tagView.mas_right).offset(8);
                make.top.equalTo(self.bigImageView.mas_bottom).offset(offset);
                make.right.equalTo(self.contentView).offset(-offset);
            }];
        } else {
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.tagView.mas_right).offset(8);
                make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
                make.right.equalTo(self.contentView).offset(-offset);
            }];
        }
    }

    BOOL hasContent = entiy.content != nil && entiy.content.length > 0;
    if (hasContent) {
        self.contentLabel.hidden = NO;
        
        NSString *cleanedContent = [entiy.content stringByReplacingOccurrencesOfString:@"\\U0000fffc\\n\\n" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, entiy.content.length)];
        NSString *contentStr = [cleanedContent stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
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
            make.right.equalTo(self.titleLabel);
        }];
        
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.top.equalTo(self.contentLabel.mas_bottom);
            make.left.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.titleLabel);
            make.bottom.equalTo(self.contentView);
        }];
    } else {
        [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
        
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.top.equalTo(self.titleLabel.mas_bottom);
            make.left.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.titleLabel);
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

- (void)createViews{
    [self.contentView addSubview:self.smallImageView];
    [self.contentView addSubview:self.bigImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.interactionBar];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.tagView];
    
    CGFloat offset = 16;
    
    [self.smallImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
        make.right.equalTo(self.contentView).offset(-offset);
        make.size.mas_equalTo(CGSizeMake(79, 64));
    }];
    
    [self.bigImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.height.mas_equalTo(167);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.centerY.equalTo(self.titleLabel);
        make.height.equalTo(@20);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagView.mas_right).offset(5);
        make.top.equalTo(self.contentView).offset(CELL_CONTENT_V_SPACE);
        make.right.equalTo(self.contentView).offset(-offset);
    }];
    
    [self.tagView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                            forAxis:UILayoutConstraintAxisHorizontal];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(CELL_CONTENT_V_SPACE);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(0);
    }];
    
    [self.interactionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(48);
        make.top.equalTo(self.contentLabel.mas_bottom);
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.titleLabel);
        make.bottom.equalTo(self.contentView);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
}

- (void)tagClick {
    if (self.labelClick) {
        self.labelClick(self.entity);
    }
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
        _contentLabel.numberOfLines = 3;
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

- (SLHomeTagViewV2 *)tagView {
    if (!_tagView) {
        _tagView = [[SLHomeTagViewV2 alloc] init];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagClick)];
        [_tagView addGestureRecognizer:tap];
    }
    return _tagView;
}

- (UIImageView *)smallImageView {
    if (!_smallImageView) {
        _smallImageView = [[UIImageView alloc] init];
        _smallImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_smallImageView setHidden:YES];
        _smallImageView.layer.masksToBounds = YES;
        _smallImageView.layer.cornerRadius = 4;
    }
    return _smallImageView;
}

- (UIImageView *)bigImageView {
    if (!_bigImageView) {
        _bigImageView = [[UIImageView alloc] init];
        _bigImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_bigImageView setHidden:YES];
        _bigImageView.layer.masksToBounds = YES;
        _bigImageView.layer.cornerRadius = 4;
    }
    return _bigImageView;
}

@end
