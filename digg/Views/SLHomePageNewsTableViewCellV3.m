//
//  SLHomePageNewsTableViewCellV3.m
//  digg
//
//  Created by Tim Bao on 2025/4/14.
//

#import "SLHomePageNewsTableViewCellV3.h"
#import <Masonry/Masonry.h>
#import "SLGeneralMacro.h"
#import "SLHomeTagViewV2.h"
#import "SLColorManager.h"
#import "SLInteractionBar.h"
#import "SDWebImage/SDWebImage.h"

@interface SLHomePageNewsTableViewCellV3 () <SLInteractionBarDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
// 新增时间Label
@property (nonatomic, strong) UILabel *timeLabel; 
@property (nonatomic, strong) SLInteractionBar *interactionBar;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) SLHomeTagViewV2 *tagView;
@property (nonatomic, strong) SLArticleTodayEntity *entity;
@property (nonatomic, strong) UIImageView* smallImageView;
@property (nonatomic, strong) UIImageView* bigImageView;

@end

@implementation SLHomePageNewsTableViewCellV3

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self){
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [SLColorManager primaryBackgroundColor];
        self.contentView.backgroundColor = [SLColorManager primaryBackgroundColor];
        [self createViews];
    }
    return self;
}

- (void)updateWithEntity:(SLArticleTodayEntity *)entiy {
    self.entity = entiy;
    self.smallImageView.hidden = YES;
    self.bigImageView.hidden = YES;
    self.contentLabel.hidden = YES;

    self.titleLabel.text = entiy.title;
    self.contentLabel.text = nil;
    self.contentLabel.attributedText = nil;
    self.contentLabel.numberOfLines = 2;

    CGFloat lineSpacing = 4;
    CGFloat hPadding = 16; // 水平间距
    
    // --- 1. 处理标签和时间行的显示逻辑 ---
    // 只有在 pageStyle == 1 (为你) 且 label 不为空时显示
    BOOL showHeaderTag = (self.pageStyle == 1 && !stringIsEmpty(entiy.label));

    // NSLog(@"调试标签: Title: %@, PageStyle: %ld, Label: %@", entiy.title, (long)self.pageStyle, entiy.label);

    
    MASViewAttribute *topAnchorAttribute;
    CGFloat topPadding;
    
    if (showHeaderTag) {
        self.tagView.hidden = NO;
        self.timeLabel.hidden = NO;
        
        [self.tagView updateWithLabel:entiy.label];
        
        // ====== 修复代码开始 ======
        // 将时间戳 (double) 转换为 字符串 (NSString)
        NSTimeInterval timestamp = entiy.gmtCreate;
        // 如果时间戳是毫秒级(13位)，需要除以1000；如果是秒级(10位)，直接使用。
        // 这里做一个简单判断：现在的秒级时间戳大约是 17亿 (10位)，毫秒是 17000亿 (13位)
        if (timestamp > 100000000000.0) {
            timestamp = timestamp / 1000.0;
        }
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        
        // 建议使用静态 formatter 提升列表滑动性能
        static NSDateFormatter *dateFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            // 格式化样式，例如 "2025-04-14" 或 "MM-dd HH:mm"
            [dateFormatter setDateFormat:@"yyyy-MM-dd"]; 
        });
        
        self.timeLabel.text = [dateFormatter stringFromDate:date];
        // ====== 修复代码结束 ======
        
        // 更新 Tag 布局：单独一行，顶部对齐 content
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(hPadding);
            make.top.equalTo(self.contentView).offset(hPadding);
            make.height.equalTo(@20);
        }];
        
        // 更新 Time 布局：在 Tag 右侧，垂直居中
        [self.timeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tagView.mas_right).offset(8);
            make.centerY.equalTo(self.tagView);
            make.right.lessThanOrEqualTo(self.contentView).offset(-hPadding);
        }];
        
        // 下方内容的锚点为 TagView 的底部，间距设为 12
        topAnchorAttribute = self.tagView.mas_bottom;
        topPadding = 12;
        
    } else {
        self.tagView.hidden = YES;
        self.timeLabel.hidden = YES;
        
        // 下方内容的锚点为 ContentView 的顶部，间距设为 16
        topAnchorAttribute = self.contentView.mas_top;
        topPadding = 16;
    }
    
    // --- 2. 处理图片和标题布局 ---
    
    if (entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
        // === 小图模式 (右图左文) ===
        self.contentLabel.numberOfLines = 2;
        [self.smallImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
        [self.bigImageView setHidden:YES];
        [self.smallImageView setHidden:NO];
        
        // 图片顶部约束
        [self.smallImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(topAnchorAttribute).offset(topPadding);
            make.right.equalTo(self.contentView).offset(-hPadding);
            make.size.mas_equalTo(CGSizeMake(79, 64));
        }];
        
        // 标题顶部约束 (与图片顶部对齐)
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(hPadding);
            make.right.equalTo(self.smallImageView.mas_left).offset(-hPadding);
            make.top.equalTo(self.smallImageView); 
        }];
        
    } else if (entiy.picSize == 1 && entiy.mainPicUrl.length > 0) {
        // === 大图模式 (上图下文) ===
        self.contentLabel.numberOfLines = 2;
        [self.bigImageView sd_setImageWithURL:[NSURL URLWithString:entiy.mainPicUrl]];
        [self.smallImageView setHidden:YES];
        [self.bigImageView setHidden:NO];
        
        // 大图顶部约束
        [self.bigImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(topAnchorAttribute).offset(topPadding);
            make.left.equalTo(self.contentView).offset(hPadding);
            make.right.equalTo(self.contentView).offset(-hPadding);
            make.height.mas_equalTo(167);
        }];
        
        // 标题位于大图下方
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(hPadding);
            make.top.equalTo(self.bigImageView.mas_bottom).offset(12); // 图片和标题间距
            make.right.equalTo(self.contentView).offset(-hPadding);
        }];
        
    } else {
        // === 无图模式 ===
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(hPadding);
            make.top.equalTo(topAnchorAttribute).offset(topPadding);
            make.right.equalTo(self.contentView).offset(-hPadding);
        }];
    }

    // --- 3. 处理正文内容 ---
    
    BOOL hasContent = entiy.content != nil && entiy.content.length > 0;
    if (hasContent) {
        self.contentLabel.hidden = NO;
        
        NSString *cleanedContent = [entiy.content stringByReplacingOccurrencesOfString:@"\\U0000fffc\\n\\n" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, entiy.content.length)];
        NSString *contentStr = [cleanedContent stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        // 特殊修正：如果是小图且没内容，强制换行占位
        if (contentStr.length == 0 && entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
            contentStr = @"\n";
        }
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = lineSpacing;
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[UIFont systemFontOfSize:14 weight:UIFontWeightLight] forKey:NSFontAttributeName];
        [attributes setObject:[SLColorManager cellContentColor] forKey:NSForegroundColorAttributeName];
        [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
        self.contentLabel.attributedText = [[NSAttributedString alloc] initWithString:contentStr attributes:attributes];

        [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(hPadding);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(CELL_CONTENT_V_SPACE);
            make.right.equalTo(self.titleLabel);
        }];
        
        // InteractionBar 布局
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.left.equalTo(self.contentView).offset(hPadding);
            make.bottom.equalTo(self.contentView);
            
            if (entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
                // 小图模式：宽度占满，Top 取 内容底部 或 图片底部 的最大值
                make.right.equalTo(self.contentView).offset(-hPadding);
                make.top.greaterThanOrEqualTo(self.contentLabel.mas_bottom);
                make.top.greaterThanOrEqualTo(self.smallImageView.mas_bottom);
            } else {
                // 其他模式
                make.top.equalTo(self.contentLabel.mas_bottom);
                make.right.equalTo(self.titleLabel);
            }
        }];
    } else {
        // 无内容逻辑
        if (entiy.picSize == 0 && entiy.mainPicUrl.length > 0) {
            self.contentLabel.text = @"\n";
            self.contentLabel.hidden = NO;
            [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView).offset(hPadding);
                make.top.equalTo(self.titleLabel.mas_bottom).offset(CELL_CONTENT_V_SPACE);
                make.right.equalTo(self.titleLabel);
            }];
        } else {
            self.contentLabel.hidden = YES;
            [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@0);
                make.top.equalTo(self.titleLabel.mas_bottom);
                make.left.equalTo(self.titleLabel);
            }];
        }
        
        [self.interactionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(hasContent ? 0 : 8);
            make.left.equalTo(self.contentView).offset(hPadding);
            make.right.equalTo(self.contentView).offset(-hPadding);
            make.bottom.equalTo(self.contentView);
        }];
    }
    
    // 更新交互数据
    [self.interactionBar updateNumber:entiy.likeCnt forType:SLInteractionTypeLike];
    [self.interactionBar updateNumber:entiy.dislikeCnt forType:SLInteractionTypeDislike];
    [self.interactionBar updateNumber:entiy.commentsCnt forType:SLInteractionTypeComment];
    [self.interactionBar setSelected:entiy.liked forType:SLInteractionTypeLike];
    [self.interactionBar setSelected:entiy.disliked forType:SLInteractionTypeDislike];
    [self.interactionBar showItemForType:SLInteractionTypeCustom];
}

