//
//  SLNumberIconView.m
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import "SLNumberIconView.h"
#import "SLColorManager.h"

#define DOT_WIDTH 1
#define NUMBER_LABLE_WIDTH 40

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
@property (nonatomic, assign) CGFloat iconSize;

- (void)updateWithItem:(SLNumberIconItem *)item;
- (CGSize)sizeThatFits:(CGSize)size;

@end

@implementation SLNumberIconItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _itemSpacing = 4.0;
        _touchAreaExtension = 10.0;
        _iconSize = 16.0;
        
        _numberLabel = [[UILabel alloc] init];
        _numberLabel.textAlignment = NSTextAlignmentLeft;
        _numberLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        [self addSubview:_numberLabel];
        
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconImageView];
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _customTextLabel.hidden = YES;
        [self addSubview:_customTextLabel];
        
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
    
    // Icon Layout
    CGFloat currentIconWidth = 0;
    if (!_iconImageView.hidden) {
        currentIconWidth = self.iconSize;
        if (currentIconWidth == 0) {
            currentIconWidth = height * 0.6;
        }
        // 垂直居中
        _iconImageView.frame = CGRectMake(0, (height - currentIconWidth) / 2, currentIconWidth, currentIconWidth);
    }
    
    // Calculate content start X for Label
    CGFloat contentStartX = currentIconWidth > 0 ? (currentIconWidth + _itemSpacing) : 0;
    
    // Number Label Layout
    // 修改逻辑：如果设置了 fixedWidth，Label 的宽度应填充剩余空间，而不是固定 40
    CGFloat currentNumberWidth = NUMBER_LABLE_WIDTH;
    if (self.item.fixedWidth > 0) {
        currentNumberWidth = totalWidth - contentStartX; // 填满剩余空间
        if (currentNumberWidth < 0) currentNumberWidth = 0;
    }
    
    _numberLabel.frame = CGRectMake(contentStartX, 0, currentNumberWidth, height);
    
    // Custom Text Layout
    if (_customTextLabel && !_customTextLabel.hidden) {
        CGFloat textWidth = [_customTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        _customTextLabel.frame = CGRectMake(contentStartX, 0, textWidth, height);
    }
    
    // Touch Button Layout
    _touchButton.frame = CGRectMake(-_touchAreaExtension,
                                   -_touchAreaExtension,
                                   totalWidth + _touchAreaExtension * 2,
                                   height + _touchAreaExtension * 2);
}

