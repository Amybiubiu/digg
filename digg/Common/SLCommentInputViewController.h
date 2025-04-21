//
//  SLCommentInputViewController.h
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SLCommentSubmitHandler)(NSString *comment);

@interface SLCommentInputViewController : UIViewController

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) SLCommentSubmitHandler submitHandler;
@property (nonatomic, copy) SLCommentSubmitHandler cancelHandler;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;

- (void)showInViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
