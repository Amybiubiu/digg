//
//  SLShowMoreCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLShowMoreCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import "SLArticleEntity.h"

@interface SLShowMoreCell ()

@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIButton *showMoreButton;

@end

@implementation SLShowMoreCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    self.line = [UIView new];
    self.line.backgroundColor = Color16(0xEEEEEE);
    self.line.hidden = YES;
    [self.contentView addSubview:self.line];
    
    // 创建"展开更多评论"按钮
    self.showMoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showMoreButton setTitle:@"展开更多评论" forState:UIControlStateNormal];
    self.showMoreButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    [self.showMoreButton setTitleColor:Color16(0x14932A) forState:UIControlStateNormal];
    [self.showMoreButton addTarget:self action:@selector(showMoreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.showMoreButton];
}

- (void)setupConstraints {
    [self.showMoreButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(96);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];
    
    [self.line mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.centerY.equalTo(self.showMoreButton);
        make.height.mas_equalTo(1);
        make.width.mas_equalTo(20);
    }];
}

- (void)updateWithHidden:(BOOL)hidden {
    self.hidden = hidden;
    self.showMoreButton.hidden = hidden;
    self.line.hidden = hidden;
}

- (void)showMoreButtonTapped {
    if (self.showMoreButtonTappedHandler) {
        self.showMoreButtonTappedHandler(self.comment);
    }
}

- (void)setComment:(SLCommentEntity *)comment {
    _comment = comment;
    if (_comment.expandedRepliesCount == 1) {
        [self.showMoreButton setTitle:[NSString stringWithFormat:@"展开%ld评论", _comment.replyList.count - _comment.expandedRepliesCount] forState:UIControlStateNormal];
    } else {
        [self.showMoreButton setTitle:@"展开更多评论" forState:UIControlStateNormal];
    }
}

@end
