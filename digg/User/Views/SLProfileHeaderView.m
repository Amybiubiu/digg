//
//  SLProfileHeaderView.m
//  digg
//
//  Created by Tim Bao on 2025/1/5.
//

#import "SLProfileHeaderView.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLTagCollectionViewCell.h"
#import "SDWebImage.h"
#import "SLTagsView.h"
#import "digg-Swift.h"
#import "SLColorManager.h"


@interface SLProfileHeaderView()

@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, strong) UIButton* editorButton;
@property (nonatomic, strong) UIButton* focusButton;
@property (nonatomic, strong) UILabel* nameLabel;
@property (nonatomic, strong) UILabel* briefLabel;

@property (nonatomic, strong) UILabel *followLabel;
@property (nonatomic, strong) UILabel *attentionLabel;
@property (nonatomic, strong) UILabel *collectLabel;

@property (nonatomic, strong) UILabel* tagLabel;
@property (nonatomic, strong) SLTagsView *tagsView;

@end

@implementation SLProfileHeaderView

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        [self addSubview:self.contentView];
        [self addSubview:self.avatarImageView];

        [self.contentView addSubview:self.editorButton];
        [self.contentView addSubview:self.focusButton];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.briefLabel];
        [self.contentView addSubview:self.followLabel];
        [self.contentView addSubview:self.attentionLabel];
        [self.contentView addSubview:self.collectLabel];
        [self.contentView addSubview:self.tagLabel];
        [self.contentView addSubview:self.tagsView];   
    }
    return self;
}

#pragma mark - Update

- (void)updateConstraints {
    
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.top.equalTo(self).offset(30);
    }];
    [self.avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(14);
        make.top.equalTo(self); // 保持头像上移
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    [self.editorButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(16);
        make.size.mas_equalTo(CGSizeMake(90, 30));
    }];
    [self.focusButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(16);
        make.size.mas_equalTo(CGSizeMake(90, 30));
    }];
    [self.nameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    [self.briefLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    [self.followLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.briefLabel.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(16);
    }];
    [self.attentionLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.followLabel);
        make.left.equalTo(self.followLabel.mas_right).offset(20);
        make.height.equalTo(self.followLabel);
    }];
    [self.collectLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.followLabel);
        make.left.equalTo(self.attentionLabel.mas_right).offset(20);
        make.height.equalTo(self.followLabel);
    }];

    if (self.entity.labels.count == 0) {
        [self.tagLabel setHidden:YES];
        [self.tagsView setHidden:YES];
        [self.tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.followLabel.mas_bottom).offset(16);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.height.mas_equalTo(0);
        }];
        [self.tagsView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagLabel.mas_bottom).offset(12);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(self.contentView);
            make.height.mas_equalTo(0);
        }];
    } else {
        CGFloat height = [self.tagLabel sizeThatFits:CGSizeZero].height;
        [self.tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.followLabel.mas_bottom).offset(16);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.height.mas_equalTo(height);
        }];
        [self.tagLabel setHidden:NO];
        [self.tagsView setHidden:NO];
        [self.tagsView setTags:self.entity.labels maxWidth:self.contentView.bounds.size.width - 32];
        
        CGFloat finalHeight = [self.tagsView calculatedHeight];
        NSLog(@"最终高度: %.2f", finalHeight);
        // 调整 frame
        [self.tagsView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagLabel.mas_bottom).offset(12);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(self.contentView);
            make.height.mas_equalTo(finalHeight);
        }];
    }

    [super updateConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新avatarImageView的mask以适应其当前大小
    if (_avatarImageView) {
        CAShapeLayer *maskLayer = (CAShapeLayer *)_avatarImageView.layer.mask;
        if (maskLayer) {
            maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:_avatarImageView.bounds 
                                                        cornerRadius:_avatarImageView.bounds.size.width / 2].CGPath;
        }
    }
}

