//
//  SLRelatedLinksView.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLRelatedLinksView.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"

@interface SLRelatedLinksView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSMutableArray<UILabel *> *linkLabels;
@property (nonatomic, strong) NSArray<SLReferEntity *> *referList;

@end

@implementation SLRelatedLinksView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.titleLabel.textColor = Color16(0x999999);
    self.titleLabel.text = @"进一步阅读";
    [self addSubview:self.titleLabel];
    
    CGSize size = [self.titleLabel sizeThatFits:CGSizeZero];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(29);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(size.height);
    }];
    
    self.linkLabels = [NSMutableArray array];
}

- (void)setupWithReferList:(NSArray<SLReferEntity *> *)referList {
    self.referList = referList;
    
    // 清除现有的链接标签
    for (UILabel *label in self.linkLabels) {
        [label removeFromSuperview];
    }
    [self.linkLabels removeAllObjects];
    
    if (referList.count == 0) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = NO;
    
    // 添加新的链接标签
    UIView *lastView = self.titleLabel;
    
    for (NSInteger i = 0; i < referList.count; i++) {
        SLReferEntity *refer = referList[i];
        
        UILabel *linkLabel = [[UILabel alloc] init];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:refer.title];
        [attributedString addAttribute:NSUnderlineStyleAttributeName 
                                 value:@(NSUnderlineStyleSingle) 
                                 range:NSMakeRange(0, refer.title.length)];
        // 添加字体属性
        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]
                                 range:NSMakeRange(0, refer.title.length)];
        // 添加颜色属性
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:Color16(0x666666)
                                 range:NSMakeRange(0, refer.title.length)];
        linkLabel.attributedText = attributedString;
        linkLabel.userInteractionEnabled = YES;
        linkLabel.tag = i;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLinkTap:)];
        [linkLabel addGestureRecognizer:tapGesture];
        
        [self addSubview:linkLabel];
        [self.linkLabels addObject:linkLabel];
        
        CGSize size = [linkLabel sizeThatFits:CGSizeZero];
        [linkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastView.mas_bottom).offset(8);
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.height.mas_equalTo(size.height);
        }];
        
        lastView = linkLabel;
    }
}

- (void)handleLinkTap:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index < self.referList.count) {
        SLReferEntity *refer = self.referList[index];
        if (self.linkClickHandler) {
            self.linkClickHandler(refer);
        }
    }
}

- (CGFloat)getContentHeight {
    if (self.referList.count == 0) {
        return 0;
    }
    
    // 计算内容高度
    [self setNeedsLayout];
    [self layoutIfNeeded];
    UILabel *lastLabel = [self.linkLabels lastObject];
    if (lastLabel) {
        CGFloat height = CGRectGetMaxY(lastLabel.frame) + 24;
        return MAX(height, 0);
    }
    
    return 0;
}

@end
