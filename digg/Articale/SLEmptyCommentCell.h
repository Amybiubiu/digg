//
//  SLEmptyCommentCell.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLEmptyCommentCell : UITableViewCell

@property (nonatomic, copy) void (^commentButtonTapHandler)(void);

@end

NS_ASSUME_NONNULL_END