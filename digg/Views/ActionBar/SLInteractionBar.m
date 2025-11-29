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
    // 1. 点赞
    SLNumberIconItem *likeItem = [SLNumberIconItem itemWithNumber:0
                                                      normalImage:[UIImage imageNamed:@"agree"]
                                                    selectedImage:[UIImage imageNamed:@"agree_selected"]];
    likeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    // likeItem.iconColor = [SLColorManager caocaoButtonTextColor];
    likeItem.interactionType = SLInteractionTypeLike;
    likeItem.fixedWidth = 33.0; 
    [self.itemsDict setObject:likeItem forKey:@(SLInteractionTypeLike)];

    // 2. 评论
    SLNumberIconItem *commentItem = [SLNumberIconItem itemWithNumber:0
                                                         normalImage:[UIImage imageNamed:@"message"]
                                                       selectedImage:nil];
    commentItem.numberColor = [SLColorManager caocaoButtonTextColor];
    commentItem.interactionType = SLInteractionTypeComment;
    commentItem.fixedWidth = 33.0;
    [self.itemsDict setObject:commentItem forKey:@(SLInteractionTypeComment)];

    // 3. 访问URL（新增功能）- 使用系统链接图标或check图标
    UIImage *linkIcon = [UIImage imageNamed:@"link"];
    SLNumberIconItem *linkItem = [SLNumberIconItem itemWithNumber:0
                                                       normalImage:linkIcon
                                                     selectedImage:nil];
    linkItem.numberColor = [SLColorManager caocaoButtonTextColor];
    linkItem.interactionType = SLInteractionTypeCustom;
    [self.itemsDict setObject:linkItem forKey:@(SLInteractionTypeCustom)];

    // 4. 点踩
    SLNumberIconItem *dislikeItem = [SLNumberIconItem itemWithNumber:0
                                                         normalImage:[UIImage imageNamed:@"disagree"]
                                                       selectedImage:[UIImage imageNamed:@"disagree_selected"]];
    dislikeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    dislikeItem.interactionType = SLInteractionTypeDislike;
    [self.itemsDict setObject:dislikeItem forKey:@(SLInteractionTypeDislike)];
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
    // 增加特殊逻辑：对于点踩 (SLInteractionTypeDislike)，一直不显示数字
    // 将 number 强制置为 0，通常 UI 控件在 count 为 0 时会自动隐藏数字标签
    if (type == SLInteractionTypeDislike) {
        number = 0;
    }
    
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