- (void)setEntity:(SLProfileEntity *)entity {
    _entity = entity;

    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:entity.avatar] placeholderImage:[UIImage imageNamed:@"avatar_default_icon"]];
    
    self.nameLabel.text = entity.userName;
    self.briefLabel.text = entity.desc;
    if (entity.isSelf) {
        [self.focusButton setHidden:YES];
        [self.editorButton setHidden:NO];
    } else {
        [self.focusButton setHidden:NO];
        [self.editorButton setHidden:YES];
        if (entity.hasFollow) {
            [self.focusButton setTitle:@"正在关注" forState:UIControlStateNormal];
        } else {
            [self.focusButton setTitle:@"关注" forState:UIControlStateNormal];
        }
    }
    NSString* txt = [NSString stringWithFormat:@"%ld 粉丝", entity.followCnt];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:txt];
    // 设置字体和颜色
    UIFont *bigFont = [UIFont pingFangRegularWithSize:12];
    UIColor *bigColor = [SLColorManager categorySelectedTextColor];
    UIFont *smallFont = [UIFont pingFangSemiboldWithSize:12];
    UIColor *smallColor = Color16(0x999999);
    
    [attributedString addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, txt.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, txt.length)];
    
    NSRange range = [txt rangeOfString:@"粉丝"];
    [attributedString addAttribute:NSFontAttributeName value:smallFont range:range];
    [attributedString addAttribute:NSForegroundColorAttributeName value:smallColor range:range];
    self.followLabel.attributedText = attributedString;
    
    NSString* attentionString = [NSString stringWithFormat:@"%ld 关注", entity.beFollowedCnt];
    NSMutableAttributedString *attributedString1 = [[NSMutableAttributedString alloc] initWithString:attentionString];
    
    [attributedString1 addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, attentionString.length)];
    [attributedString1 addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, attentionString.length)];
    
    NSRange range1 = [attentionString rangeOfString:@"关注"];
    [attributedString1 addAttribute:NSFontAttributeName value:smallFont range:range1];
    [attributedString1 addAttribute:NSForegroundColorAttributeName value:smallColor range:range1];
    self.attentionLabel.attributedText = attributedString1;
    
    NSString* collectionString = [NSString stringWithFormat:@"%ld 点赞", entity.likedArticleCnt];
    NSMutableAttributedString *attributedString2 = [[NSMutableAttributedString alloc] initWithString:collectionString];
    
    [attributedString2 addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, collectionString.length)];
    [attributedString2 addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, collectionString.length)];
    
    NSRange range2 = [collectionString rangeOfString:@"点赞"];
    [attributedString2 addAttribute:NSFontAttributeName value:smallFont range:range2];
    [attributedString2 addAttribute:NSForegroundColorAttributeName value:smallColor range:range2];
    self.collectLabel.attributedText = attributedString2;
    
    [self updateConstraints];
}

#pragma mark - Actions
- (void)gotoEdit {
    if (self.delegate && [self.delegate respondsToSelector:@selector(gotoEditPersonalInfo)]) {
        [self.delegate gotoEditPersonalInfo];
    }
}

- (void)focusBtnClick {
    if (self.delegate && [self.delegate respondsToSelector:@selector(follow:)]) {
        [self.delegate follow:!self.entity.hasFollow];
    }
}

#pragma mark - UI Elements
- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
//        _avatarImageView.backgroundColor = [SLColorManager headerBorderColor];
        _avatarImageView.image = [UIImage imageNamed:@"avatar_default_icon"];
        _avatarImageView.layer.cornerRadius = 30;
        _avatarImageView.layer.borderColor = [SLColorManager headerBorderColor].CGColor;
        _avatarImageView.layer.borderWidth = 1;

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 60, 60) 
                                                    cornerRadius:30].CGPath;
        _avatarImageView.layer.mask = maskLayer;
        
        _avatarImageView.layer.zPosition = 1; // 提高层级
        _avatarImageView.isSkeletonable = YES;
    }
    return _avatarImageView;
}

- (UIButton *)editorButton {
    if (!_editorButton) {
        _editorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editorButton.layer.cornerRadius = 15;
        _editorButton.layer.masksToBounds = YES;
        _editorButton.layer.borderColor = [[SLColorManager categorySelectedTextColor] colorWithAlphaComponent:0.15].CGColor;
        _editorButton.layer.borderWidth = 0.5;
        [_editorButton setTitle:@"编辑信息" forState:UIControlStateNormal];
        [_editorButton setTitleColor:[SLColorManager categorySelectedTextColor] forState:UIControlStateNormal];
        _editorButton.titleLabel.font = [UIFont pingFangRegularWithSize:12];
        [_editorButton setHidden: YES];
        [_editorButton addTarget:self action:@selector(gotoEdit) forControlEvents:UIControlEventTouchUpInside];
        
        _editorButton.isSkeletonable = YES;
    }
    return _editorButton;
}

