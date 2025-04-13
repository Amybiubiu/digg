//
//  SLHomePageNewsTableViewCell.m
//  digg
//
//  Created by hey on 2024/9/26.
//

#import "SLHomePageNewsTableViewCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "CaocaoButton.h"
#import "SLHomeTagView.h"
#import "SLColorManager.h"

@interface SLHomePageNewsTableViewCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) CaocaoButton *likeBtn;
@property (nonatomic, strong) UILabel *dot1Label;
@property (nonatomic, strong) CaocaoButton *dislikeBtn;
@property (nonatomic, strong) UILabel *dot2Label;
@property (nonatomic, strong) CaocaoButton *messageBtn;
@property (nonatomic, strong) UILabel *dot3Label;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) SLHomeTagView *tagView;
@property (nonatomic, strong) SLArticleTodayEntity *entity;
@property (nonatomic, assign) BOOL isSelected;

@end

@implementation SLHomePageNewsTableViewCell


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

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

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.likeBtn layoutSubviews];
    [self.dislikeBtn layoutSubviews];
    [self.messageBtn layoutSubviews];
}

- (void)updateWithEntity:(SLArticleTodayEntity *)entiy{
    self.entity = entiy;
    self.titleLabel.text = entiy.title;
    CGFloat lineSpacing = 6;
    
    NSString *contentStr = [entiy.content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = lineSpacing;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[UIFont systemFontOfSize:14] forKey:NSFontAttributeName];
    [attributes setObject:[SLColorManager cellContentColor] forKey:NSForegroundColorAttributeName];
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    if (contentStr != nil) {
        self.contentLabel.attributedText = [[NSAttributedString alloc] initWithString:contentStr attributes:attributes];
    } else {
        self.contentLabel.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:attributes];
    }

    [self.likeBtn setTitle:[NSString stringWithFormat:@"%ld",entiy.likeCnt] forState:UIControlStateNormal];
    [self.dislikeBtn setTitle:[NSString stringWithFormat:@"%ld",entiy.dislikeCnt] forState:UIControlStateNormal];
    [self.messageBtn setTitle:[NSString stringWithFormat:@"%ld",entiy.commentsCnt] forState:UIControlStateNormal];

    if (!self.isSelected) {
        //重置
        self.likeBtn.selected = false;
        self.dislikeBtn.selected = false;
    }
    CGFloat offset = 16;

    if (stringIsEmpty(entiy.label)) {
        self.tagView.hidden = YES;
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(offset);
            make.top.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.contentView).offset(-offset);
        }];
    } else {
        self.tagView.hidden = NO;
        [self.tagView updateWithLabel:entiy.label];

        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tagView.mas_right).offset(8);
            make.top.equalTo(self.contentView).offset(offset);
            make.right.equalTo(self.contentView).offset(-offset);
        }];
    }
    
    [self layoutIfNeeded];
}

- (void)createViews{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.likeBtn];
    [self.contentView addSubview:self.dot1Label];
    [self.contentView addSubview:self.dislikeBtn];
    [self.contentView addSubview:self.dot2Label];
    [self.contentView addSubview:self.messageBtn];
    [self.contentView addSubview:self.dot3Label];
    [self.contentView addSubview:self.checkBtn];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.tagView];
    
    CGFloat offset = 16;
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset+2);
        make.top.equalTo(self.contentView).offset(offset);
        make.height.equalTo(@20);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagView.mas_right).offset(8);
        make.top.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
    }];
    
    [self.tagView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                            forAxis:UILayoutConstraintAxisHorizontal];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.right.equalTo(self.contentView).offset(-offset);
    }];
    [self.likeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(34);
        make.top.equalTo(self.contentLabel.mas_bottom).offset(9);
        make.left.equalTo(self.contentView).offset(offset);
        make.bottom.equalTo(self.lineView).offset(-7);
    }];
    
    [self.dot1Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(6, 16));
        make.centerY.equalTo(self.likeBtn.mas_centerY);
        make.left.equalTo(self.likeBtn.mas_right).offset(12);
    }];
    
    [self.dislikeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.dot1Label.mas_right).offset(12);
        make.centerY.equalTo(self.likeBtn.mas_centerY);
        make.height.equalTo(self.likeBtn.mas_height);
    }];
    
    [self.dot2Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(6, 16));
        make.centerY.equalTo(self.dislikeBtn.mas_centerY);
        make.left.equalTo(self.dislikeBtn.mas_right).offset(12);
    }];
    [self.messageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.dot2Label.mas_right).offset(12);
        make.centerY.equalTo(self.likeBtn.mas_centerY);
        make.height.equalTo(self.likeBtn.mas_height);
    }];
    
    [self.dot3Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(6, 16));
        make.centerY.equalTo(self.messageBtn.mas_centerY);
        make.left.equalTo(self.messageBtn.mas_right).offset(12);
    }];
    [self.checkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.dot3Label.mas_right).offset(12);
        make.centerY.equalTo(self.likeBtn.mas_centerY);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)likeBtnAction:(id)sender {
    if (!self.likeBtn.selected) {
        if (self.likeClick) {
            self.likeClick(self.entity);
        }
        [self.likeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.likeCnt + 1] forState:UIControlStateNormal];
        [self.dislikeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.dislikeCnt] forState:UIControlStateNormal];
        
        self.likeBtn.selected = YES;
        self.dislikeBtn.selected = NO;
    } else {
        if (self.cancelLikeClick) {
            self.cancelLikeClick(self.entity);
        }
        if (self.likeBtn.selected) {
            [self.likeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.likeCnt] forState:UIControlStateNormal];
        }
        self.likeBtn.selected = NO;
    }
    
    [self layoutIfNeeded];
}

