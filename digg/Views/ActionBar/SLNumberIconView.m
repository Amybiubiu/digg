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
// New property to enforce uniform size
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
        _iconSize = 16.0; // Default fallback
        
        // Create number label
        _numberLabel = [[UILabel alloc] init];
        _numberLabel.textAlignment = NSTextAlignmentLeft;
        _numberLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        [self addSubview:_numberLabel];
        
        // Create icon view
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconImageView];
        
        // Create custom text label
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _customTextLabel.hidden = YES;
        [self addSubview:_customTextLabel];
        
        // Create touch button
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
    
    // Calculate number label width
    CGFloat numberWidth = NUMBER_LABLE_WIDTH;
    
    // Handle Icon - Layout on the left
    CGFloat currentIconWidth = 0;
    if (!_iconImageView.hidden) {
        // --- MODIFIED: Enforce fixed size instead of image size ---
        currentIconWidth = self.iconSize;
        if (currentIconWidth == 0) {
             // Fallback just in case iconSize isn't set
            currentIconWidth = height * 0.6;
        }

        _iconImageView.frame = CGRectMake(0, (height - currentIconWidth) / 2, currentIconWidth, currentIconWidth);
    }
    
    // Layout Number Label - Layout on the right
    CGFloat numberX = currentIconWidth > 0 ? (currentIconWidth + _itemSpacing) : 0;
    _numberLabel.frame = CGRectMake(numberX, 0, numberWidth, height);
    _numberLabel.textAlignment = NSTextAlignmentLeft;
    
    // Handle Custom Text
    if (_customTextLabel && !_customTextLabel.hidden) {
        CGFloat textWidth = [_customTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width;
        CGFloat textX = currentIconWidth > 0 ? (currentIconWidth + _itemSpacing) : 0;
        _customTextLabel.frame = CGRectMake(textX, 0, textWidth, height);
    }
    
    // Layout Touch Button
    _touchButton.frame = CGRectMake(-_touchAreaExtension, 
                                   -_touchAreaExtension, 
                                   totalWidth + _touchAreaExtension * 2, 
                                   height + _touchAreaExtension * 2);
}

- (void)updateWithItem:(SLNumberIconItem *)item {
    _item = item;
    
    // Update Number
    if (item.number > 0) {
        _numberLabel.text = [NSString stringWithFormat:@"%ld", (long)item.number];
        _numberLabel.textColor = item.numberColor;
        _numberLabel.hidden = NO;
    } else {
        _numberLabel.hidden = YES;
    }
    
    // Handle Custom Text
    NSString *customText = [item valueForKey:@"customText"];
    if (customText.length > 0) {
        _iconImageView.hidden = YES;
        _customTextLabel.text = customText;
        _customTextLabel.textColor = item.numberColor;
        _customTextLabel.hidden = NO;
    } else {
        _customTextLabel.hidden = YES;
        
        // Update Icon
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
    
    // Calculate Icon Width
    CGFloat currentIconWidth = 0;
    NSString *customText = [_item valueForKey:@"customText"];
    
    if (customText.length == 0 && !_iconImageView.hidden) {
        // --- MODIFIED: Use fixed size for calculation ---
        currentIconWidth = self.iconSize;
        if (currentIconWidth == 0) {
            currentIconWidth = height * 0.6;
        }
        width += currentIconWidth;
        
        // Add spacing if we have an icon
        width += _itemSpacing;
    }
    
    // Calculate Number Width
    // if (_item.number > 0) {
        CGFloat numberWidth = NUMBER_LABLE_WIDTH;
        width += numberWidth;
    // }
    
    // Handle Custom Text Width
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
        _iconSize = 16.0; // Ensure this is the desired uniform size
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
    
    // Clear existing views
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    [self.itemViews removeAllObjects];

    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }
    
    // Create new item views
    for (NSInteger i = 0; i < items.count; i++) {
        SLNumberIconItem *item = items[i];
        SLNumberIconItemView *itemView = [[SLNumberIconItemView alloc] init];
        itemView.itemSpacing = self.itemSpacing;
        itemView.touchAreaExtension = self.touchAreaExtension;
        
        // --- MODIFIED: Pass the container's iconSize to the item ---
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

    // Clear separators
    for (UIView *subview in [self.subviews copy]) {
        if (subview.tag >= 1000) {
            [subview removeFromSuperview];
        }
    }

    CGFloat height = self.bounds.size.height;
    CGFloat totalWidth = self.bounds.size.width;

    // Collect visible items
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
            // sizeThatFits will now calculate width based on the fixed iconSize
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

    // Space-between calculation (handles the 100% width requirement automatically)
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

// ... rest of the existing methods (updateNumber, setSelected, etc.) remain unchanged ...

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