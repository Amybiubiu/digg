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

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *plusLabel;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic, assign) CGFloat maxWidth;

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
    self.maxWidth = [UIScreen mainScreen].bounds.size.width - 60; // 屏幕宽度减去左右边距
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.layer.cornerRadius = 15;
    self.containerView.clipsToBounds = YES;
    [self.contentView addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(100); // 默认宽度
    }];
    
    self.plusLabel = [[UILabel alloc] init];
    self.plusLabel.text = @"+ 标签";
    self.plusLabel.font = [UIFont systemFontOfSize:14];
    self.plusLabel.textColor = [SLColorManager cellTitleColor];
    self.plusLabel.textAlignment = NSTextAlignmentCenter; // 确保文本居中
    [self.containerView addSubview:self.plusLabel];
    
    [self.plusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.containerView);
        make.left.right.equalTo(self.containerView).inset(10);
    }];
    
    self.inputField = [[UITextField alloc] init];
    self.inputField.font = [UIFont systemFontOfSize:14];
    self.inputField.textColor = [SLColorManager cellTitleColor];
    self.inputField.backgroundColor = [UIColor clearColor];
    self.inputField.returnKeyType = UIReturnKeyDone;
    self.inputField.textAlignment = NSTextAlignmentLeft; // 从左往右输入
    self.inputField.hidden = YES;
    [self.containerView addSubview:self.inputField];
    
    [self.inputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(10);
        make.right.equalTo(self.containerView).offset(-10);
        make.height.equalTo(self.containerView);
    }];
    
    // 立即调用setupDashedBorder确保初始化时就有边框
    [self setupDashedBorder];
}

- (void)setupDashedBorder {
    // 移除旧的边框
    if (self.borderLayer) {
        [self.borderLayer removeFromSuperlayer];
    }
    
    // 创建虚线边框
    self.borderLayer = [CAShapeLayer layer];
    self.borderLayer.strokeColor = [UIColor lightGrayColor].CGColor; // 使用浅灰色更符合UI
    self.borderLayer.lineDashPattern = @[@4, @2];
    self.borderLayer.lineWidth = 1.0;
    self.borderLayer.fillColor = [UIColor clearColor].CGColor;
    
    // 确保在下一个渲染周期更新路径
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect borderRect = CGRectInset(self.containerView.bounds, 0, 0);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:15];
        self.borderLayer.path = path.CGPath;
        
        [self.containerView.layer addSublayer:self.borderLayer];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新虚线边框的路径
    if (self.borderLayer) {
        CGRect borderRect = CGRectInset(self.containerView.bounds, 0, 0);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:15];
        self.borderLayer.path = path.CGPath;
    }
}

- (void)configDataWithIndex:(NSInteger)index {
    // 配置为添加标签入口
    self.plusLabel.hidden = NO;
    self.inputField.hidden = YES;
    self.containerView.backgroundColor = [UIColor clearColor];
    
    // 更新约束
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(100); // 默认宽度
    }];
}

- (void)startInput:(BOOL)isEditing {
    if (isEditing) {
        // 切换到编辑模式
        self.plusLabel.hidden = YES;
        self.inputField.hidden = NO;
        self.containerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        // 移除虚线边框
        if (self.borderLayer) {
            [self.borderLayer removeFromSuperlayer];
            self.borderLayer = nil;
        }
        
        // 更新约束 - 初始编辑宽度设置更大
        CGFloat initialEditWidth = [UIScreen mainScreen].bounds.size.width * 0.7; // 增加初始编辑宽度
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(initialEditWidth);
        }];
    } else {
        // 切换回添加标签入口
        self.plusLabel.hidden = NO;
        self.inputField.hidden = YES;
        self.containerView.backgroundColor = [UIColor clearColor];
        
        // 添加虚线边框
        [self setupDashedBorder];
        
        // 更新约束
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(100); // 增加默认宽度
        }];
    }
}

- (void)updateInputFieldWidthWithText:(NSString *)text {
    // 计算文本宽度
    UIFont *font = self.inputField.font;
    CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    
    // 设置最小宽度为100，最大宽度为屏幕宽度减去左右边距
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat maxAvailableWidth = screenWidth - 40; // 左右各减去20的边距
    
    // 文本宽度加上左右内边距
    CGFloat width = MAX(100, textSize.width + 40); // 增加内边距
    
    // 如果文本长度超过一定值，直接使用最大宽度
    if (text.length > 5) {
        width = MIN(width, maxAvailableWidth);
    }
    
    // 更新约束
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
    }];
    
    [self.contentView layoutIfNeeded];
}

- (void)resetInputField {
    self.inputField.text = @"";
    [self startInput:NO];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.inputField.text = @"";
    [self startInput:NO];
}

@end
