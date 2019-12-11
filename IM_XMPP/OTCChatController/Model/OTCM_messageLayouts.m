//
//  OTCM_messageLayouts.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCM_messageLayouts.h"
#import "JFKit.h"
#import "OTCM_messageBodyText.h"
#import "OTCM_messageBodyImage.h"
#import "APNetworkClient.h"
#import "UIColor+Add.h"


@implementation OTCM_messageLayouts

+ (instancetype) layoutWithMessage:(OTCM_message*)message {
    return [[OTCM_messageLayouts alloc] initWithMessage:message];
}

- (instancetype)initWithMessage:(OTCM_message*)message {
    self = [super init];
    if (self) {
        if (message) {
            // 是否发送方
            self.message = message;
            self.isSender = message.sendReceive == OTCMMessageSCSend;
            self.status = message.status;
            // 正文字体
            CGFloat contentTextFontSize = 14;
            // 内容与气泡的间距
            UIEdgeInsets contentBubbleInsets = UIEdgeInsetsMake(JFScaleWidth6(kOTCTextInsetsV),
                                                                JFScaleWidth6(kOTCTextInsetsH),
                                                                JFScaleWidth6(kOTCTextInsetsV),
                                                                JFScaleWidth6(kOTCTextInsetsH));
            // 文本与内容的边距
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(1, 2, 1, 2);
            // 气泡离边界的距离
            CGFloat bubbleGap = JFScaleWidth6(56);
            // 头像宽度
            CGFloat avatarWidth = JFScaleWidth6(kOTCAvatarWidth);
            // 图片|视频的最大显示高度
            CGFloat mediaMaxHeight = JFScaleWidth6(160);
            // 图片|视频|位置图片的圆角
            CGSize imgCornerSize = CGSizeMake(JFScaleWidth6(kOTCCornerRadius), JFScaleWidth6(kOTCCornerRadius));
            // 底部
            CGFloat bottom = 0;
            
            // 气泡背景色:发送
            UIColor* bubbleBgColorSend = JFRGBAColor(0x0AA3D1, 1);
            // 气泡背景色:接受
            UIColor* bubbleBgColorReceive = [UIColor whiteColor];

            CGFloat QQGapM = JFScaleWidth6(15);
            CGFloat QQGapS = JFScaleWidth6(10);
            CGFloat QQGapXS = JFScaleWidth6(5);
            
            CGFloat lineSpace = 5;
            CGFloat kMaxWidth = JFScaleWidth6(195);

            
            // 发送方
            if (self.isSender) {
                // 头像|昵称
                JFTextStorage* name = [JFTextStorage storageWithText:@"1"];
                name.textColor = JFColorWhite;
                name.font = PING_FANG_MEDIUM(15);
                JFTextLayout* txt_name = [JFTextLayout textLayoutWithText:name];
                txt_name.backgroundColor = [UIColor avatarBgColorAtIndex:message.senderId.hash % 6];
                txt_name.width = txt_name.height = avatarWidth;
                txt_name.centerX = JFSCREEN_WIDTH - QQGapM - avatarWidth * 0.5;
                txt_name.centerY = QQGapM - JFScaleWidth6(2) + avatarWidth * 0.5;
                txt_name.tag = OTCMMessageLayoutsTagNickName;
                [self addLayout:txt_name];
                self.nickNameFrame = CGRectMake(JFSCREEN_WIDTH - QQGapM - avatarWidth - 1,
                                                QQGapM - JFScaleWidth6(2),
                                                avatarWidth, avatarWidth);

                // 内容: 文本|语音|图片|视频
                {
                    // 文本
                    if ([message.messageBody isKindOfClass:[OTCM_messageBodyText class]]) {
                        JFTextStorage* text = [JFTextStorage storageWithText:((OTCM_messageBodyText*)message.messageBody).text];
                        text.font = [UIFont systemFontOfSize:contentTextFontSize];
                        text.textColor = [UIColor whiteColor];
                        text.lineSpacing = lineSpace;
                        JFTextLayout* txt_content = [JFTextLayout textLayoutWithText:text];
                        txt_content.backgroundColor = bubbleBgColorSend;
                        txt_content.tag = OTCMMessageLayoutsTagText;
                        txt_content.numberOfLines = 0;
                        txt_content.width = kMaxWidth;
                        txt_content.height = 10000;
                        txt_content.top = QQGapM + contentBubbleInsets.top;
                        txt_content.right = JFSCREEN_WIDTH - QQGapM - avatarWidth - QQGapS - contentBubbleInsets.right;
                        [self addLayout:txt_content];
                        if (bottom < txt_content.bottom + contentBubbleInsets.bottom) {
                            bottom = txt_content.bottom + contentBubbleInsets.bottom + QQGapXS;
                        }
                        [self makeBubbleFrameWithLayout:txt_content isSender:YES];
                    }
                    // 图片
                    else if ([message.messageBody isKindOfClass:[OTCM_messageBodyImage class]]) {
                        OTCM_messageBodyImage* imageBody = (OTCM_messageBodyImage*)message.messageBody;
                        JFImageLayout* img_content = [JFImageLayout new];
                        img_content.contentMode = UIViewContentModeScaleAspectFill;
                        img_content.tag = OTCMMessageLayoutsTagImage;
                        // 图片存在
                        if (!IsNon(imageBody.imageUrl)) {
                            if ([imageBody.imageUrl isKindOfClass:[UIImage class]]) {
                                img_content.image = imageBody.imageUrl;
                            }
                            else if ([imageBody.imageUrl isKindOfClass:[NSURL class]]) {
                                img_content.image = imageBody.imageUrl;
                            }
                            else if ([imageBody.imageUrl isKindOfClass:[NSString class]]) {
                                // 本地图片
                                if ([imageBody.imageUrl hasPrefix:kOTCLocalImagePre]) {
                                    NSRange range = [imageBody.imageUrl rangeOfString:kOTCLocalImagePre];
                                    NSString* localPath = [imageBody.imageUrl substringFromIndex:range.location + range.length];
                                    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                    NSString* documentDir = [dirs lastObject];
                                    img_content.image = [UIImage imageWithContentsOfFile:[documentDir stringByAppendingPathComponent:localPath]];
                                }
                                // 网络图片
                                else {
                                    img_content.image = [NSURL URLWithString:[APNetworkClientAPIBaseURLString stringByAppendingPathComponent:imageBody.imageUrl]];
                                }
                            }
                        }
                        
                        CGSize imageSize = [self scaleSize:CGSizeMake(imageBody.imageWidth, imageBody.imageHeight) withMaxHeightOrWidth:mediaMaxHeight];
                        img_content.width = imageSize.width > 0 ? imageSize.width : 100;
                        img_content.height = imageSize.height > 0 ? imageSize.height : 100;
                        img_content.top = QQGapM;
                        img_content.right = JFSCREEN_WIDTH - QQGapM - avatarWidth - QQGapS;
                        img_content.cornerRadius = imgCornerSize;
                        [self addLayout:img_content];
                        if (bottom < img_content.bottom) {
                            bottom = img_content.bottom;
                        }
                        // 气泡.frame
                        self.bubbleHidden = YES;
                        [self makeBubbleFrameWithLayout:img_content isSender:YES];
                    }
                }
                
            }
            // 接收方
            else {
                // 昵称
                JFTextStorage* name = [JFTextStorage storageWithText:@"1"];
                name.textColor = JFColorWhite;
                name.font = JFFontWithName(@"PingFangSC-Medium", 15);
                JFTextLayout* txt_name = [JFTextLayout textLayoutWithText:name];
                txt_name.backgroundColor = [UIColor avatarBgColorAtIndex:message.senderId.hash % 6];
                txt_name.width = txt_name.height = 50;
                txt_name.centerX = QQGapM + avatarWidth * 0.5;
                txt_name.centerY = QQGapM - JFScaleWidth6(2) + avatarWidth * 0.5;
                txt_name.tag = OTCMMessageLayoutsTagNickName;
                [self addLayout:txt_name];
                self.nickNameFrame = CGRectMake(QQGapM,
                                                QQGapM - JFScaleWidth6(2),
                                                avatarWidth, avatarWidth);

                // 内容: 文本|语音|图片|视频
                {
                    // 文本
                    if ([message.messageBody isKindOfClass:[OTCM_messageBodyText class]]) {
                        JFTextStorage* text = [JFTextStorage storageWithText:((OTCM_messageBodyText*)message.messageBody).text];
                        text.font = [UIFont systemFontOfSize:contentTextFontSize];
                        text.textColor = [UIColor blackColor];
                        text.lineSpacing = lineSpace;
                        JFTextLayout* txt_content = [JFTextLayout textLayoutWithText:text];
                        txt_content.tag = OTCMMessageLayoutsTagText;
                        txt_content.numberOfLines = 0;
                        txt_content.width = kMaxWidth;
                        txt_content.height = 1000;
                        txt_content.top = QQGapM + contentBubbleInsets.top;
                        txt_content.left = QQGapM + avatarWidth + QQGapS + contentBubbleInsets.left;
                        txt_content.backgroundColor = bubbleBgColorReceive;
                        [self addLayout:txt_content];
                        if (bottom < txt_content.bottom + contentBubbleInsets.bottom) {
                            bottom = txt_content.bottom + contentBubbleInsets.bottom + QQGapXS;
                        }
                        // 气泡.frame
                        [self makeBubbleFrameWithLayout:txt_content isSender:NO];
                    }
                    // 图片
                    else if ([message.messageBody isKindOfClass:[OTCM_messageBodyImage class]]) {
                        OTCM_messageBodyImage* imageBody = (OTCM_messageBodyImage*)message.messageBody;
                        JFImageLayout* img_content = [JFImageLayout new];
                        img_content.contentMode = UIViewContentModeScaleAspectFill;
                        img_content.tag = OTCMMessageLayoutsTagImage;
                        // 图片存在
                        if (!IsNon(imageBody.imageUrl)) {
                            if ([imageBody.imageUrl isKindOfClass:[UIImage class]]) {
                                img_content.image = imageBody.imageUrl;
                            }
                            else if ([imageBody.imageUrl isKindOfClass:[NSURL class]]) {
                                img_content.image = imageBody.imageUrl;
                            }
                            else if ([imageBody.imageUrl isKindOfClass:[NSString class]]) {
                                // 本地图片
                                if ([imageBody.imageUrl hasPrefix:kOTCLocalImagePre]) {
                                    NSRange range = [imageBody.imageUrl rangeOfString:kOTCLocalImagePre];
                                    NSString* localPath = [imageBody.imageUrl substringFromIndex:range.location + range.length];
                                    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                    NSString* documentDir = [dirs lastObject];
                                    img_content.image = [UIImage imageWithContentsOfFile:[documentDir stringByAppendingPathComponent:localPath]];
                                }
                                // 网络图片
                                else {
                                    img_content.image = [NSURL URLWithString:[APNetworkClientAPIBaseURLString stringByAppendingPathComponent:imageBody.imageUrl]];
                                }
                            }
                        }
                        CGSize imageSize = [self scaleSize:CGSizeMake(imageBody.imageWidth, imageBody.imageHeight) withMaxHeightOrWidth:mediaMaxHeight];
                        img_content.width = imageSize.width > 0 ? imageSize.width : 100;
                        img_content.height = imageSize.height > 0 ? imageSize.height : 100;
                        img_content.top = QQGapM;
                        img_content.left = QQGapM + avatarWidth + QQGapS;
                        img_content.cornerRadius = imgCornerSize;
                        [self addLayout:img_content];
                        if (bottom < img_content.bottom) {
                            bottom = img_content.bottom;
                        }
                        // 气泡.frame
                        self.bubbleHidden = YES;
                        [self makeBubbleFrameWithLayout:img_content isSender:NO];
                    }
                }
            }
            self.viewFrame = CGRectMake(0, 0, JFSCREEN_WIDTH, bottom);
        }
    }
    return self;
}



