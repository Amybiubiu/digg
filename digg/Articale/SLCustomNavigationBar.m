//
//  SLCustomNavigationBar.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLCustomNavigationBar.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLCustomNavigationBar ()

@property (nonatomic, strong) UIButton *backButton;

@end

@implementation SLCustomNavigationBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [SLColorManager primaryBackgroundColor];
    
    // 返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:[UIImage imageNamed:@"left_back_icon"] forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backButton];
    
    // 更多按钮
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setImage:[UIImage imageNamed:@"more_btn_icon"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.moreButton];
    
    // 设置导航栏内部组件约束
    UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.allObjects.firstObject;
    CGFloat statusBarHeight = windowScene.statusBarManager.statusBarFrame.size.height;
    
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(statusBarHeight + 10);
        make.width.height.equalTo(@24);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.backButton);
        make.width.height.equalTo(@24);
    }];
}

#pragma mark - Actions

- (void)backButtonTapped {
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigationBarBackButtonTapped)]) {
        [self.delegate navigationBarBackButtonTapped];
    }
}

- (void)moreButtonTapped {
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigationBarMoreButtonTapped)]) {
        [self.delegate navigationBarMoreButtonTapped];
    }
}

@end
