//
//  SLTagListView.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLTagListView.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLHomeTagViewV2.h"


@interface SLTagListView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<SLHomeTagViewV2 *> *tagViews;
@property (nonatomic, strong) NSArray<NSString *> *tags;

@end

@implementation SLTagListView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    // 创建滚动视图
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];
    
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    _tagViews = [NSMutableArray array];
}

- (void)setTags:(NSArray<NSString *> *)tags {
    _tags = tags;
    
    // 清除现有的标签视图
    for (SLHomeTagViewV2 *tagView in _tagViews) {
        [tagView removeFromSuperview];
    }
    [_tagViews removeAllObjects];
    
    if (tags.count == 0) {
        return;
    }
    
    // 创建新的标签视图
    CGFloat offsetX = 0;
    CGFloat tagHeight = 24;
    CGFloat tagSpacing = 12;
    
    for (NSString *tag in tags) {
        SLHomeTagViewV2 *tagView = [[SLHomeTagViewV2 alloc] init];
        tagView.tagLabel.text = tag;
        tagView.userInteractionEnabled = YES;
        
        // 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagViewTapped:)];
        [tagView addGestureRecognizer:tapGesture];
        
        [_scrollView addSubview:tagView];
        [_tagViews addObject:tagView];
        
        // 计算标签视图宽度
        CGSize titleSize = [tag boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, tagHeight)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName: tagView.tagLabel.font}
                                            context:nil].size;
        CGFloat tagWidth = titleSize.width + 20; // 左右各10点的内边距
        
        tagView.frame = CGRectMake(offsetX, 0, tagWidth, tagHeight);
        offsetX += tagWidth + tagSpacing;
    }
    
    // 设置滚动视图的内容大小
    _scrollView.contentSize = CGSizeMake(offsetX, tagHeight);
}

- (void)tagViewTapped:(UITapGestureRecognizer *)gesture {
    SLHomeTagViewV2 *tagView = (SLHomeTagViewV2 *)gesture.view;
    if (self.tagClickHandler) {
        self.tagClickHandler(tagView.tagLabel.text);
    }
}

- (CGFloat)getContentHeight {
    // 如果没有标签，返回0高度
    if (_tags.count == 0) {
        return 0;
    }
    
    // 返回滚动视图的内容高度
    // 如果是水平滚动的标签列表，可以返回固定高度
    return 24; // 标签按钮的高度
    
    // 如果是垂直布局的标签列表，可以返回内容的实际高度
    // return _scrollView.contentSize.height;
}

@end
