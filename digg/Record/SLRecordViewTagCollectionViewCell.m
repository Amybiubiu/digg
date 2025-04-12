//
//  SLRecordViewTagCollectionViewCell.m
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import "SLRecordViewTagCollectionViewCell.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLRecordViewTagCollectionViewCell()

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UILabel* nameLabel;
@property (nonatomic, assign) NSInteger index;

@end

@implementation SLRecordViewTagCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.borderView];
    [self.borderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [self.borderView addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15);
        make.centerY.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(12, 12));
    }];
    [self.borderView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.top.bottom.equalTo(self.borderView);
        make.height.mas_equalTo(25);
        make.left.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.closeButton.mas_left).offset(-10);
    }];
}

- (void)configDataWithTagName:(NSString *)name index:(NSInteger)index {
    self.nameLabel.text = name;
    self.index = index;
}

- (void)closeBtnClick {
    if (self.removeTag) {
        self.removeTag(self.nameLabel.text, self.index);
    }
}

#pragma mark - UI Elements
- (UIView *)borderView {
    if (!_borderView) {
        _borderView = [UIView new];
        _borderView.backgroundColor = Color16(0xF4F4F4);
        _borderView.clipsToBounds = YES;
        _borderView.layer.cornerRadius = 12.5;
        _borderView.layer.borderColor = Color16(0xDCDCDC).CGColor;
        _borderView.layer.borderWidth = 1;
    }
    return _borderView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"";
        _nameLabel.textColor = [SLColorManager cellTitleColor];
        _nameLabel.font = [UIFont boldSystemFontOfSize:13];
    }
    return _nameLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"remove_tag_icon"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
