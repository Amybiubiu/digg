//
//  CaocaoRefreshFooter.m
//  UXRefreshDemo
//
//  Created by byn on 2017/11/24.
//  Copyright © 2017年 uxing. All rights reserved.
//

#import "CaocaoRefreshFooter.h"
#import "CaocaoRefreshCircleView.h"
@interface CaocaoRefreshFooter()

@property (nonatomic, strong) CaocaoRefreshCircleView *circleView;
@property (nonatomic, strong) UILabel *noMoreDataLabel;

@end

@implementation CaocaoRefreshFooter

- (UILabel *)noMoreDataLabel {
    if (!_noMoreDataLabel) {
        _noMoreDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 17)];
        _noMoreDataLabel.textColor = [UIColor colorWithRed:155.0 / 255 green:155.0 / 255 blue:165.0 / 255 alpha:1];
        _noMoreDataLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _noMoreDataLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _noMoreDataLabel;
}

- (CaocaoRefreshCircleView *)circleView {
    if (!_circleView) {
        _circleView = [[CaocaoRefreshCircleView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    }
    return _circleView;
}

- (void)prepare {
    [super prepare];
    [self addSubview:self.circleView];
    [self addSubview:self.noMoreDataLabel];
    self.automaticallyRefresh = NO;
}


- (void)placeSubviews {
    [super placeSubviews];
    self.circleView.center = CGPointMake([[UIScreen mainScreen] bounds].size.width / 2, self.frame.size.height / 2);
    self.noMoreDataLabel.center = CGPointMake([[UIScreen mainScreen] bounds].size.width / 2, self.frame.size.height / 2);
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState
    switch (state) {
        case MJRefreshStateIdle:
        {
            self.noMoreDataLabel.hidden = NO;
            self.circleView.hidden = !self.noMoreDataLabel.hidden;
            [self.circleView stopRefreshingAnimation];
            self.noMoreDataLabel.text = @"上拉加载更多";
        }
            break;
        case MJRefreshStatePulling:
            break;
        case MJRefreshStateRefreshing:
        {
            self.noMoreDataLabel.hidden = YES;
            self.circleView.hidden = !self.noMoreDataLabel.hidden;
            [self.circleView startRefreshingAnimation];
            self.noMoreDataLabel.text = @"";
        }
            break;
        case MJRefreshStateNoMoreData:
        {
            self.noMoreDataLabel.hidden = NO;
            self.circleView.hidden = !self.noMoreDataLabel.hidden;
            [self.circleView stopRefreshingAnimation];
            self.noMoreDataLabel.text = self.text;
        }
            break;
        case MJRefreshStateWillRefresh:
            break;
        default:
            break;
    }
}

#pragma mark 监听拖拽比例（控件被拖出来的比例）
- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];
    if (pullingPercent >= 1.0) {
        [self.circleView setCicleRun:1.0];
    } else {
        [self.circleView setCicleRun:pullingPercent];
    }
}


@end
