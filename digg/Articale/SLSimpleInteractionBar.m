//
//  SLSimpleInteractionBar.m
//  digg
//
//  Created by Tim Bao on 2025/5/20.
//

#import "SLSimpleInteractionBar.h"
#import "SLNumberIconView.h"
#import "SLColorManager.h"
#import "Masonry.h"

@interface SLSimpleInteractionBar () <SLNumberIconViewDelegate>

@property (nonatomic, strong) SLNumberIconView *leftIconView;  // 左侧点赞和不喜欢
@property (nonatomic, strong) UIButton *replyButton;          // 右侧回复按钮
@property (nonatomic, strong) NSMutableArray<SLNumberIconItem *> *leftItems;

// 固定索引常量
@property (nonatomic, assign, readonly) NSInteger likeIndex;
@property (nonatomic, assign, readonly) NSInteger dislikeIndex;

@end

@implementation SLSimpleInteractionBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _likeIndex = 0;
        _dislikeIndex = 1;
        
        [self setupItems];
        [self setupViews];
    }
    return self;
}

- (void)setupItems {
    // 初始化左侧项目（点赞和不喜欢）
    _leftItems = [NSMutableArray array];
    
    // 点赞
    SLNumberIconItem *likeItem = [SLNumberIconItem itemWithNumber:0 
                                                      normalImage:[UIImage imageNamed:@"agree"] 
                                                    selectedImage:[UIImage imageNamed:@"agree_selected"]];
    likeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    likeItem.iconColor = [SLColorManager caocaoButtonTextColor];
    [_leftItems addObject:likeItem];
    
    // 不喜欢
    SLNumberIconItem *dislikeItem = [SLNumberIconItem itemWithNumber:0 
                                                         normalImage:[UIImage imageNamed:@"disagree"] 
                                                       selectedImage:[UIImage imageNamed:@"disagree_selected"]];
    dislikeItem.numberColor = [SLColorManager caocaoButtonTextColor];
    dislikeItem.iconColor = [SLColorManager caocaoButtonTextColor];
    [_leftItems addObject:dislikeItem];
}

- (void)setupViews {
    // 创建左侧视图
    _leftIconView = [[SLNumberIconView alloc] initWithFrame:CGRectZero items:_leftItems];
    _leftIconView.delegate = self;
    _leftIconView.spacing = 12.0;
    _leftIconView.itemSpacing = 4.0;
    _leftIconView.touchAreaExtension = 10.0;
    [self addSubview:_leftIconView];
    
    // 创建右侧回复按钮
    _replyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_replyButton setTitle:@"回复" forState:UIControlStateNormal];
    [_replyButton setTitleColor:[SLColorManager caocaoButtonTextColor] forState:UIControlStateNormal];
    _replyButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [_replyButton addTarget:self action:@selector(replyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_replyButton];

    // 计算"回复"文本的宽度
    UILabel* label = [UILabel new];
    label.text = @"回复";
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    CGSize replySize = [label sizeThatFits:CGSizeZero];
    CGFloat replyWidth = replySize.width + 1;
    
    [_leftIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self);
        make.right.equalTo(_replyButton.mas_left).offset(-10);
    }];
    [_replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.right.equalTo(self);
        make.width.mas_equalTo(replyWidth);
    }];
}

#pragma mark - Actions

- (void)replyButtonTapped {
    if ([self.delegate respondsToSelector:@selector(interactionBarDidTapReply:)]) {
        [self.delegate interactionBarDidTapReply:self];
    }
}

#pragma mark - Public Methods

- (void)updateLikeNumber:(NSInteger)number {
    [self.leftIconView updateNumber:number atIndex:self.likeIndex];
}

- (void)updateDislikeNumber:(NSInteger)number {
    [self.leftIconView updateNumber:number atIndex:self.dislikeIndex];
}

- (void)setLikeSelected:(BOOL)selected {
    [self.leftIconView setSelected:selected atIndex:self.likeIndex];
}

- (void)setDislikeSelected:(BOOL)selected {
    [self.leftIconView setSelected:selected atIndex:self.dislikeIndex];
}

- (BOOL)isLikeSelected {
    return [self.leftIconView isSelectedAtIndex:self.likeIndex];
}

- (BOOL)isDislikeSelected {
    return [self.leftIconView isSelectedAtIndex:self.dislikeIndex];
}

#pragma mark - SLNumberIconViewDelegate

- (void)numberIconView:(SLNumberIconView *)numberIconView didClickAtIndex:(NSInteger)index {
    if (numberIconView == self.leftIconView) {
        if (index == self.likeIndex) {
            BOOL selected = [numberIconView isSelectedAtIndex:index];
            
            // 如果点赞被选中，取消不喜欢的选中状态
            if (selected) {
                [self.leftIconView setSelected:NO atIndex:self.dislikeIndex];
            }
            
            if ([self.delegate respondsToSelector:@selector(interactionBar:didTapLikeWithSelected:)]) {
                [self.delegate interactionBar:self didTapLikeWithSelected:selected];
            }
        } 
        else if (index == self.dislikeIndex) {
            BOOL selected = [numberIconView isSelectedAtIndex:index];
            
            // 如果不喜欢被选中，取消点赞的选中状态
            if (selected) {
                [self.leftIconView setSelected:NO atIndex:self.likeIndex];
            }
            
            if ([self.delegate respondsToSelector:@selector(interactionBar:didTapDislikeWithSelected:)]) {
                [self.delegate interactionBar:self didTapDislikeWithSelected:selected];
            }
        }
    } 
}

@end
