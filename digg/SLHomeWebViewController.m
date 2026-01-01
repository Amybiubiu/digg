//
//  SLHomeWebViewController.m
//  digg
//
//  Created by hey on 2024/11/24.
//

#import "SLHomeWebViewController.h"

@interface SLHomeWebViewController ()

@end

@implementation SLHomeWebViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        // Tab 中的常驻页面不应该复用 WebView
        self.shouldReuseWebView = NO;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Tab 中的常驻页面不应该复用 WebView
        self.shouldReuseWebView = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIView *)listView{
    return self.view;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
