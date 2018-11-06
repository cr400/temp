//
//  LSCustomDescView.m
//  LiveShow
//
//  Created by admin on 16/12/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "LSCustomDescView.h"

@interface LSCustomDescView ()
@property (nonatomic, strong) YYLabel                       *descLab;/**<内容*/
@property (nonatomic, strong) UIButton                      *lookAllBtn;/**<查看全部 收起*/
@property (nonatomic, strong) YYTextHighlight               *textHighlight;
@property (nonatomic, assign) BOOL                          externFlag;/**<是否展开*/
@property (nonatomic, assign) NSInteger                     minLine;
@property(nonatomic, assign) BOOL                           otherLine;

@end

@implementation LSCustomDescView

-(CGFloat)marginX{
    if (_marginX < 0) {
        _marginX = 16;
    }
    return _marginX;
}

-(YYLabel *)descLab{
    if (!_descLab) {
        _descLab = [YYLabel new];
        _descLab.font = DECLARE_SYSTEMFont(16);
        _descLab.textColor = UIColorHex(#333333);
        _descLab.userInteractionEnabled = YES;
        _descLab.textVerticalAlignment = YYTextVerticalAlignmentTop;//YYTextVerticalAlignmentCenter
        _descLab.preferredMaxLayoutWidth = DEVICE_WIDTH - 32;
    }
    return _descLab;
}

-(UIButton *)lookAllBtn{
    if (!_lookAllBtn) {
        _lookAllBtn = [UIButton new];
        _lookAllBtn.titleLabel.font = DECLARE_SYSTEMFont(16);
        [_lookAllBtn setTitleColor:LSHexRGB(0x6699cc) forState:UIControlStateNormal];
        [_lookAllBtn setTitle:@"收起" forState:UIControlStateSelected];
        
        [_lookAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -10)];
    }
    return _lookAllBtn;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorWhite;
        [self addSubview:self.descLab];
        [self addSubview:self.lookAllBtn];
        
        @weakify(self);
        [[self.lookAllBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            @strongify(self);
            self.otherLine = NO;
            self.lookAllBtn.selected = !self.lookAllBtn.selected;
            if (self.lookAllCallback) {
                self.lookAllCallback(self.lookAllBtn.selected);
            }
            
        }];
        
        self.textHighlight = [YYTextHighlight new];
        self.textHighlight.tapAction = ^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect){
            @strongify(self);
            self.lookAllBtn.selected = !self.lookAllBtn.selected;
            if (self.lookAllCallback) {
                self.lookAllCallback(self.lookAllBtn.selected);
            }
        };
        
        [self installConstraints];
        self.userInteractionEnabled = YES;
    }
    return self;
}

-(CGSize)sizeThatFits:(CGSize)size{
    [super sizeThatFits:size];
    
    CGFloat totalHeight = 0;
    CGSize maxSize = CGSizeMake(DEVICE_WIDTH - (2 * self.marginX), CGFLOAT_MAX);
    
    self.descLab.numberOfLines = self.minLine;
    if (self.externFlag) {
        self.descLab.numberOfLines = 0;
    }
    totalHeight += [self.descLab sizeThatFits:maxSize].height;
    totalHeight += self.marginBottom;
    if (self.otherLine) {
        totalHeight += 16;
        
    }
    
    NSLog(@"#SUN layoutSize.height totalHeight %.f", totalHeight);
    
//    CGSize resultSize = CGSizeMake(size.width, 0);
    CGFloat resultHeight = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    NSLog(@"#SUN layoutSize.height desc %.f", resultHeight);
    
    return CGSizeMake(size.width, totalHeight);
}

- (void)installConstraints{
    [self.descLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.bottom.mas_lessThanOrEqualTo(0);
        
    }];
    
}

