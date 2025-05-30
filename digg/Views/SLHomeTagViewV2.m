//
//  SLHomeTagView.m
//  digg
//
//  Created by hey on 2024/11/24.
//

#import "SLHomeTagViewV2.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLHomeTagViewV2 ()

@end

@implementation SLHomeTagViewV2

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [SLColorManager tagV2BackgroundTextColor];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 6;
        [self addSubview:self.tagLabel];
        [self.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(4, 4, 4, 4));
            make.width.equalTo(@0);
        }];
    }
    return self;
}

- (void)updateWithLabel:(NSString *)label{
    self.tagLabel.text = label;
    CGSize size = [self.tagLabel sizeThatFits:CGSizeZero];
    [self.tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(4, 4, 4, 4));
        make.width.equalTo(@(size.width));
    }];
}

- (void)updateWithLabelBySmall:(NSString *)label {
    self.tagLabel.text = label;
    CGSize size = [self.tagLabel sizeThatFits:CGSizeZero];
    [self.tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(1, 4, 1, 4));
        make.width.equalTo(@(size.width));
    }];
}

- (UILabel *)tagLabel{
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] init];
        _tagLabel.textColor = [SLColorManager tagV2TextColor];
        _tagLabel.textAlignment = NSTextAlignmentCenter;
        _tagLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    }
    return _tagLabel;
}

@end