- (void)createViews{
    [self.contentView addSubview:self.smallImageView];
    [self.contentView addSubview:self.bigImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.interactionBar];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.tagView];
    // 添加 TimeLabel
    [self.contentView addSubview:self.timeLabel];
    
    // 初始化约束，具体位置在 updateWithEntity 中根据数据重设
    CGFloat offset = 16;
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.top.equalTo(self.contentView).offset(offset);
        make.height.equalTo(@20);
    }];
    
    [self.tagView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                            forAxis:UILayoutConstraintAxisHorizontal];

    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(offset);
        make.right.equalTo(self.contentView).offset(-offset);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
}

// ... (tagClick 和 SLInteractionBarDelegate 方法保持不变) ...

- (void)tagClick {
    if (self.labelClick) {
        self.labelClick(self.entity);
    }
}

#pragma mark - SLInteractionBarDelegate

- (void)interactionBar:(SLInteractionBar *)interactionBar didTapItemWithType:(SLInteractionType)type selected:(BOOL)selected {
    switch (type) {
        case SLInteractionTypeLike:
            if (selected) {
                if (self.likeClick) {
                    self.likeClick(self.entity);
                }
                [interactionBar updateNumber:self.entity.likeCnt + 1 forType:SLInteractionTypeLike];
                [interactionBar updateNumber:self.entity.dislikeCnt forType:SLInteractionTypeDislike];
                [interactionBar setSelected:NO forType:SLInteractionTypeDislike];
            } else {
                if (self.cancelLikeClick) {
                    self.cancelLikeClick(self.entity);
                }
                [interactionBar updateNumber:self.entity.likeCnt forType:SLInteractionTypeLike];
            }
            break;
        case SLInteractionTypeDislike:
            if (selected) {
                if (self.dislikeClick) {
                    self.dislikeClick(self.entity);
                }
                
                [interactionBar updateNumber:self.entity.likeCnt forType:SLInteractionTypeLike];
                [interactionBar updateNumber:self.entity.dislikeCnt + 1 forType:SLInteractionTypeDislike];
                [interactionBar setSelected:NO forType:SLInteractionTypeLike];
            } else {
                if (self.cancelDisLikeClick) {
                    self.cancelDisLikeClick(self.entity);
                }
                
                [interactionBar updateNumber:self.entity.dislikeCnt forType:SLInteractionTypeDislike];
            }
            break;
        case SLInteractionTypeComment:
            if (self.showDetailClick) {
                self.showDetailClick(self.entity);
            }
            break;
        case SLInteractionTypeCustom:
            if (self.checkDetailClick) {
                self.checkDetailClick(self.entity);
            }
            break;
        default:
            break;
    }
}


