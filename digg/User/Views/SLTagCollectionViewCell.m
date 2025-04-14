//
//  SLTagCollectionViewCell.m
//  digg
//
//  Created by Tim Bao on 2025/1/5.
//

#import "SLTagCollectionViewCell.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"

@interface SLTagCollectionViewCell()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *tagNameLabel;
@property (nonatomic, strong) UIImageView *tagImageView;

@end

@implementation SLTagCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bgView];
        [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [self.bgView addSubview:self.tagImageView];
        [self.tagImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(7);
            make.size.mas_equalTo(CGSizeMake(10, 10));
        }];
        [self.bgView addSubview:self.tagNameLabel];
        [self.tagNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.top.equalTo(self.contentView).offset(7);
            make.bottom.equalTo(self.contentView).offset(-7);
            make.left.equalTo(self.tagImageView.mas_right).offset(4);
            make.right.equalTo(self.contentView).offset(-11);
        }];
    }
    return self;
}

- (void)setLabel:(NSString *)label {
    self.tagNameLabel.text = label;
}

#pragma mark - UI Elements
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.backgroundColor = UIColor.clearColor;
        _bgView.layer.borderColor = [UIColor.blackColor colorWithAlphaComponent:0.2].CGColor;
        _bgView.layer.borderWidth = 0.5;
        _bgView.layer.masksToBounds = YES;
        _bgView.layer.cornerRadius = 15.5;
    }
    return _bgView;
}

- (UIImageView *)tagImageView {
    if (!_tagImageView) {
        _tagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag_icon"]];
    }
    return _tagImageView;
}

- (UILabel *)tagNameLabel {
    if (!_tagNameLabel) {
        _tagNameLabel = [[UILabel alloc] init];
        _tagNameLabel.text = @"";
        _tagNameLabel.textColor = Color16(0x222222);
        _tagNameLabel.font = [UIFont pingFangRegularWithSize:12];
        _tagNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tagNameLabel;
}

@end
