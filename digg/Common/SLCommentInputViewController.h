//
//  SLCommentInputViewController.h
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SLCommentSubmitHandler)(NSString *comment);
typedef void(^SLCommentCancelHandler)(void);

@interface SLCommentInputViewController : UIViewController

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) SLCommentSubmitHandler submitHandler;
@property (nonatomic, copy) SLCommentCancelHandler cancelHandler;

- (void)showInViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
