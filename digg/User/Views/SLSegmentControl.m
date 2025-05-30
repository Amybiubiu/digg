//
//  SLSegmentControl.m
//  digg
//
//  Created by Tim Bao on 2025/1/5.
//

#import "SLSegmentControl.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"
#import "SLColorManager.h"


@interface SLSegmentControl ()

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

@end

@implementation SLSegmentControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        self.buttons = [NSMutableArray array];
        self.selectedIndex = 0;
    }
    return self;
}

- (void)layoutSubviews {
    if (self.frame.size.height > 0 && self.frame.size.width > 0 && self.buttons.count == 0) {
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.buttons removeAllObjects];
        
        CGFloat buttonWidth = 40;
        CGFloat space = (self.frame.size.width  - buttonWidth * 3) / 2;
//        CGFloat buttonWidth = (self.frame.size.width  - space * 2) / self.titles.count;
        for (int i = 0; i < self.titles.count; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake((buttonWidth + space) * i, 0, buttonWidth, self.frame.size.height);
            [button setTitle:self.titles[i] forState:UIControlStateNormal];
            [button setTitleColor:[SLColorManager categorySelectedTextColor] forState:UIControlStateSelected];
            [button setTitleColor:[SLColorManager categoryNormalTextColor] forState:UIControlStateNormal];
            button.titleLabel.font = i == self.selectedIndex ? [UIFont pingFangSemiboldWithSize:14] : [UIFont pingFangRegularWithSize:14];
            [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [self.buttons addObject:button];
        }
        
        // 创建指示线
        UIButton* button = self.buttons[self.selectedIndex];
        self.indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        self.indicatorView.layer.cornerRadius = 1.5;
        self.indicatorView.layer.masksToBounds = YES;
        self.indicatorView.backgroundColor = Color16(0x14932A);
        [self addSubview:self.indicatorView];
        [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(button.mas_bottom);
            make.height.mas_equalTo(3);
            make.centerX.equalTo(button);
            make.width.mas_equalTo(28);
        }];
        
        [self updateIndicatorPosition];
    }
    
    [super layoutSubviews];
}

- (void)setTitles:(NSArray<NSString *> *)titles {
    _titles = titles;
}

- (void)buttonTapped:(UIButton *)button {
    UIButton* lastSelectedBtn = self.buttons[self.selectedIndex];
    lastSelectedBtn.selected = NO;
    lastSelectedBtn.titleLabel.font = [UIFont pingFangSemiboldWithSize:14];
    NSInteger index = [self.buttons indexOfObject:button];
    self.selectedIndex = index;
    [self updateIndicatorPosition];
    
    // 发送通知或调用代理方法
    if ([self.delegate respondsToSelector:@selector(segmentControl:didSelectIndex:)]) {
        [self.delegate segmentControl:self didSelectIndex:self.selectedIndex];
    }
}

- (void)updateIndicatorPosition {
    UIButton* button = self.buttons[self.selectedIndex];
    button.titleLabel.font = [UIFont pingFangSemiboldWithSize:14];
    button.selected = YES;
    [self.indicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(button.mas_bottom);
        make.height.mas_equalTo(3);
        make.centerX.equalTo(button);
        make.width.mas_equalTo(28);
    }];
}

@end
