//
//  OTCChatCell.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCChatCell.h"
#import "JFKit.h"
#import <Masonry.h>

static CGFloat const QQBubbleInset = 3;

@interface OTCChatCell() <JFAsyncViewDelegate>
@property (nonatomic, strong) JFAsyncView* asynvView;
@property (nonatomic, strong) UIImageView* imgSendError;
@property (nonatomic, strong) UIActivityIndicatorView* vActivity;
@end

@implementation OTCChatCell

- (IBAction) clickedAtImgSendError:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickedResendInchatCell:)]) {
        [self.delegate didClickedResendInchatCell:self];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.asynvView.delegate = self;
        self.contentView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.asynvView];
        [self.contentView addSubview:self.imgSendError];
        [self.contentView addSubview:self.vActivity];
        [self.asynvView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
    return self;
}

- (void)resetViews {
    if (!self.layouts) {
        return;
    }
    UIEdgeInsets resizeInset = UIEdgeInsetsMake(20, 20, 20, 20);
    if (self.layouts.status == OTCMMessageStatusNotSend) {
        [self.vActivity startAnimating];
    }
    else {
        [self.vActivity stopAnimating];
    }
    
    // 气泡
    [UIView performWithoutAnimation:^{
        self.imgSendError.frame = self.layouts.flagFrame;
        self.vActivity.frame = self.layouts.flagFrame;
        self.imgSendError.hidden = self.layouts.status != OTCMMessageStatusSendFail;
    }];
}

# pragma mark - JFAsyncViewDelegate
/**
 点击了文本区;
 */
- (void) asyncView:(JFAsyncView*)asyncView didClickedAtTextLayout:(JFTextLayout*)textLayout withHighlight:(JFTextAttachmentHighlight*)highlight
{
    if (textLayout.tag == OTCMMessageLayoutsTagText) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didClickedContentTextInchatCell:)]) {
            [self.delegate didClickedContentTextInchatCell:self];
        }
    }
}


/**
 长按文本区;
 */
- (void) asyncView:(JFAsyncView*)asyncView didLongpressAtTextLayout:(JFTextLayout*)textLayout withHighlight:(JFTextAttachmentHighlight*)highlight
{
    if (textLayout.tag == OTCMMessageLayoutsTagText) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didLongpressedContentTextInchatCell:)]) {
            [self.delegate didLongpressedContentTextInchatCell:self];
        }
    }
}
- (void)didLongPressAtAsyncView {
    if (self.layouts.message && self.layouts.message.messageBodyType == OTCMMessageBodyTypeText) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didLongpressedContentTextInchatCell:)]) {
            [self.delegate didLongpressedContentTextInchatCell:self];
        }
    }
}


/**
 点击了图片区;
 @param asyncView 当前异步加载视图;
 @param imageLayout 图片布局对象;
 */
- (void) asyncView:(JFAsyncView*)asyncView didClickedAtImageLayout:(JFImageLayout*)imageLayout
{
    if (imageLayout.tag == OTCMMessageLayoutsTagAvatar) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didClickedAvatorInchatCell:)]) {
            [self.delegate didClickedAvatorInchatCell:self];
        }
    }
    else if (imageLayout.tag == OTCMMessageLayoutsTagImage) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didClickedImageInchatCell:)]) {
            [self.delegate didClickedImageInchatCell:self];
        }
    }
}

