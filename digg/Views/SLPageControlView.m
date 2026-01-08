#import "SLPageControlView.h"

@interface SLPageControlView ()
@property (nonatomic, strong) NSMutableArray<CALayer *> *dotLayers;
@end

@implementation SLPageControlView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _numberOfPages = 0;
        _currentPage = 0;
        _hidesForSinglePage = NO;
        _dotDiameter = 8.0;
        _dotSpacing = 12.0;
        _contentInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        _dotColor = [UIColor colorWithWhite:1 alpha:0.35];
        _currentDotColor = [UIColor whiteColor];
        _backgroundFillColor = [UIColor colorWithWhite:0 alpha:0.35];
        _dotLayers = [NSMutableArray array];
        self.backgroundColor = _backgroundFillColor;
        // 移除 masksToBounds 以显示阴影
        self.layer.masksToBounds = NO;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGFloat w = self.contentInsets.left + self.contentInsets.right;
    if (self.numberOfPages > 0) {
        w += self.numberOfPages * self.dotDiameter;
        w += (self.numberOfPages - 1) * self.dotSpacing;
    }
    CGFloat h = self.contentInsets.top + self.contentInsets.bottom + self.dotDiameter;
    return CGSizeMake(w, h);
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    if (_numberOfPages == numberOfPages) return;
    _numberOfPages = MAX(0, numberOfPages);
    [self rebuildDots];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated {
    NSInteger newPage = MIN(MAX(0, currentPage), MAX(0, self.numberOfPages - 1));
    if (_currentPage == newPage && self.dotLayers.count > 0) return;
    _currentPage = newPage;
    [self updateDotColorsAnimated:animated];
}

- (void)setDotDiameter:(CGFloat)dotDiameter {
    _dotDiameter = MAX(1.0, dotDiameter);
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setDotSpacing:(CGFloat)dotSpacing {
    _dotSpacing = MAX(0.0, dotSpacing);
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {
    _contentInsets = contentInsets;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setBackgroundFillColor:(UIColor *)backgroundFillColor {
    _backgroundFillColor = backgroundFillColor ?: [UIColor clearColor];
    self.backgroundColor = _backgroundFillColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = self.bounds.size.height;
    self.layer.cornerRadius = height / 2.0;

    // 添加细边框以提高清晰度
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;

    // 添加整体阴影效果以提高可见性
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 3.0;
    self.layer.shadowOpacity = 0.3;

    [self positionDots];
}

- (void)rebuildDots {
    for (CALayer *layer in self.dotLayers) {
        [layer removeFromSuperlayer];
    }
    [self.dotLayers removeAllObjects];

    if (self.hidesForSinglePage && self.numberOfPages <= 1) {
        self.hidden = YES;
        return;
    }
    self.hidden = (self.numberOfPages == 0);

    for (NSInteger i = 0; i < self.numberOfPages; i++) {
        CALayer *dot = [CALayer layer];
        dot.cornerRadius = self.dotDiameter / 2.0;
        dot.backgroundColor = (i == self.currentPage ? self.currentDotColor.CGColor : self.dotColor.CGColor);

        // 添加阴影以提高可见性
        dot.shadowColor = [UIColor blackColor].CGColor;
        dot.shadowOffset = CGSizeMake(0, 1);
        dot.shadowRadius = 2.0;
        dot.shadowOpacity = 0.5;

        [self.layer addSublayer:dot];
        [self.dotLayers addObject:dot];
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)positionDots {
    if (self.dotLayers.count == 0) return;
    CGFloat startX = self.contentInsets.left;
    CGFloat y = (self.bounds.size.height - self.dotDiameter) / 2.0;
    for (NSInteger i = 0; i < self.dotLayers.count; i++) {
        CALayer *dot = self.dotLayers[i];
        dot.frame = CGRectMake(startX, y, self.dotDiameter, self.dotDiameter);
        startX += self.dotDiameter + self.dotSpacing;
    }
}

- (void)updateDotColorsAnimated:(BOOL)animated {
    [CATransaction begin];
    [CATransaction setAnimationDuration:(animated ? 0.2 : 0.0)];
    for (NSInteger i = 0; i < self.dotLayers.count; i++) {
        CALayer *dot = self.dotLayers[i];
        dot.backgroundColor = (i == self.currentPage ? self.currentDotColor.CGColor : self.dotColor.CGColor);
    }
    [CATransaction commit];
}

@end