#pragma mark - Property

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _timeLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]; // 浅灰色
        _timeLabel.hidden = YES;
    }
    return _timeLabel;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [SLColorManager cellTitleColor];
        // 移除 lineBreakMode 显式设置，默认为 TruncatingTail，防止某些情况显示不全
    }
    return _titleLabel;
}

// ... (其他 Getter 方法保持不变) ...
- (UILabel *)contentLabel {
    if(!_contentLabel){
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightLight];
        _contentLabel.numberOfLines = 2;
        _contentLabel.textColor = [SLColorManager cellContentColor];
    }
    return _contentLabel;
}

- (SLInteractionBar *)interactionBar {
    if (!_interactionBar) {
        _interactionBar = [[SLInteractionBar alloc] initWithFrame:CGRectZero
                                            interactionTypes:@[
                                                @(SLInteractionTypeLike),
                                                @(SLInteractionTypeComment),
                                                @(SLInteractionTypeCustom),
                                                @(SLInteractionTypeDislike)
                                            ]];
        _interactionBar.delegate = self;
    }
    return _interactionBar;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [SLColorManager cellDivideLineColor];
    }
    return _lineView;
}

- (SLHomeTagViewV2 *)tagView {
    if (!_tagView) {
        _tagView = [[SLHomeTagViewV2 alloc] init];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagClick)];
        [_tagView addGestureRecognizer:tap];
    }
    return _tagView;
}

- (UIImageView *)smallImageView {
    if (!_smallImageView) {
        _smallImageView = [[UIImageView alloc] init];
        _smallImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_smallImageView setHidden:YES];
        _smallImageView.layer.masksToBounds = YES;
        _smallImageView.layer.cornerRadius = 4;
    }
    return _smallImageView;
}

- (UIImageView *)bigImageView {
    if (!_bigImageView) {
        _bigImageView = [[UIImageView alloc] init];
        _bigImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_bigImageView setHidden:YES];
        _bigImageView.layer.masksToBounds = YES;
        _bigImageView.layer.cornerRadius = 4;
    }
    return _bigImageView;
}

@end