- (UIButton *)focusButton {
    if (!_focusButton) {
        _focusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _focusButton.layer.cornerRadius = 15;
        _focusButton.layer.masksToBounds = YES;
        _focusButton.layer.borderColor = [[SLColorManager categorySelectedTextColor] colorWithAlphaComponent:0.15].CGColor;
        _focusButton.layer.borderWidth = 0.5;
        [_focusButton setTitle:@"关注" forState:UIControlStateNormal];
        [_focusButton setTitleColor:[SLColorManager categorySelectedTextColor] forState:UIControlStateNormal];
        _focusButton.titleLabel.font = [UIFont pingFangRegularWithSize:12];
        [_focusButton setHidden: NO];
        [_focusButton addTarget:self action:@selector(focusBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _focusButton;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"";
        _nameLabel.textColor = [SLColorManager categorySelectedTextColor];
        _nameLabel.font = [UIFont pingFangSemiboldWithSize:18];
        
        _nameLabel.isSkeletonable = YES;
    }
    return _nameLabel;
}

- (UILabel *)briefLabel {
    if (!_briefLabel) {
        _briefLabel = [[UILabel alloc] init];
        _briefLabel.text = @"";
        _briefLabel.textColor = [SLColorManager cellTitleColor];
        _briefLabel.font = [UIFont pingFangRegularWithSize:12];
        _briefLabel.numberOfLines = 0;
        
        _briefLabel.isSkeletonable = YES;
    }
    return _briefLabel;
}

- (UILabel *)followLabel {
    if (!_followLabel) {
        _followLabel = [[UILabel alloc] init];
        NSString* txt = @"0 粉丝";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:txt];
        // 设置字体和颜色
        UIFont *bigFont = [UIFont pingFangRegularWithSize:12];
        UIColor *bigColor = [SLColorManager categorySelectedTextColor];
        UIFont *smallFont = [UIFont pingFangSemiboldWithSize:12];
        UIColor *smallColor = Color16(0x999999);
        
        [attributedString addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, txt.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, txt.length)];
        
        NSRange range = [txt rangeOfString:@"粉丝"];
        [attributedString addAttribute:NSFontAttributeName value:smallFont range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName value:smallColor range:range];
        _followLabel.attributedText = attributedString;
        
        _followLabel.isSkeletonable = YES;
    }
    return _followLabel;
}

- (UILabel *)attentionLabel {
    if (!_attentionLabel) {
        _attentionLabel = [[UILabel alloc] init];
        NSString* txt = @"0 关注";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:txt];
        // 设置字体和颜色
        UIFont *bigFont = [UIFont pingFangRegularWithSize:12];
        UIColor *bigColor = [SLColorManager categorySelectedTextColor];
        UIFont *smallFont = [UIFont pingFangSemiboldWithSize:12];
        UIColor *smallColor = Color16(0x999999);
        
        [attributedString addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, txt.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, txt.length)];
        
        NSRange range = [txt rangeOfString:@"关注"];
        [attributedString addAttribute:NSFontAttributeName value:smallFont range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName value:smallColor range:range];
        _attentionLabel.attributedText = attributedString;
        
        _attentionLabel.isSkeletonable = YES;
    }
    return _attentionLabel;
}

- (UILabel *)collectLabel {
    if (!_collectLabel) {
        _collectLabel = [[UILabel alloc] init];
        NSString* txt = @"0 点赞";
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:txt];
        
        // 设置字体和颜色
        UIFont *bigFont = [UIFont pingFangRegularWithSize:12];
        UIColor *bigColor = [SLColorManager categorySelectedTextColor];
        UIFont *smallFont = [UIFont pingFangSemiboldWithSize:12];
        UIColor *smallColor = Color16(0x999999);
        
        [attributedString addAttribute:NSFontAttributeName value:bigFont range:NSMakeRange(0, txt.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:bigColor range:NSMakeRange(0, txt.length)];
        
        NSRange range = [txt rangeOfString:@"点赞"];
        [attributedString addAttribute:NSFontAttributeName value:smallFont range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName value:smallColor range:range];
        _collectLabel.attributedText = attributedString;
        
        _collectLabel.isSkeletonable = YES;
    }
    return _collectLabel;
}

- (UILabel *)tagLabel {
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] init];
        _tagLabel.text = @"我的标签";
        _tagLabel.textColor = [SLColorManager categorySelectedTextColor];
        _tagLabel.font = [UIFont pingFangSemiboldWithSize:14];
        
        _tagLabel.isSkeletonable = YES;
    }
    return _tagLabel;
}

- (SLTagsView *)tagsView {
    if (!_tagsView) {
        _tagsView = [[SLTagsView alloc] init];
    }
    return _tagsView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [SLColorManager primaryBackgroundColor];
        _contentView.clipsToBounds = NO;
         _contentView.layer.cornerRadius = 16.0;
         _contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    return _contentView;
}

@end
