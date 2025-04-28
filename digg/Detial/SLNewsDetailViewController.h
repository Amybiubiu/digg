//
//  SLNewsDetailViewController.h
//  digg
//
//  Created by Tim Bao on 2023/5/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLNewsDetailViewController : UIViewController

@property (nonatomic, strong) NSString *newsURL;
@property (nonatomic, strong) NSString *newsTitle;

@end

NS_ASSUME_NONNULL_END