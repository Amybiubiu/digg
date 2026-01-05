//
//  SLRecordViewController.h
//  digg
//
//  Created by Tim Bao on 2025/1/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRecordViewController : UIViewController

@property (nonatomic, assign) BOOL isEdit;
@property (nonatomic, strong) NSString* articleId;
@property (nonatomic, strong) NSString* titleText;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* content;
@property (nonatomic, strong) NSArray* imageUrls;
@property (nonatomic, strong) NSArray* labels;

@end

NS_ASSUME_NONNULL_END
