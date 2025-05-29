//
//  SLEndOfListCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLEndOfListCell.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@interface SLEndOfListCell ()

@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIView *sectionSegment;

@end

@implementation SLEndOfListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];

    //分割条
    self.sectionSegment = [UIView new];
    self.sectionSegment.backgroundColor = Color16(0xF6F6F6);
    [self.contentView addSubview:self.sectionSegment];
    
    // 创建左侧横线
    UIView *leftLineView = [[UIView alloc] init];
    leftLineView.backgroundColor = Color16(0xC6C6C6);
    [self.contentView addSubview:leftLineView];
    
    // 创建提示标签
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"已经到底了";
    self.emptyLabel.textColor = Color16(0x999999);
    self.emptyLabel.font = [UIFont pingFangRegularWithSize:12];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.emptyLabel];

    // 创建右侧横线
    UIView *rightLineView = [[UIView alloc] init];
    rightLineView.backgroundColor = Color16(0xC6C6C6);
    [self.contentView addSubview:rightLineView];

    [self.sectionSegment mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(7);
    }];

    // 设置约束
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.sectionSegment.mas_bottom).offset(50);
    }];
    
    // 设置左侧横线约束
    [leftLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.emptyLabel);
        make.right.equalTo(self.emptyLabel.mas_left).offset(-10);
        make.width.mas_equalTo(7);
        make.height.mas_equalTo(0.5);
    }];
    
    // 设置右侧横线约束
    [rightLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.emptyLabel);
        make.left.equalTo(self.emptyLabel.mas_right).offset(10);
        make.width.mas_equalTo(7);
        make.height.mas_equalTo(0.5);
    }];
}

@end
