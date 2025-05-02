//
//  SLArticleTagCell.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleTagCell.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLColorManager.h"
#import "SLTagListView.h"

@interface SLArticleTagCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) SLTagListView *tagListView;
@property (nonatomic, strong) UIView *separatorLine;

@end

@implementation SLArticleTagCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont pingFangMediumWithSize:16];
    self.titleLabel.textColor = [SLColorManager primaryTextColor];
    self.titleLabel.text = @"相关标签";
    [self.contentView addSubview:self.titleLabel];
    
    // 标签列表视图
    self.tagListView = [[SLTagListView alloc] init];
    __weak typeof(self) weakSelf = self;
    self.tagListView.tagClickHandler = ^(NSString *tag) {
        if (weakSelf.tagSelectedHandler) {
            weakSelf.tagSelectedHandler(tag);
        }
    };
    [self.contentView addSubview:self.tagListView];
    
    // 分隔线
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = [SLColorManager cellDivideLineColor];
    [self.contentView addSubview:self.separatorLine];
    
    // 设置约束
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [self.tagListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.height.equalTo(@40);
    }];
    
    [self.separatorLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView);
        make.height.equalTo(@0.5);
        make.top.equalTo(self.tagListView.mas_bottom).offset(16);
    }];
}

- (void)updateWithTags:(NSArray<NSString *> *)tags {
    if (tags.count == 0) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = NO;
    [self.tagListView setTags:tags];
    
    // 根据标签列表的实际高度调整约束
    [self.tagListView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@([self.tagListView getContentHeight]));
    }];
}

@end
