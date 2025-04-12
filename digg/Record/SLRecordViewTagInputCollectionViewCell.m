//
//  SLRecordViewTagInputCollectionViewCell.m
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import "SLRecordViewTagInputCollectionViewCell.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLRecordViewTagInputCollectionViewCell()

@property (nonatomic, strong) UIView *bashOutlineView;
@property (nonatomic, strong) UILabel* addNameLabel;
@property (nonatomic, strong) CAShapeLayer *borderLayer;

@end

@implementation SLRecordViewTagInputCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.bashOutlineView];
    [self.bashOutlineView addSubview:self.addNameLabel];
    [self.contentView addSubview:self.inputField];

    // [self updateConstraints];
    [self.bashOutlineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    CGSize size = [self.addNameLabel sizeThatFits:CGSizeZero];
    [self.addNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bashOutlineView).offset(15);
        make.centerY.top.bottom.equalTo(self.bashOutlineView);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(size.width);
        make.right.equalTo(self.bashOutlineView).offset(-15);
    }];
    
    [self.inputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bashOutlineView);
    }];
}

- (void)configDataWithIndex:(NSInteger)index {
    if (index == 0) {
        self.addNameLabel.text = @"＋ 标签";
    } else {
        self.addNameLabel.text = [NSString stringWithFormat:@"＋ %ld级标签", index];
    }

    // 计算文本大小并更新约束
    CGSize size = [self.addNameLabel sizeThatFits:CGSizeZero];
    [self.addNameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(size.width);
    }];

    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // [self updateConstraints];
}

- (void)startInput:(BOOL)start {
    if (start) {
        [self.bashOutlineView setHidden:YES];
        [self.addNameLabel setHidden:YES];
        [self.borderLayer setHidden:YES];
    } else {
        [self.bashOutlineView setHidden:NO];
        [self.addNameLabel setHidden:NO];
        [self.borderLayer setHidden:NO];
    }
}

// - (void)updateConstraints {
//
//     [self.bashOutlineView mas_updateConstraints:^(MASConstraintMaker *make) {
//         make.edges.equalTo(self.contentView);
//     }];
//     CGSize size = [self.addNameLabel sizeThatFits:CGSizeZero];
//     [self.addNameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
//         make.left.equalTo(self.bashOutlineView).offset(15);
//         make.centerY.top.bottom.equalTo(self.bashOutlineView);
//         make.height.mas_equalTo(25);
//         make.width.mas_equalTo(size.width);
//         make.right.equalTo(self.bashOutlineView).offset(-15);
//     }];
//     [self.inputField mas_updateConstraints:^(MASConstraintMaker *make) {
//         make.edges.equalTo(self.contentView);
//     }];
//    
//     [super updateConstraints];
// }

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectGetWidth(self.bashOutlineView.bounds) > 0 && CGRectGetHeight(self.bashOutlineView.bounds) > 0) {
        self.borderLayer.bounds = self.bashOutlineView.bounds;
        self.borderLayer.position = CGPointMake(CGRectGetMidX(self.bashOutlineView.bounds), CGRectGetMidY(self.bashOutlineView.bounds));
        self.borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.borderLayer.bounds cornerRadius:12.5].CGPath;
        self.borderLayer.lineDashPattern = @[@(3), @(1)];//前边是虚线的长度，后边是虚线之间空隙的长度
        self.borderLayer.lineDashPhase = 1;
        //实线边框
        self.borderLayer.fillColor = [UIColor clearColor].CGColor;
        self.borderLayer.strokeColor = Color16(0xDCDCDC).CGColor;
    }
}

#pragma mark - UI Elements
- (UITextField *)inputField {
    if (!_inputField) {
        _inputField = [[UITextField alloc] initWithFrame:CGRectZero];
        _inputField.borderStyle = UITextBorderStyleNone;
        _inputField.font = [UIFont systemFontOfSize:14];
    }
    return _inputField;
}

- (UIView *)bashOutlineView {
    if (!_bashOutlineView) {
        _bashOutlineView = [UIView new];
        _bashOutlineView.backgroundColor = UIColor.clearColor;        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        [_bashOutlineView.layer addSublayer:borderLayer];
        self.borderLayer = borderLayer;
    }
    return _bashOutlineView;
}

- (UILabel *)addNameLabel {
    if (!_addNameLabel) {
        _addNameLabel = [[UILabel alloc] init];
        _addNameLabel.text = @"＋ 标签";
        _addNameLabel.textColor = [SLColorManager cellTitleColor];
        _addNameLabel.font = [UIFont boldSystemFontOfSize:13];
    }
    return _addNameLabel;
}

@end
