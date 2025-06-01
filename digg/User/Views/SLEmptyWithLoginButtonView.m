//
//  SLEmptyWithLoginButtonView.m
//  digg
//
//  Created by Tim Bao on 2025/1/6.
//

#import "SLEmptyWithLoginButtonView.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLEmptyWithLoginButtonView()

@property (nonatomic, strong) UIImageView* iconImageView;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* descLabel;

@end

@implementation SLEmptyWithLoginButtonView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.iconImageView];
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(self).offset(243);
            make.size.mas_equalTo(CGSizeMake(103, 97));
        }];
        [self addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self);
            make.top.equalTo(self.iconImageView.mas_bottom).offset(45);
        }];
        [self addSubview:self.descLabel];
        [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        }];
        
        [self addSubview:self.loginBtn];
        [self.loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-70);
            make.size.mas_equalTo(CGSizeMake(190, 42));
        }];
    }
    return self;
}

- (void)gotoLoginPage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(gotoLoginPage)]) {
        [self.delegate gotoLoginPage];
    }
}

#pragma mark - UI Elements
- (UIButton *)loginBtn {
    if (!_loginBtn) {
        _loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginBtn setTitle:@"登录" forState:UIControlStateNormal];
        [_loginBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _loginBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _loginBtn.layer.cornerRadius = 4;
        _loginBtn.layer.masksToBounds = YES;
        _loginBtn.backgroundColor = Color16(0x14932A);
        [_loginBtn addTarget:self action:@selector(gotoLoginPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loginBtn;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no_login_icon"]];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"你还没有登录";
        _titleLabel.textColor = [SLColorManager primaryTextColor];
        _titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.text = @"登录账号，查看你关注的精彩内容";
        _descLabel.textColor = [SLColorManager secondaryTextColor];
        _descLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _descLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _descLabel;
}

@end
