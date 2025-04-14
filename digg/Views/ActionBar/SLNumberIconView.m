//
//  SLNumberIconView.m
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import "SLNumberIconView.h"
#import "SLColorManager.h"

@implementation SLNumberIconItem

+ (instancetype)itemWithNumber:(NSInteger)number normalImage:(UIImage *)normalImage selectedImage:(nullable UIImage *)selectedImage {
    SLNumberIconItem *item = [[SLNumberIconItem alloc] init];
    item.number = number;
    item.normalImage = normalImage;
    item.selectedImage = selectedImage;
    item.numberColor = [UIColor darkGrayColor];
    item.iconColor = [UIColor darkGrayColor];
    item.isSelected = NO;
    return item;
}

@end

@interface SLNumberIconItemView : UIView

@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UIButton *touchButton;
@property (nonatomic, strong) SLNumberIconItem *item;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) void (^clickHandler)(NSInteger index);
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat touchAreaExtension;

- (void)updateWithItem:(SLNumberIconItem *)item;
- (CGSize)sizeThatFits:(CGSize)size;

@end

@implementation SLNumberIconItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _itemSpacing = 4.0;
        _touchAreaExtension = 10.0;
        
        // 创建数字标签
        _numberLabel = [[UILabel alloc] init];
        _numberLabel.textAlignment = NSTextAlignmentRight;
        _numberLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:_numberLabel];
        
        // 创建图标视图
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconImageView];
        
        // 创建自定义文本标签
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.font = [UIFont systemFontOfSize:12];
        _customTextLabel.hidden = YES;
        [self addSubview:_customTextLabel];
        
        // 创建透明按钮用于扩大点击区域
        _touchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _touchButton.backgroundColor = [UIColor clearColor];
        [_touchButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_touchButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat totalWidth = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // 计算数字标签宽度
    CGFloat numberWidth = 0;
    if (_item.number > 0) {
        numberWidth = [_numberLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
    }
    
    // 布局数字标签
    if (_item.number > 0) {
        _numberLabel.frame = CGRectMake(0, 0, numberWidth, height);
    } else {
        _numberLabel.frame = CGRectZero;
    }
    
    // 处理自定义文本
    if (_customTextLabel && !_customTextLabel.hidden) {
        CGFloat textWidth = [_customTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        CGFloat textX = (_item.number > 0) ? (numberWidth + _itemSpacing) : 0;
        _customTextLabel.frame = CGRectMake(textX, 0, textWidth, height);
    }
    // 处理图标
    else if (!_iconImageView.hidden) {
        CGFloat iconWidth = _iconImageView.image.size.width;
        if (iconWidth == 0) {
            iconWidth = height * 0.6; // 默认使用高度的60%作为宽度
        }
        
        CGFloat iconX = (_item.number > 0) ? (numberWidth + _itemSpacing) : 0;
        _iconImageView.frame = CGRectMake(iconX, (height - iconWidth) / 2, iconWidth, iconWidth);
    }
    
    // 布局点击按钮 - 扩大点击区域
    _touchButton.frame = CGRectMake(-_touchAreaExtension, 
                                   -_touchAreaExtension, 
                                   totalWidth + _touchAreaExtension * 2, 
                                   height + _touchAreaExtension * 2);
}

- (void)updateWithItem:(SLNumberIconItem *)item {
    _item = item;
    
    // 更新数字
    if (item.number > 0) {
        _numberLabel.text = [NSString stringWithFormat:@"%ld", (long)item.number];
        _numberLabel.textColor = item.numberColor;
        _numberLabel.hidden = NO;
    } else {
        _numberLabel.hidden = YES;
    }
    
    // 处理自定义文本
    NSString *customText = [item valueForKey:@"customText"];
    if (customText.length > 0) {
        _iconImageView.hidden = YES;
        _customTextLabel.text = customText;
        _customTextLabel.textColor = item.numberColor;
        _customTextLabel.hidden = NO;
    } else {
        _customTextLabel.hidden = YES;
        
        // 更新图标 - 即使数字为0，也显示图标
        UIImage *image = item.isSelected && item.selectedImage ? item.selectedImage : item.normalImage;
        if (image) {
            _iconImageView.image = image;
            _iconImageView.tintColor = item.iconColor;
            _iconImageView.hidden = NO;
        } else {
            _iconImageView.hidden = YES;
        }
    }
    
    [self setNeedsLayout];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat width = 0;
    CGFloat height = size.height;
    
    // 计算数字宽度
    if (_item.number > 0) {
        CGFloat numberWidth = [_numberLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        width += numberWidth;
        
        // 如果有数字，添加间距
        width += _itemSpacing;
    }
    
    // 处理自定义文本
    NSString *customText = [_item valueForKey:@"customText"];
    if (customText.length > 0) {
        CGFloat textWidth = [_customTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        width += textWidth;
    } else {
        // 添加图标宽度
        CGFloat iconWidth = _iconImageView.image.size.width;
        if (iconWidth == 0) {
            iconWidth = height; // 默认使用高度作为宽度
        }
        width += iconWidth;
    }
    
    return CGSizeMake(width, height);
}

- (void)buttonTapped:(UIButton *)sender {
    if (self.clickHandler) {
        self.clickHandler(self.index);
    }
}

@end

@interface SLNumberIconView ()

@property (nonatomic, strong) NSMutableArray<SLNumberIconItemView *> *itemViews;

@end

@implementation SLNumberIconView

- (instancetype)initWithFrame:(CGRect)frame items:(NSArray<SLNumberIconItem *> *)items {
    self = [super initWithFrame:frame];
    if (self) {
        _spacing = 15.0;
        _itemSpacing = 4.0;
        _fontSize = 12.0;
        _iconSize = 16.0;
        _touchAreaExtension = 10.0;
        _itemViews = [NSMutableArray array];
        
        if (items) {
            self.items = items;
        }
    }
    return self;
}

- (void)setItems:(NSArray<SLNumberIconItem *> *)items {
    _items = [items copy];
    
    // 清除现有视图
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    [self.itemViews removeAllObjects];

    // 清除分隔点
    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }
    
    // 创建新的项视图
    for (NSInteger i = 0; i < items.count; i++) {
        SLNumberIconItem *item = items[i];
        SLNumberIconItemView *itemView = [[SLNumberIconItemView alloc] init];
        itemView.itemSpacing = self.itemSpacing;
        itemView.touchAreaExtension = self.touchAreaExtension;
        itemView.index = i;
        
        __weak typeof(self) weakSelf = self;
        itemView.clickHandler = ^(NSInteger index) {
            [weakSelf handleItemClickAtIndex:index];
        };
        
        [itemView updateWithItem:item];
        [self addSubview:itemView];
        [self.itemViews addObject:itemView];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // 先清除所有现有的分隔点
    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }
    
    CGFloat x = 0;
    CGFloat height = self.bounds.size.height;
    
    for (NSInteger i = 0; i < self.itemViews.count; i++) {
        SLNumberIconItemView *itemView = self.itemViews[i];
        SLNumberIconItem *item = self.items[i];
        
        // 修改显示逻辑：只有当没有图标、没有自定义文本且未选中时才隐藏整个项
        NSString *customText = [item valueForKey:@"customText"];
        BOOL hasIcon = item.normalImage != nil;
        BOOL hasCustomText = customText.length > 0;
        
        if (!hasIcon && !hasCustomText && !item.isSelected) {
            itemView.hidden = YES;
            continue;
        }
        
        itemView.hidden = NO;
        
        // 计算项视图大小
        CGSize itemSize = [itemView sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)];
        
        // 设置项视图位置
        itemView.frame = CGRectMake(x, 0, itemSize.width, height);
        
        // 更新下一个项的起始位置
        x += itemSize.width;
        
        // 如果不是最后一个可见项，添加分隔点
        if (i < self.itemViews.count - 1) {
            // 检查下一个项是否可见
            BOOL nextItemVisible = NO;
            for (NSInteger j = i + 1; j < self.itemViews.count; j++) {
                SLNumberIconItem *nextItem = self.items[j];
                NSString *nextCustomText = [nextItem valueForKey:@"customText"];
                BOOL nextHasIcon = nextItem.normalImage != nil;
                BOOL nextHasCustomText = nextCustomText.length > 0;
                
                if (nextHasIcon || nextHasCustomText || nextItem.isSelected) {
                    nextItemVisible = YES;
                    break;
                }
            }
            
            if (nextItemVisible) {
                // 添加分隔点
                UIView *separatorDot = [[UIView alloc] initWithFrame:CGRectMake(x + _spacing - 1, height/2 - 1, 2, 2)];
                separatorDot.backgroundColor = [SLColorManager categorySelectedTextColor];
                separatorDot.layer.cornerRadius = 1;
                separatorDot.tag = 1000 + i; // 使用tag标识分隔点
                [self addSubview:separatorDot];
                
                // 更新位置，考虑分隔点和间距
                x += _spacing * 2;
            }
        }
    }
    
    // 移除多余的分隔点
    for (UIView *subview in self.subviews) {
        if (subview.tag >= 1000 && subview.tag < 1000 + self.itemViews.count) {
            NSInteger dotIndex = subview.tag - 1000;
            if (dotIndex >= self.itemViews.count - 1 || self.itemViews[dotIndex].hidden || self.itemViews[dotIndex+1].hidden) {
                [subview removeFromSuperview];
            }
        }
    }
}

- (void)updateNumber:(NSInteger)number atIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return;
    }
    
    SLNumberIconItem *item = self.items[index];
    item.number = number;
    
    SLNumberIconItemView *itemView = self.itemViews[index];
    [itemView updateWithItem:item];
    
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected atIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return;
    }
    
    SLNumberIconItem *item = self.items[index];
    item.isSelected = selected;
    
    SLNumberIconItemView *itemView = self.itemViews[index];
    [itemView updateWithItem:item];
    
    [self setNeedsLayout];
}

- (BOOL)isSelectedAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return NO;
    }
    
    return self.items[index].isSelected;
}

- (void)handleItemClickAtIndex:(NSInteger)index {
    // 如果有选中图标，则切换选中状态
    SLNumberIconItem *item = self.items[index];
    if (item.selectedImage) {
        item.isSelected = !item.isSelected;
        SLNumberIconItemView *itemView = self.itemViews[index];
        [itemView updateWithItem:item];
    }
    
    // 调用代理方法
    if ([self.delegate respondsToSelector:@selector(numberIconView:didClickAtIndex:)]) {
        [self.delegate numberIconView:self didClickAtIndex:index];
    }
}

@end
