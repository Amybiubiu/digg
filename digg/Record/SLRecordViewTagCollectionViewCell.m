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

@interface SLRecordViewTagCollectionViewCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *tagName;

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
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.containerView.layer.cornerRadius = 15;
    self.containerView.clipsToBounds = YES;
    [self.contentView addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
        make.height.mas_equalTo(30);
    }];
    
    self.tagLabel = [[UILabel alloc] init];
    self.tagLabel.font = [UIFont systemFontOfSize:14];
    self.tagLabel.textColor = [SLColorManager cellTitleColor];
    [self.containerView addSubview:self.tagLabel];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    self.deleteButton.tintColor = [UIColor lightGrayColor];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.deleteButton];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView).offset(-5);
        make.centerY.equalTo(self.containerView);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(10);
        make.right.equalTo(self.deleteButton.mas_left).offset(-5);
        make.centerY.equalTo(self.containerView);
    }];
}

- (void)configDataWithTagName:(NSString *)tagName index:(NSInteger)index {
    self.tagName = tagName;
    self.index = index;
    self.tagLabel.text = tagName;
    
    // 计算标签宽度
    UIFont *font = self.tagLabel.font;
    CGSize textSize = [tagName sizeWithAttributes:@{NSFontAttributeName: font}];
    
    // 设置最小宽度，最大宽度为屏幕宽度减去边距
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - 60;
    CGFloat width = MAX(60, textSize.width + 45); // 文本宽度加上左右内边距和删除按钮宽度
    width = MIN(width, maxWidth);
    
    // 更新约束
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
    }];
}

- (void)deleteButtonTapped {
    if (self.removeTag) {
        self.removeTag(self.tagName, self.index);
    }
}

@end
