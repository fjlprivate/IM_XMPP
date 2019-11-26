//
//  OTCChatToolBar.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCChatToolBar.h"
#import "JFKit.h"
#import <Masonry.h>

@implementation OTCChatToolBar

+ (CGFloat) toolBarHeight {
    return 70;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.txtInput];
        [self addSubview:self.btnMore];
        [self addSubview:self.separator];

        [self.separator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.mas_equalTo(0);
            make.height.mas_equalTo(0.5);
        }];
        [self.btnMore mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(15);
            make.bottom.mas_equalTo(-15);
            make.right.mas_equalTo(-18);
            make.width.equalTo(self.btnMore.mas_height);
        }];
        self.btnMore.layer.cornerRadius = ([OTCChatToolBar toolBarHeight] - 15 * 2) * 0.5;
        [self.txtInput mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(18);
            make.top.mas_equalTo(15);
            make.bottom.mas_equalTo(-15);
            make.right.equalTo(self.btnMore.mas_left).offset(-18);
        }];
        self.txtInput.layer.masksToBounds = YES;
        self.txtInput.layer.cornerRadius = ([OTCChatToolBar toolBarHeight] - 15 * 2) * 0.5;
    
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat radius = rect.size.height * 18.f/70.f;
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, JFRGBAColor(0xf5f5f5, 1).CGColor);
    CGContextFillRect(context, rect);
    
    CGMutablePathRef path = CGPathCreateMutable();
    // 绘制形状
    CGPathMoveToPoint(path, NULL, 0, height);
    CGPathAddLineToPoint(path, NULL, 0, radius);
    CGPathAddArc(path, NULL, radius, radius, radius, M_PI, M_PI * 1.5, NO);
    CGPathAddLineToPoint(path, NULL, width - radius, 0);
    CGPathAddArc(path, NULL, width - radius, radius, radius, M_PI * 1.5, M_PI * 2, NO);
    CGPathAddLineToPoint(path, NULL, width, height);
    CGPathAddLineToPoint(path, NULL, 0, height);
    // 添加path
    CGContextAddPath(context, path);
    
    // 设置背景色
    CGContextSetFillColorWithColor(context, JFColorWhite.CGColor);
    // 填充path
    CGContextFillPath(context);
    
    CGPathRelease(path);}

# pragma mark - getter
- (UIButton *)btnPhoto {
    if (!_btnPhoto) {
        _btnPhoto = [UIButton new];
        [_btnPhoto setImage:JFImageNamed(@"ic_chat_uppic") forState:UIControlStateNormal];
    }
    return _btnPhoto;
}
- (UITextField *)txtInput {
    if (!_txtInput) {
        _txtInput = [UITextField new];
        _txtInput.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        UIView* whiteSpace = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 10)];
        _txtInput.leftView = whiteSpace;
        _txtInput.leftViewMode = UITextFieldViewModeAlways;
        _txtInput.returnKeyType = UIReturnKeySend;
    }
    return _txtInput;
}
- (UIButton *)btnMore {
    if (!_btnMore) {
        _btnMore = [UIButton new];
        _btnMore.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        [_btnMore setImage:JFImageNamed(@"icon_chat_toolBar_more") forState:UIControlStateNormal];
    }
    return _btnMore;
}
- (UIView *)separator {
    if (!_separator) {
        _separator = [UIView new];
        _separator.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
    }
    return _separator;
}

@end