/// 即将开始绘制
/// @param asyncView  当前异步加载视图
/// @param context  当前即将绘制的上下文
/// @param cancelled  退出绘制的回调；在外部绘制时，要不时判断当前绘制是否结束
- (void) asyncView:(JFAsyncView*)asyncView willDrawInContext:(CGContextRef)context cancelled:(IsCancelled)cancelled {
    // 取昵称文本属性+文本属性|图片属性
    JFTextLayout* txt_nickname = nil;
    JFTextLayout* txt_content = nil;
    JFImageLayout* img_content = nil;
    for (JFTextLayout* layout in self.layouts.layouts) {
        if ([layout isKindOfClass:[JFTextLayout class]] && layout.tag == OTCMMessageLayoutsTagNickName) {
            txt_nickname = layout;
        }
        else if ([layout isKindOfClass:[JFTextLayout class]] && layout.tag == OTCMMessageLayoutsTagText) {
            txt_content = layout;
        }
        else if ([layout isKindOfClass:[JFImageLayout class]] && layout.tag == OTCMMessageLayoutsTagImage) {
            img_content = (JFImageLayout*)layout;
        }
    }

    CGContextSaveGState(context);
    
    // 绘制头像的背景色
    CGFloat cornerRadius = JFScaleWidth6(kOTCCornerRadius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    // 绘制昵称背景色
    CGRect frame = self.layouts.nickNameFrame;
    CGPathAddRoundedRect(path, NULL, frame, JFScaleWidth6(kOTCAvatarWidth * 0.5), JFScaleWidth6(kOTCAvatarWidth * 0.5));
    CGContextAddPath(context, path);
    if (txt_nickname) {
        CGContextSetFillColorWithColor(context, txt_nickname.backgroundColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, [UIColor orangeColor].CGColor);
    }
    CGContextFillPath(context);
    CGPathRelease(path);
    
    // 发送方
    if (self.layouts.isSender) {
        // 绘制文本内容气泡
        if (txt_content) {
            CGFloat startX = CGRectGetMinX(self.layouts.bubbleFrame);
            CGFloat startY = CGRectGetMinY(self.layouts.bubbleFrame) ;
            CGFloat width = CGRectGetWidth(self.layouts.bubbleFrame);
            CGFloat height = CGRectGetHeight(self.layouts.bubbleFrame);
            path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, startX + width, startY);
            CGPathAddLineToPoint(path, NULL, startX + width, startY + height - cornerRadius);
            CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI * 0, M_PI * 0.5, NO);
            CGPathAddLineToPoint(path, NULL, startX + cornerRadius, startY + height);
            CGPathAddArc(path, NULL, startX + cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI * 0.5, M_PI * 1, NO);
            CGPathAddLineToPoint(path, NULL, startX, startY + cornerRadius);
            CGPathAddArc(path, NULL, startX + cornerRadius, startY + cornerRadius, cornerRadius, M_PI * 1, M_PI * 1.5, NO);
            CGPathAddLineToPoint(path, NULL, startX + width, startY);
            CGContextAddPath(context, path);
            CGContextSetFillColorWithColor(context, txt_content.backgroundColor.CGColor);
            CGContextFillPath(context);
            CGPathRelease(path);
        }
    }
    // 接收方
    else {
        // 绘制文本内容气泡
        if (txt_content) {
            CGFloat startX = CGRectGetMinX(self.layouts.bubbleFrame);
            CGFloat startY = CGRectGetMinY(self.layouts.bubbleFrame) ;
            CGFloat width = CGRectGetWidth(self.layouts.bubbleFrame);
            CGFloat height = CGRectGetHeight(self.layouts.bubbleFrame);
            path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, startX, startY);
            CGPathAddLineToPoint(path, NULL, startX + width - cornerRadius, startY);
            CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + cornerRadius, cornerRadius, M_PI * 1.5, M_PI * 2, NO);
            CGPathAddLineToPoint(path, NULL, startX + width, startY + height - cornerRadius);
            CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI * 0, M_PI * 0.5, NO);
            CGPathAddLineToPoint(path, NULL, startX + cornerRadius, startY + height);
            CGPathAddArc(path, NULL, startX + cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI * 0.5, M_PI * 1, NO);
            CGPathAddLineToPoint(path, NULL, startX, startY);
            CGContextAddPath(context, path);
            CGContextSetFillColorWithColor(context, txt_content.backgroundColor.CGColor);
            CGContextFillPath(context);
            CGPathRelease(path);
        }
    }
    
    CGContextRestoreGState(context);
}


# pragma mark - getter

- (JFAsyncView *)asynvView {
    if (!_asynvView) {
        _asynvView = [JFAsyncView new];
        _asynvView.delegate = self;
    }
    return _asynvView;
}
- (UIImageView *)imgSendError {
    if (!_imgSendError) {
        _imgSendError = [UIImageView new];
        _imgSendError.contentMode = UIViewContentModeScaleAspectFit;
        _imgSendError.image = JFImageNamed(@"tishi");
        _imgSendError.userInteractionEnabled = YES;
        UITapGestureRecognizer* tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedAtImgSendError:)];
        [_imgSendError addGestureRecognizer:tapGes];
    }
    return _imgSendError;
}
- (UIActivityIndicatorView *)vActivity {
    if (!_vActivity) {
        _vActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _vActivity.hidesWhenStopped = YES;
    }
    return _vActivity;
}

# pragma mark - setter
- (void)setLayouts:(OTCM_messageLayouts *)layouts {
    _layouts = layouts;
    self.asynvView.layouts = layouts;
    self.asynvView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
    [self resetViews];
}


@end
