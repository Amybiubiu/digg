//
//  SLCustomNavigationBar.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLCustomNavigationBarDelegate <NSObject>

- (void)navigationBarBackButtonTapped;
- (void)navigationBarMoreButtonTapped;

@end

@interface SLCustomNavigationBar : UIView

@property (nonatomic, weak) id<SLCustomNavigationBarDelegate> delegate;
@property (nonatomic, strong) UIButton *moreButton;

@end

NS_ASSUME_NONNULL_END
