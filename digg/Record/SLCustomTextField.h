//
//  SLCustomTextField.h
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLCustomTextField : UITextField <UITextFieldDelegate>

/**
 *  自定义初始化方法
 *
 *  @param frame       frame
 *  @param placeholder 提示语
 *  @param clear       是否显示清空按钮 YES为显示
 *  @param view        是否设置leftView不设置传nil
 *  @param font        设置字号
 *
 *  @return self
 */
- (instancetype)initWithFrame:(CGRect)frame placeholder:(NSString *)placeholder clear:(BOOL)clear leftView:(_Nullable id)view fontSize:(CGFloat)font;

@property (nonatomic, assign) CGRect customFrame;

@property (nonatomic, copy) void(^updateFrame)(CGFloat height);

- (void)textChangedHeight:(NSString *)text;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
