#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPageControlView : UIView

@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hidesForSinglePage;

@property (nonatomic, assign) CGFloat dotDiameter;        // default 8
@property (nonatomic, assign) CGFloat dotSpacing;         // default 12
@property (nonatomic, assign) UIEdgeInsets contentInsets; // default {6,12,6,12}

@property (nonatomic, strong) UIColor *dotColor;          // default alpha gray
@property (nonatomic, strong) UIColor *currentDotColor;   // default white
@property (nonatomic, strong) UIColor *backgroundFillColor; // default black alpha

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

