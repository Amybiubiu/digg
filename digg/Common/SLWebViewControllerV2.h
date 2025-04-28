//
//  SLWebViewControllerV2.h
//  digg
//
//  Created by hey on 2024/10/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLWebViewControllerV2 : UIViewController

@property (nonatomic, copy) NSString *uxTitle;
@property (nonatomic, assign) BOOL isLoginPage;
@property (nonatomic, copy) void(^loginSucessCallback) ();

- (void)startLoadRequestWithUrl:(NSString *)url;

- (void)reload;

@end

NS_ASSUME_NONNULL_END
