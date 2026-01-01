//
//  SLHomeTagView.h
//  digg
//
//  Created by hey on 2024/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHomeTagView : UIView

@property (nonatomic, strong) UILabel *tagLabel;

- (void)updateWithLabel:(NSString *)label;

@end

NS_ASSUME_NONNULL_END
