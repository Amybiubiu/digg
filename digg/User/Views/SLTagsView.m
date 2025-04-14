//
//  SLTagsView.m
//  digg
//
//  Created by Tim Bao on 2025/1/8.
//

#import "SLTagsView.h"
#import "Masonry.h"
#import "SLGeneralMacro.h"
#import "SLColorManager.h"

@interface SLTagItemView: UIView

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *tagNameLabel;
@property (nonatomic, strong) UIImageView *tagImageView;
@property (nonatomic, assign) CGSize itemSize;

@end

@implementation SLTagItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.bgView];
        [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.bgView addSubview:self.tagImageView];
        [self.tagImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self).offset(7);
            make.size.mas_equalTo(CGSizeMake(10, 10));
        }];
        [self.bgView addSubview:self.tagNameLabel];
        [self.tagNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.top.equalTo(self).offset(7);
            make.bottom.equalTo(self).offset(-7);
            make.left.equalTo(self.tagImageView.mas_right).offset(4);
            make.right.equalTo(self).offset(-11);
        }];
    }
    return self;
}

- (void)bindData:(NSString *)name {
    self.tagNameLabel.text = name;

    CGSize labelSize = [self.tagNameLabel sizeThatFits:CGSizeZero];
    self.itemSize = CGSizeMake(labelSize.width + 32, 31);
}

#pragma mark - UI Elements
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.backgroundColor = UIColor.clearColor;
        _bgView.layer.borderColor = [[SLColorManager categorySelectedTextColor] colorWithAlphaComponent:0.2].CGColor;
        _bgView.layer.borderWidth = 0.5;
        _bgView.layer.masksToBounds = YES;
        _bgView.layer.cornerRadius = 15.5;
    }
    return _bgView;
}

- (UIImageView *)tagImageView {
    if (!_tagImageView) {
        _tagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag_icon"]];
    }
    return _tagImageView;
}

- (UILabel *)tagNameLabel {
    if (!_tagNameLabel) {
        _tagNameLabel = [[UILabel alloc] init];
        _tagNameLabel.text = @"";
        _tagNameLabel.textColor = [SLColorManager cellTitleColor];
        _tagNameLabel.font = [UIFont pingFangRegularWithSize:12];
        _tagNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tagNameLabel;
}

@end

@interface SLTagsView()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray<NSString *> *tagsArray;
@property (nonatomic, assign) CGFloat totalHeight; // 最终计算的高度
@property (nonatomic, assign) CGFloat maxWidth; // 最长宽度

@end

@implementation SLTagsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 初始化 ScrollView
        self.scrollView = [[UIScrollView alloc] init];
        [self addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

- (void)setTags:(NSArray<NSString *> *)tags maxWidth:(CGFloat)maxWidth {
    self.tagsArray = tags;
    [self layoutTagsWithMaxWidth:maxWidth];
}

/// 动态布局标签
- (void)layoutTagsWithMaxWidth:(CGFloat)maxWidth {
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)]; // 移除之前的标签
    
    CGFloat totalWidth = 0;
    NSMutableArray<NSNumber *> *tagWidths = [NSMutableArray array];
    
    // 计算每个标签的宽度
    for (NSString *tag in self.tagsArray) {
        CGSize itemSize = [self getTagItemSize:tag];
        [tagWidths addObject:@(itemSize.width)];
        totalWidth += itemSize.width + (totalWidth == 0 ? 0 : 12); // 12 是标签间距
    }
    
    if (totalWidth <= maxWidth) {
        // 情况 1：总宽度小于等于屏幕宽度，单行显示
        [self layoutTagsInSingleLineWithWidths:tagWidths maxWidth:maxWidth];
    } else if (totalWidth <= 2 * maxWidth) {
        // 情况 2：总宽度小于等于两倍屏幕宽度，双行显示且不滚动
        [self layoutTagsInTwoLinesWithWidths:tagWidths balanced:NO maxWidth:maxWidth];
    } else {
        // 情况 3：总宽度超过两倍屏幕宽度，动态分配标签并支持滚动
        [self layoutTagsInTwoLinesWithWidths:tagWidths balanced:YES maxWidth:maxWidth];
    }
}

- (void)layoutTagsInSingleLineWithWidths:(NSArray<NSNumber *> *)tagWidths maxWidth:(CGFloat)maxWidth {
    CGFloat x = 0; // 左边距
    CGFloat y = 12; // 顶部间距
    CGFloat rowHeight = 31; // 每行高度
    for (int i = 0; i < tagWidths.count; i++) {
        CGFloat width = tagWidths[i].floatValue;
        SLTagItemView* tag = [self createTagItemWithTitle:self.tagsArray[i]];
        tag.frame = CGRectMake(x, y, width, rowHeight);
        [self.scrollView addSubview:tag];
        x += width + 12; // 累加X位置
    }
    
    self.totalHeight = rowHeight + 12 * 2; // 单行高度
    self.scrollView.contentSize = CGSizeMake(maxWidth, rowHeight + self.totalHeight);
}