- (NSAttributedString *)configTruncationToken:(NSString *)truncationStr subStr:(NSString *)subStr font:(UIFont *)font color:(UIColor *)color textHighlight:(YYTextHighlight *)textHighlight{
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:truncationStr];
    text.yy_font = font;
    
    [text yy_setColor:color range:[text.string rangeOfString:subStr]];
    [text yy_setTextHighlight:textHighlight range:[text.string rangeOfString:subStr]];
    
    YYLabel *seeMore = [YYLabel new];
    seeMore.attributedText = text;
    [seeMore sizeToFit];
    
    NSAttributedString *truncationToken = [NSAttributedString yy_attachmentStringWithContent:seeMore contentMode:UIViewContentModeScaleAspectFit attachmentSize:seeMore.frame.size alignToFont:text.yy_font alignment:YYTextVerticalAlignmentCenter];
    return truncationToken;
}

- (void)updateWithDesc:(NSString *)desc minLine:(NSInteger)minLine extern:(BOOL)externFlag{
    if (!desc) {
        return;
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 6;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:desc attributes:@{NSFontAttributeName: DECLARE_SYSTEMFont(16), NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName: UIColorHex(#333333)}];
    self.descLab.attributedText = text;
    
        //更多按钮 逻辑
    [self.descLab sizeToFit];
    CGSize maxSize = CGSizeMake(kLSScreenWidth - 32, CGFLOAT_MAX);
    self.descLab.numberOfLines = 0;
    self.descLab.lineBreakMode = NSLineBreakByTruncatingTail;
    
    CGFloat h = ceilf([self.descLab sizeThatFits:maxSize].height);
    
    NSInteger numberOfLines = round(ceilf([self.descLab sizeThatFits:maxSize].height)/self.descLab.font.lineHeight);
        //加上 " 收起"
    NSMutableAttributedString *upText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ 收起", desc] attributes:@{NSFontAttributeName: DECLARE_SYSTEMFont(16), NSParagraphStyleAttributeName: style}];
    self.descLab.attributedText = upText;
    [self.descLab sizeToFit];
    
    CGFloat tempH = ceilf([self.descLab sizeThatFits:maxSize].height);
    NSLog(@"extern -------temp %f", [self.descLab sizeThatFits:maxSize].height);
    
    NSInteger nextNumberOfLines = round(ceilf([self.descLab sizeThatFits:maxSize].height)/self.descLab.font.lineHeight);
    self.descLab.attributedText = text;
    if (tempH - h >= floor(self.descLab.font.lineHeight)) {
        nextNumberOfLines = numberOfLines +1;
        
    }
    else{
        nextNumberOfLines = numberOfLines;
    }
    
        //全部展开 隐藏查看全部按钮
    if (numberOfLines <= minLine) {
        self.lookAllBtn.hidden = YES;
        
    }else{
            ////一开始展开部分3行
            //点击了查看全部 全展开
        if (externFlag) {
            self.descLab.numberOfLines = 0;
            self.lookAllBtn.hidden = NO;
                //同一行
            if (nextNumberOfLines == numberOfLines) {
                self.otherLine = NO;
                [self.lookAllBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(self.descLab).mas_offset(-16);
                    make.width.height.mas_equalTo(44);
                    make.lastBaseline.mas_equalTo(self.descLab).mas_offset(-6);
                }];
            }
                //另起一行
            else{
                self.otherLine = YES;
                [self.lookAllBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(self.descLab).mas_offset(-16);
                    make.width.height.mas_equalTo(44);
                    make.lastBaseline.mas_equalTo(self.descLab).mas_offset(16);
                    
                }];
            }
        }
            //部分展开
        else{
            self.descLab.numberOfLines = 3;
            self.descLab.truncationToken = [self configTruncationToken:@"... 更多" subStr:@"更多" font:DECLARE_SYSTEMFont(16) color:LSHexRGB(0x6699CC) textHighlight:self.textHighlight];
        }
    }
    
//    [self.descLab sizeToFit];
    CGFloat height = [self.descLab sizeThatFits:maxSize].height;
    [self.descLab mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height + 3);
    }];
    
    self.externFlag = externFlag;
    self.minLine = minLine;
}
@end
