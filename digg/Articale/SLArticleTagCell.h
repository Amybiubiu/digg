//
//  SLArticleTagCell.h
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLArticleTagCell : UITableViewCell

@property (nonatomic, copy) void (^tagSelectedHandler)(NSString *tag);

- (void)updateWithTags:(NSArray<NSString *> *)tags;

@end

NS_ASSUME_NONNULL_END