- (void)layoutTagsInTwoLinesWithWidths:(NSArray<NSNumber *> *)tagWidths balanced:(BOOL)balanced maxWidth:(CGFloat)maxWidth {
    CGFloat x = 0; // 左边距
    CGFloat y = 12; // 第一行顶部间距
    CGFloat rowHeight = 31; // 每行高度
    CGFloat rowWidth = 0; // 当前行宽度
    int rowCount = 1; // 当前行数
    
    // 如果需要平衡两行
    if (balanced) {
        // 平均分配标签到两行
        NSUInteger totalTags = tagWidths.count;
        NSUInteger midIndex = totalTags / 2; // 中间索引
        if (totalTags % 2 != 0) midIndex += 1; // 奇数情况下调整分配
        
        NSArray<NSNumber *> *firstLineWidths = [tagWidths subarrayWithRange:NSMakeRange(0, midIndex)];
        CGFloat firstWidth = 0;
        for (int i = 0; i < firstLineWidths.count; ++i) {
            NSNumber* itemWidth = firstLineWidths[i];
            firstWidth += [itemWidth floatValue] + 12;
        }
        CGFloat secondWidth = 0;
        NSArray<NSNumber *> *secondLineWidths = [tagWidths subarrayWithRange:NSMakeRange(midIndex, totalTags - midIndex)];
        for (int i = 0; i < secondLineWidths.count; ++i) {
            NSNumber* itemWidth = secondLineWidths[i];
            secondWidth += [itemWidth floatValue] + 12;
        }
        
        [self layoutTagsWithWidths:firstLineWidths atYOffset:y startIndex:0];
        [self layoutTagsWithWidths:secondLineWidths atYOffset:y + rowHeight + 12 startIndex:midIndex];
        
        self.totalHeight = 2 * (rowHeight + 12) + 12; // 两行高度
        CGRect frame = self.scrollView.frame;
        frame.size.height = self.totalHeight;
        self.scrollView.frame = frame;
        self.scrollView.contentSize = CGSizeMake(MAX(firstWidth + 12, secondWidth + 12), self.totalHeight);
        return;
    }
    
    // 普通双行布局
    for (int i = 0; i < tagWidths.count; i++) {
        CGFloat width = tagWidths[i].floatValue;
        if (rowWidth + width >= maxWidth) { // 换行
            rowCount++;
            rowWidth = 0;
            x = 0;
            y += rowHeight + 12; // 下一行顶部间距
        }
        SLTagItemView* tag = [self createTagItemWithTitle:self.tagsArray[i]];
        tag.frame = CGRectMake(x, y, width, rowHeight);
        [self.scrollView addSubview:tag];
        x += width + 12; // 累加X位置
        rowWidth += width + 12;
    }
    
    self.totalHeight = rowCount * (rowHeight + 12) + 12; // 总高度
    self.scrollView.contentSize = CGSizeMake(maxWidth, self.totalHeight);
}

- (void)layoutTagsWithWidths:(NSArray<NSNumber *> *)tagWidths atYOffset:(CGFloat)yOffset startIndex:(NSInteger)startIndex {
    CGFloat x = 0; // 左边距
    CGFloat rowHeight = 31; // 标签高度
    for (int i = 0; i < tagWidths.count; i++) {
        CGFloat width = tagWidths[i].floatValue;
        SLTagItemView* tag = [self createTagItemWithTitle:self.tagsArray[i + startIndex]];
        tag.frame = CGRectMake(x, yOffset, width, rowHeight);
        [self.scrollView addSubview:tag];
        x += width + 12; // 累加X位置
    }
}

/// 获取最终计算的高度
- (CGFloat)calculatedHeight {
    return self.totalHeight;
}

- (SLTagItemView *)createTagItemWithTitle:(NSString *)title {
    SLTagItemView* item = [SLTagItemView new];
    [item bindData:title];
    return item;
}

- (CGSize)getTagItemSize:(NSString *)text {
    CGSize labelSize = [self getLabelSize:text];
    CGSize itemSize = CGSizeMake(labelSize.width + 32, 31);
    return itemSize;
}

- (CGSize)getLabelSize:(NSString *)text {
    UILabel *tagNameLabel = [[UILabel alloc] init];
    tagNameLabel.text = text;
    tagNameLabel.textColor = [SLColorManager cellTitleColor];
    tagNameLabel.font = [UIFont pingFangRegularWithSize:12];
    tagNameLabel.textAlignment = NSTextAlignmentCenter;
    CGSize size = [tagNameLabel sizeThatFits:CGSizeZero];
    return size;
}

@end
