//
//  CaocaoButton.m
//  CaocaoBaseCoreFlowForCallCar
//
//  Created by 梁世伟 on 2021/1/5.
//

#import "CaocaoButton.h"
#import "UIView+CommonKit.h"
#import "Masonry.h"

@implementation CaocaoButton

- (void)layoutSubviews {
    [super layoutSubviews];

    switch (self.imageButtonType) {
    case CaocaoLeftImageButton: {
        [self leftImage];
        break;
    }
    case CaocaoUpImageButton: {
        [self upImage];
        break;
    }
    case CaocaoRightImageButton: {
        [self rightImage];
        break;
    }
    case CaocaoCenterImageButton:
        break;
    case CaocaoLeftImageButtonAndLeftAligment: {
        [self leftImageAndLeftAligment];
        break;
    }
    case CaocaoRightImageButtonAndRightAligment: {
        [self rightImageAndRightAligment];
        break;
    }
    default: {
        break;
    }
    }
}

- (void)upImage {
    CGSize imageSize = self.imageView.size;
    //Up image
    self.imageView.centerX = self.width / 2;
    self.imageView.centerY = self.height / 2 + 1 - imageSize.height / 2 + 4;

    //Down title
    self.titleLabel.top = self.height / 2 + 2 + 2;
    self.titleLabel.left = 0.f;
    self.titleLabel.width = self.width;
    double height = self.titleLabel.font.lineHeight;
    self.titleLabel.height = height;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)leftImage {
    CGSize imageSize = self.imageView.size;
    CGSize labelSize = self.titleLabel.size;
    CGFloat margin = self.margin;
  
    CGFloat totalWidth = labelSize.width + imageSize.width + margin;

    //left image
    CGFloat leftDelta = MAX(self.width - totalWidth, 0) / 2;
    self.imageView.left = leftDelta;

    //Right title
    self.titleLabel.left = self.imageView.right + margin;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)leftImageAndLeftAligment {
    CGSize imageSize = self.imageView.size;
    CGSize labelSize = self.titleLabel.size;
    CGFloat margin = self.margin;
    
    CGFloat totalWidth = labelSize.width + imageSize.width + margin;
    
    //left image
    CGFloat leftDelta = 0;
    self.imageView.left = leftDelta;
    
    //Right title
    self.titleLabel.left = self.imageView.right + margin;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)rightImage {
    CGSize imageSize = self.imageView.size;
    CGSize labelSize = self.titleLabel.size;
    CGFloat margin = self.margin;
    
    self.titleLabel.left = 0;
    self.imageView.left = self.titleLabel.right + margin;

    // 计算所需的总宽度
    CGFloat requiredWidth = self.titleLabel.right + margin + imageSize.width;
    
    // 如果按钮宽度不足，调整按钮宽度
    if (self.width < requiredWidth) {
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(requiredWidth + margin);
        }];
        
        // 通知布局系统需要更新
        [self setNeedsLayout];
        [self.superview setNeedsLayout];
    } 
}

- (void)rightImageAndRightAligment {
    CGSize imageSize = self.imageView.size;
    CGSize labelSize = self.titleLabel.size;
    CGFloat margin = self.margin;

    CGFloat totalWidth = labelSize.width + imageSize.width + margin;

    //Right image
    CGFloat rightDelta = 0;
    self.imageView.right = self.width - rightDelta;

    //Left title
    self.titleLabel.right = self.imageView.left - margin;
    self.titleLabel.textAlignment = NSTextAlignmentRight;
}

@end