// 计算气泡.frame
- (void) makeBubbleFrameWithLayout:(JFLayout*)layout isSender:(BOOL)isSender
{
    if ([layout isKindOfClass:[JFTextLayout class]]) {
        self.bubbleFrame = CGRectMake(CGRectGetMinX(layout.frame) - JFScaleWidth6(kOTCTextInsetsH),
                                      CGRectGetMinY(layout.frame) - JFScaleWidth6(kOTCTextInsetsV),
                                      layout.width + JFScaleWidth6(kOTCTextInsetsH * 2),
                                      layout.height + JFScaleWidth6(kOTCTextInsetsV * 2));
    } else {
        self.bubbleFrame = layout.frame;
    }
    
    CGFloat flagWidth = JFScaleWidth6(20);
    CGFloat gap = JFScaleWidth6(8);
    if (isSender) {
        self.flagFrame = CGRectMake(CGRectGetMinX(self.bubbleFrame) - gap - flagWidth,
                                    self.bubbleFrame.origin.y + self.bubbleFrame.size.height * 0.5 - flagWidth * 0.5,
                                    flagWidth,
                                    flagWidth);
    }
    else {
        self.flagFrame = CGRectMake(CGRectGetMaxX(self.bubbleFrame) + gap,
                                    self.bubbleFrame.origin.y + self.bubbleFrame.size.height * 0.5 - flagWidth * 0.5,
                                    flagWidth,
                                    flagWidth);
    }
}

// 计算图片的展示尺寸
- (CGSize) scaleSize:(CGSize)size withMaxHeightOrWidth:(CGFloat)maxWH {
    if (size.width == 0 || size.height == 0) {
        return size;
    }
    // >
    if (size.width > size.height) {
        CGFloat width = size.width < maxWH ? size.width : maxWH;
        return CGSizeMake(width, width * size.height/size.width);
    }
    // <
    else if (size.width < size.height) {
        CGFloat height = size.height < maxWH ? size.height : maxWH;
        return CGSizeMake(height * size.width/size.height, height);
    }
    // ==
    else {
        CGFloat width = size.width < maxWH ? size.width : maxWH;
        return CGSizeMake(width, width);
    }
}

@end
