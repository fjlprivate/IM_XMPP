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
        [self.asynvView addSubview:self.bubbleImageView];
        [self.asynvView sendSubviewToBack:self.bubbleImageView];
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
        // 发送方
        if (self.layouts.isSender) {
            self.bubbleImageView.image = [[UIImage imageNamed:@"paopao_blue"] resizableImageWithCapInsets:resizeInset resizingMode:UIImageResizingModeStretch];
        }
        // 接收方
        else {
            self.bubbleImageView.image = [[UIImage imageNamed:@"paopao_bai"] resizableImageWithCapInsets:resizeInset resizingMode:UIImageResizingModeStretch];
        }
        self.bubbleImageView.hidden = self.layouts.bubbleHidden;
        self.bubbleImageView.frame = CGRectInset(self.layouts.bubbleFrame, -JFScaleWidth6(QQBubbleInset), -JFScaleWidth6(QQBubbleInset));
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



# pragma mark - getter
- (UIImageView *)bubbleImageView {
    if (!_bubbleImageView) {
        _bubbleImageView = [UIImageView new];
    }
    return _bubbleImageView;
}

- (JFAsyncView *)asynvView {
    if (!_asynvView) {
        _asynvView = [JFAsyncView new];
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
