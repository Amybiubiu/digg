//
//  SLInteractionBar.m
//  digg
//
//  Created by Tim Bao on 2023/11/20.
//

#import "SLInteractionBar.h"
#import "SLColorManager.h"

@interface SLInteractionBar ()

@property (nonatomic, strong) SLNumberIconView *numberIconView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SLNumberIconItem *> *itemsDict;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *typeOrder;

@end

@implementation SLInteractionBar

- (instancetype)initWithFrame:(CGRect)frame interactionTypes:(NSArray<NSNumber *> *)types {
    self = [super initWithFrame:frame];
    if (self) {
        _spacing = 15.0;
        _itemSpacing = 4.0;
        _touchAreaExtension = 10.0;
        _itemsDict = [NSMutableDictionary dictionary];
        _typeOrder = [NSMutableArray array];
        
        // 初始化默认项
        [self setupDefaultItems];
        
        // 创建数字图标视图
        NSMutableArray *items = [NSMutableArray array];
        
        for (NSNumber *typeNumber in types) {
            SLInteractionType type = [typeNumber integerValue];
            SLNumberIconItem *item = [self itemForType:type];
            if (item) {
                [items addObject:item];
                [_typeOrder addObject:typeNumber];
            }
        }
        
        _numberIconView = [[SLNumberIconView alloc] initWithFrame:self.bounds items:items];
        _numberIconView.delegate = self;
        _numberIconView.spacing = _spacing;
        _numberIconView.itemSpacing = _itemSpacing;
        _numberIconView.touchAreaExtension = _touchAreaExtension;
        [self addSubview:_numberIconView];
        
        // 设置自动布局
        _numberIconView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_numberIconView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_numberIconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_numberIconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_numberIconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    return self;
}

- (void)setupDefaultItems {
    // 点赞
    SLNumberIconItem *likeItem = [SLNumberIconItem itemWithNumber:0 
                                                      normalImage:[UIImage imageNamed:@"agree"] 
                                                    selectedImage:[UIImage imageNamed:@"agree_selected"]];
    likeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    likeItem.iconColor = [SLColorManager caocaoButtonTextColor];
    [self.itemsDict setObject:likeItem forKey:@(SLInteractionTypeLike)];
    
    // 不喜欢
    SLNumberIconItem *dislikeItem = [SLNumberIconItem itemWithNumber:0 
                                                         normalImage:[UIImage imageNamed:@"disagree"] 
                                                       selectedImage:[UIImage imageNamed:@"disagree_selected"]];
    dislikeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    dislikeItem.iconColor = [SLColorManager caocaoButtonTextColor];
    [self.itemsDict setObject:dislikeItem forKey:@(SLInteractionTypeDislike)];
    
    // 评论
    SLNumberIconItem *commentItem = [SLNumberIconItem itemWithNumber:0 
                                                         normalImage:[UIImage imageNamed:@"message"] 
                                                       selectedImage:nil];
    commentItem.numberColor = [SLColorManager caocaoButtonTextColor];
    commentItem.iconColor = [SLColorManager caocaoButtonTextColor];
    [self.itemsDict setObject:commentItem forKey:@(SLInteractionTypeComment)];

    // 查看
    SLNumberIconItem *checkItem = [SLNumberIconItem itemWithNumber:0 
                                                       normalImage:nil 
                                                     selectedImage:nil];
    checkItem.numberColor = [SLColorManager cellContentColor];
    checkItem.iconColor = [SLColorManager cellContentColor];
    checkItem.customText = @"查看";
    [self.itemsDict setObject:checkItem forKey:@(SLInteractionTypeCustom)];
}

- (SLNumberIconItem *)itemForType:(SLInteractionType)type {
    return self.itemsDict[@(type)];
}

- (void)setSpacing:(CGFloat)spacing {
    _spacing = spacing;
    self.numberIconView.spacing = spacing;
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    self.numberIconView.itemSpacing = itemSpacing;
}

- (void)setTouchAreaExtension:(CGFloat)touchAreaExtension {
    _touchAreaExtension = touchAreaExtension;
    self.numberIconView.touchAreaExtension = touchAreaExtension;
}

- (void)updateNumber:(NSInteger)number forType:(SLInteractionType)type {
    NSInteger index = [self indexForType:type];
    if (index != NSNotFound) {
        [self.numberIconView updateNumber:number atIndex:index];
        
        // 同时更新字典中的数据
        SLNumberIconItem *item = [self itemForType:type];
        if (item) {
            item.number = number;
        }
    }
}

- (void)setSelected:(BOOL)selected forType:(SLInteractionType)type {
    NSInteger index = [self indexForType:type];
    if (index != NSNotFound) {
        [self.numberIconView setSelected:selected atIndex:index];
        
        // 同时更新字典中的数据
        SLNumberIconItem *item = [self itemForType:type];
        if (item) {
            item.isSelected = selected;
        }
    }
}

- (BOOL)isSelectedForType:(SLInteractionType)type {
    NSInteger index = [self indexForType:type];
    if (index != NSNotFound) {
        return [self.numberIconView isSelectedAtIndex:index];
    }
    return NO;
}

- (void)addCustomItem:(SLNumberIconItem *)item forType:(SLInteractionType)type {
    if (type == SLInteractionTypeCustom) {
        NSNumber *typeKey = @(type);
        [self.itemsDict setObject:item forKey:typeKey];
        [self.typeOrder addObject:typeKey];
        
        // 重新构建items数组
        NSMutableArray *items = [NSMutableArray array];
        for (NSNumber *typeNumber in self.typeOrder) {
            SLNumberIconItem *item = [self itemForType:[typeNumber integerValue]];
            if (item) {
                [items addObject:item];
            }
        }
        
        // 更新视图
        self.numberIconView.items = items;
    }
}

- (NSInteger)indexForType:(SLInteractionType)type {
    return [self.typeOrder indexOfObject:@(type)];
}

- (void)hideItemForType:(SLInteractionType)type {
    // 获取对应类型的索引
    NSInteger index = [self indexForType:type];
    if (index != NSNotFound) {
        // 直接隐藏对应的视图
        [self.numberIconView setItemHidden:YES atIndex:index];
    }
}

- (void)showItemForType:(SLInteractionType)type {
    // 获取对应类型的索引
    NSInteger index = [self indexForType:type];
    if (index != NSNotFound) {
        // 直接显示对应的视图
        [self.numberIconView setItemHidden:NO atIndex:index];
    }
}

#pragma mark - SLNumberIconViewDelegate

- (void)numberIconView:(SLNumberIconView *)numberIconView didClickAtIndex:(NSInteger)index {
    if (index < self.typeOrder.count) {
        SLInteractionType type = [self.typeOrder[index] integerValue];
        BOOL selected = [numberIconView isSelectedAtIndex:index];
        
        if ([self.delegate respondsToSelector:@selector(interactionBar:didTapItemWithType:selected:)]) {
            [self.delegate interactionBar:self didTapItemWithType:type selected:selected];
        }
    }
}

@end
