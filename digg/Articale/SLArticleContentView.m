//
//  SLArticleContentView.m
//  digg
//
//  Created by Tim Bao on 2025/3/15.
//

#import "SLArticleContentView.h"
#import "Masonry.h"
#import "SLColorManager.h"
#import "SLGeneralMacro.h"
#import "digg-Swift.h"
#import <SDWebImage/SDWebImage.h>

@interface SLArticleContentView () <RZRichTextViewDelegate>

@property (nonatomic, strong) RZRichTextView *richTextView;
@property (nonatomic, assign) CGFloat contentHeight;

@end

@implementation SLArticleContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 8;
    
    // 富文本视图
    self.richTextView = [[RZRichTextView alloc] initWithFrame:CGRectZero viewModel:[RZRichTextViewModel sharedWithEdit:NO]];
    self.richTextView.delegate = self;
    self.richTextView.editable = NO;
    self.richTextView.scrollEnabled = NO;
    self.richTextView.backgroundColor = [UIColor clearColor];
    self.richTextView.font = [UIFont pingFangRegularWithSize:16];
    self.richTextView.textColor = Color16(0x313131);
    [self addSubview:self.richTextView];
    
    // 设置约束
    CGFloat margin = 10.0;
    
    [self.richTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self).offset(margin);
        make.right.equalTo(self).offset(-margin);
        make.height.mas_equalTo(0);
        make.bottom.equalTo(self);
    }];
}

- (void)setupWithRichContent:(NSString *)richContent {    
    [self.richTextView html2AttributedstringWithHtml:richContent];
    [self.richTextView hidePlaceHolder];
    
//    [self.richTextView layoutIfNeeded];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRichTextViewHeight];
    });
}

- (void)richTextViewDidInsertAttachment:(RZRichTextView *)textView {
    [self updateRichTextViewHeight];
}

- (void)updateRichTextViewHeight {
    CGSize contentSize = [self.richTextView sizeThatFits:CGSizeMake(self.richTextView.frame.size.width, MAXFLOAT)];
    self.contentHeight = contentSize.height;
    [self.richTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.contentHeight);
    }];

    // 通知高度变化
    if (self.heightChangedHandler) {
        self.heightChangedHandler(self.contentHeight);
    }
}

- (CGFloat)getContentHeight {
    return self.contentHeight;
}

@end