- (void)updateWithItem:(SLNumberIconItem *)item {
    _item = item;
    
    if (item.number > 0) {
        _numberLabel.text = [NSString stringWithFormat:@"%ld", (long)item.number];
        _numberLabel.textColor = item.numberColor;
        _numberLabel.hidden = NO;
    } else {
        // 即便是 hidden，我们也要在 layoutSubviews 里保留位置（如果是固定宽度的话）
        _numberLabel.hidden = YES;
    }
    
    NSString *customText = [item valueForKey:@"customText"];
    if (customText.length > 0) {
        _iconImageView.hidden = YES;
        _customTextLabel.text = customText;
        _customTextLabel.textColor = item.numberColor;
        _customTextLabel.hidden = NO;
    } else {
        _customTextLabel.hidden = YES;
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
    // --- 核心修改：如果设置了 fixedWidth，直接返回固定宽度 ---
    // 注意：前提是你已经在 SLNumberIconItem.h 中添加了 fixedWidth 属性
    if (self.item.fixedWidth > 0) {
        return CGSizeMake(self.item.fixedWidth, size.height);
    }
    // ---------------------------------------------------

    CGFloat width = 0;
    CGFloat height = size.height;
    
    CGFloat currentIconWidth = 0;
    NSString *customText = [_item valueForKey:@"customText"];
    
    if (customText.length == 0 && !_iconImageView.hidden) {
        currentIconWidth = self.iconSize;
        if (currentIconWidth == 0) {
            currentIconWidth = height * 0.6;
        }
        width += currentIconWidth;
        width += _itemSpacing;
    }
    
    BOOL shouldShowNumber = _item.number > 0;
    // 假设 SLNumberIconItem 有 interactionType 属性，且 SLInteractionTypeDislike 为 1
    // 如果 item 没有 interactionType 属性，请确保在 Item 类中添加
    if ([_item respondsToSelector:@selector(interactionType)] && _item.interactionType == 1) {
        shouldShowNumber = NO;
    }

    if (shouldShowNumber) {
        CGFloat numberWidth = NUMBER_LABLE_WIDTH;
        width += numberWidth;
    }
    
    if (customText.length > 0) {
        CGFloat textWidth = [_customTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        width += textWidth;
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
        _spacing = 2;
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
    
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    [self.itemViews removeAllObjects];

    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }
    
    for (NSInteger i = 0; i < items.count; i++) {
        SLNumberIconItem *item = items[i];
        SLNumberIconItemView *itemView = [[SLNumberIconItemView alloc] init];
        itemView.itemSpacing = self.itemSpacing;
        itemView.touchAreaExtension = self.touchAreaExtension;
        itemView.iconSize = self.iconSize;
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

    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }

    CGFloat height = self.bounds.size.height;
    CGFloat totalWidth = self.bounds.size.width;

    NSMutableArray *visibleItemViews = [NSMutableArray array];
    NSMutableArray *visibleItemSizes = [NSMutableArray array];

    for (NSInteger i = 0; i < self.itemViews.count; i++) {
        SLNumberIconItemView *itemView = self.itemViews[i];
        SLNumberIconItem *item = self.items[i];

        NSString *customText = [item valueForKey:@"customText"];
        BOOL hasIcon = item.normalImage != nil;
        BOOL hasCustomText = customText.length > 0;

        if (!hasIcon && !hasCustomText && !item.isSelected) {
            itemView.hidden = YES;
            continue;
        }

        itemView.hidden = item.hidden;
        if (!itemView.hidden) {
            [visibleItemViews addObject:itemView];
            // 这里会调用上面修改过的 sizeThatFits
            CGSize itemSize = [itemView sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)];
            [visibleItemSizes addObject:[NSValue valueWithCGSize:itemSize]];
        }
    }

    if (visibleItemViews.count == 0) {
        return;
    }

    CGFloat totalItemsWidth = 0;
    for (NSValue *sizeValue in visibleItemSizes) {
        totalItemsWidth += sizeValue.CGSizeValue.width;
    }

    // 计算间距 (Space-between 逻辑)
    CGFloat availableSpacing = totalWidth - totalItemsWidth;
    CGFloat spacingBetweenItems = 0;

    if (visibleItemViews.count > 1) {
        spacingBetweenItems = availableSpacing / (visibleItemViews.count - 1);
    }

    CGFloat currentX = 0;
    for (NSInteger i = 0; i < visibleItemViews.count; i++) {
        SLNumberIconItemView *itemView = visibleItemViews[i];
        CGSize itemSize = [visibleItemSizes[i] CGSizeValue];

        itemView.frame = CGRectMake(currentX, 0, itemSize.width, height);
        currentX += itemSize.width + spacingBetweenItems;
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
    
    // 更新数字后需要重新布局，但如果是 fixedWidth，layoutSubviews 不会改变 Frame 宽度，只会重新绘制内部 Label
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
    SLNumberIconItem *item = self.items[index];
    if (item.selectedImage) {
        item.isSelected = !item.isSelected;
        SLNumberIconItemView *itemView = self.itemViews[index];
        [itemView updateWithItem:item];
    }
    
    if ([self.delegate respondsToSelector:@selector(numberIconView:didClickAtIndex:)]) {
        [self.delegate numberIconView:self didClickAtIndex:index];
    }
}

- (void)setItemHidden:(BOOL)hidden atIndex:(NSInteger)index {
    if (index < self.items.count) {
        SLNumberIconItem *item = self.items[index];
        item.hidden = hidden;
        
        if (index < self.itemViews.count) {
            SLNumberIconItemView *itemView = self.itemViews[index];
            itemView.hidden = hidden;
        }
    }
}

@end