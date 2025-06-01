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
    
    // 创建提示标签
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无评论，";
    self.emptyLabel.textColor = Color16(0xC6C6C6);
    self.emptyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.emptyLabel];
    
    // 创建评论按钮
    self.commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.commentButton setTitle:@"写评论" forState:UIControlStateNormal];
    [self.commentButton setTitleColor:Color16(0x005ECC) forState:UIControlStateNormal];
    self.commentButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.commentButton.backgroundColor = [UIColor clearColor];
    [self.commentButton addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    // 显示按钮
    self.commentButton.hidden = NO;
    [self.contentView addSubview:self.commentButton];
    
    [self.sectionSegment mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(7);
    }];

    // 设置约束
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView).offset(-20); // 向左偏移，为写评论按钮留出空间
        make.top.equalTo(self.sectionSegment.mas_bottom).offset(55);
    }];
    
    // 修改评论按钮位置，放在标签右侧
    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.emptyLabel);
        make.left.equalTo(self.emptyLabel.mas_right).offset(5);
        make.height.equalTo(self.emptyLabel);
    }];
}

- (void)commentButtonTapped {
    if (self.commentButtonTapHandler) {
        self.commentButtonTapHandler();
    }
}

@end