- (void)dislikeBtnAction:(id)sender {
    if (!self.dislikeBtn.selected) {
        if (self.dislikeClick) {
            self.dislikeClick(self.entity);
        }
        
        [self.likeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.likeCnt] forState:UIControlStateNormal];
        [self.dislikeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.dislikeCnt+1] forState:UIControlStateNormal];
        self.likeBtn.selected = NO;
        self.dislikeBtn.selected = YES;
    } else {
        if (self.cancelDisLikeClick) {
            self.cancelDisLikeClick(self.entity);
        }
        if (self.dislikeBtn.selected) {
            [self.dislikeBtn setTitle:[NSString stringWithFormat:@"%ld",self.entity.dislikeCnt] forState:UIControlStateNormal];
        }
        self.dislikeBtn.selected = NO;
    }
    
    [self layoutIfNeeded];
}

- (void)checkBtnAction:(id)sender{
    if (self.checkDetailClick) {
        self.checkDetailClick(self.entity);
    }
}

- (void)tagClick {
    if (self.labelClick) {
        self.labelClick(self.entity);
    }
}

#pragma mark - Property
- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textColor = [SLColorManager cellTitleColor];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if(!_contentLabel){
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.numberOfLines = 3;
        _contentLabel.textColor = [SLColorManager cellContentColor];
    }
    return _contentLabel;
}

- (CaocaoButton *)likeBtn {
    if(!_likeBtn){
        _likeBtn = [[CaocaoButton alloc] init];
        _likeBtn.imageButtonType = CaocaoRightImageButton;
        _likeBtn.margin = 4;
        [_likeBtn setTitle:@"--" forState:UIControlStateNormal];
        _likeBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_likeBtn setTitleColor:[SLColorManager caocaoButtonTextColor] forState:UIControlStateNormal];
        [_likeBtn setImage:[UIImage imageNamed:@"agree"] forState:UIControlStateNormal];
        [_likeBtn setImage:[UIImage imageNamed:@"agree_selected"] forState:UIControlStateSelected];
        [_likeBtn addTarget:self action:@selector(likeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_likeBtn sizeToFit];
    }
    return _likeBtn;
}

- (CaocaoButton *)dislikeBtn {
    if (!_dislikeBtn) {
        _dislikeBtn = [[CaocaoButton alloc] init];
        _dislikeBtn.margin = 4;
        _dislikeBtn.imageButtonType = CaocaoRightImageButton;
        [_dislikeBtn setTitle:@"--" forState:UIControlStateNormal];
        _dislikeBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_dislikeBtn setTitleColor:[SLColorManager caocaoButtonTextColor] forState:UIControlStateNormal];
        [_dislikeBtn setImage:[UIImage imageNamed:@"disagree"]forState:UIControlStateNormal];
        [_dislikeBtn setImage:[UIImage imageNamed:@"disagree_selected"] forState:UIControlStateSelected];
        [_dislikeBtn addTarget:self action:@selector(dislikeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_dislikeBtn sizeToFit];
    }
    return _dislikeBtn;
}

- (CaocaoButton *)messageBtn {
    if (!_messageBtn) {
        _messageBtn = [[CaocaoButton alloc] init];
        _messageBtn.margin = 4;
        _messageBtn.imageButtonType = CaocaoRightImageButton;
        [_messageBtn setTitle:@"--" forState:UIControlStateNormal];
        _messageBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_messageBtn setTitleColor:[SLColorManager caocaoButtonTextColor] forState:UIControlStateNormal];
        [_messageBtn setImage:[UIImage imageNamed:@"message"] forState:UIControlStateNormal];
        [_messageBtn sizeToFit];
    }
    return _messageBtn;
}

- (UIButton *)checkBtn {
    if (!_checkBtn) {
        _checkBtn = [[UIButton alloc] init];
        [_checkBtn setTitle:@"查看" forState:UIControlStateNormal];
        [_checkBtn setTitleColor:[SLColorManager cellContentColor] forState:UIControlStateNormal];
        _checkBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_checkBtn addTarget:self action:@selector(checkBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _checkBtn;
}

- (UILabel *)dot1Label {
    if (!_dot1Label) {
        _dot1Label = [[UILabel alloc] init];
        _dot1Label.text = @"·";
        _dot1Label.textColor = Color16(0xA0A0A0);
        _dot1Label.font = [UIFont systemFontOfSize:12];
    }
    return _dot1Label;
}

- (UILabel *)dot2Label {
    if (!_dot2Label) {
        _dot2Label = [[UILabel alloc] init];
        _dot2Label.text = @"·";
        _dot2Label.textColor = Color16(0xA0A0A0);
        _dot2Label.font = [UIFont systemFontOfSize:12];
    }
    return _dot2Label;
}

- (UILabel *)dot3Label{
    if (!_dot3Label) {
        _dot3Label = [[UILabel alloc] init];
        _dot3Label.text = @"·";
        _dot3Label.textColor = Color16(0xA0A0A0);
        _dot3Label.font = [UIFont systemFontOfSize:12];
    }
    return _dot3Label;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _lineView;
}

- (SLHomeTagView *)tagView {
    if (!_tagView) {
        _tagView = [[SLHomeTagView alloc] init];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagClick)];
        [_tagView addGestureRecognizer:tap];
    }
    return _tagView;
}

@end
