//
//  SLEmptyCommentCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLEmptyCommentCell.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@interface SLEmptyCommentCell ()

@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIView *sectionSegment;

@end

@implementation SLEmptyCommentCell

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
    self.emptyLabel.text = @"还没有评论";
    self.emptyLabel.textColor = Color16(0x999999);
    self.emptyLabel.font = [UIFont pingFangRegularWithSize:12];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.emptyLabel];

    // 创建右侧横线
    UIView *rightLineView = [[UIView alloc] init];
    rightLineView.backgroundColor = Color16(0xC6C6C6);
    [self.contentView addSubview:rightLineView];
    
    // 创建评论按钮
    self.commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.commentButton setTitle:@"立即评论" forState:UIControlStateNormal];
    [self.commentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.commentButton.titleLabel.font = [UIFont pingFangRegularWithSize:12];
    self.commentButton.backgroundColor = Color16(0x14932A);
    self.commentButton.layer.cornerRadius = 4;
    [self.commentButton addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.commentButton.hidden = YES;
    [self.contentView addSubview:self.commentButton];
    
    [self.sectionSegment mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(7);
    }];

    // 设置约束
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.sectionSegment.mas_bottom).offset(55);
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
    
    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.emptyLabel.mas_bottom).offset(14);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(24);
    }];
}

- (void)commentButtonTapped {
    if (self.commentButtonTapHandler) {
        self.commentButtonTapHandler();
    }
}

@end
