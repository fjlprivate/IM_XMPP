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
            self.isSender = message.sendReceive == OTCMMessageSCSend;
            self.status = message.status;
            // 正文字体
            CGFloat contentTextFontSize = 16;
            // 内容与气泡的间距
            UIEdgeInsets contentBubbleInsets = UIEdgeInsetsMake(JFScaleWidth6(5),
                                                                JFScaleWidth6(10),
                                                                JFScaleWidth6(5),
                                                                JFScaleWidth6(10));
            // 文本与内容的边距
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(1, 2, 1, 2);
            // 气泡离边界的距离
            CGFloat bubbleGap = JFScaleWidth6(56);
            // 头像宽度
            CGFloat avatarWidth = JFScaleWidth6(44);
            // 图片|视频的最大显示高度
            CGFloat mediaMaxHeight = JFScaleWidth6(160);
            // 图片|视频|位置图片的圆角
            CGSize imgCornerSize = CGSizeMake(5, 5);
            // 底部
            CGFloat bottom = 0;
            
            // 气泡背景色:发送
            UIColor* bubbleBgColorSend = JFRGBAColor(0x0AA3D1, 1);
            // 气泡背景色:接受
            UIColor* bubbleBgColorReceive = [UIColor whiteColor];

            CGFloat QQGapM = 15;
            CGFloat QQGapXS = 5;
            CGFloat QQGapS = 10;
            
            CGFloat lineSpace = 5;

            
            // 发送方
            if (self.isSender) {
                // 头像
                JFImageLayout* img_avatar = [JFImageLayout new];
                img_avatar.tag = OTCMMessageLayoutsTagAvatar;
                img_avatar.image = message.senderAvator;
                img_avatar.contentMode = UIViewContentModeScaleAspectFill;
//                img_avatar.placeHolder = JFImageNamed(@"avatar");
                img_avatar.top = JFScaleWidth6(QQGapM);
                img_avatar.width = img_avatar.height = avatarWidth;
                img_avatar.left = JFSCREEN_WIDTH - JFScaleWidth6(QQGapM) - img_avatar.width;
                img_avatar.cornerRadius = CGSizeMake(img_avatar.width * 0.5, img_avatar.height * 0.5);
                img_avatar.backgroundColor = [UIColor avatarBgColorAtIndex:message.senderId.hash % 6];
                [self addLayout:img_avatar];
                bottom = img_avatar.bottom;
                // 昵称
                JFTextStorage* name = [JFTextStorage storageWithText:@"1"];
                name.backgroundColor = img_avatar.backgroundColor;
                name.textColor = JFColorWhite;
                name.font = JFFontWithName(@"PingFangSC-Medium", 15);
                JFTextLayout* txt_name = [JFTextLayout textLayoutWithText:name];
                txt_name.backgroundColor = name.backgroundColor;
                txt_name.width = txt_name.height = 50;
                txt_name.centerX = img_avatar.centerX;
                txt_name.centerY = img_avatar.centerY;
                [self addLayout:txt_name];

                // 内容: 文本|语音|图片|视频
                {
                    // 文本
                    if ([message.messageBody isKindOfClass:[OTCM_messageBodyText class]]) {
                        JFTextStorage* text = [JFTextStorage storageWithText:((OTCM_messageBodyText*)message.messageBody).text];
                        text.font = [UIFont systemFontOfSize:contentTextFontSize];
                        text.textColor = [UIColor whiteColor];
                        text.lineSpacing = lineSpace;
                        text.backgroundColor = bubbleBgColorSend;
                        JFTextLayout* txt_content = [JFTextLayout textLayoutWithText:text];
                        txt_content.tag = OTCMMessageLayoutsTagText;
                        txt_content.insets = contentInsets;
                        txt_content.numberOfLines = 0;
                        txt_content.width = img_avatar.left - bubbleGap - JFScaleWidth6(QQGapS) - contentBubbleInsets.left - contentBubbleInsets.right;
                        txt_content.height = 10000;
                        txt_content.top = img_avatar.top + JFScaleWidth6(QQGapXS + 2) + contentBubbleInsets.top;
                        txt_content.left = img_avatar.left - JFScaleWidth6(QQGapS) - txt_content.width - contentBubbleInsets.right;
                        txt_content.backgroundColor = text.backgroundColor;
                        [self addLayout:txt_content];
                        if (bottom < txt_content.bottom + contentBubbleInsets.bottom) {
                            bottom = txt_content.bottom + contentBubbleInsets.bottom + QQGapXS;
                        }
                        // 气泡.frame
                        [self makeBubbleFrameWithLayout:txt_content widthBubbleContentInsets:contentBubbleInsets isSender:YES];
                    }
                    // 图片
                    else if ([message.messageBody isKindOfClass:[OTCM_messageBodyImage class]]) {
                        OTCM_messageBodyImage* imageBody = (OTCM_messageBodyImage*)message.messageBody;
                        JFImageLayout* img_content = [JFImageLayout new];
                        img_content.backgroundColor = JFColorWhite;
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
                        else {
                            // 占位图
//                            img_content.image = JFImageNamed(@"placeholder_circle_image");
                        }
                        
                        CGSize imageSize = [self scaleSize:CGSizeMake(imageBody.imageWidth, imageBody.imageHeight) withMaxHeightOrWidth:mediaMaxHeight];
                        img_content.width = imageSize.width > 0 ? imageSize.width : 100;
                        img_content.height = imageSize.height > 0 ? imageSize.height : 100;
                        img_content.top = img_avatar.top + JFScaleWidth6(QQGapXS);
                        img_content.left = img_avatar.left - JFScaleWidth6(QQGapS) - img_content.width;
                        img_content.cornerRadius = imgCornerSize;
                        [self addLayout:img_content];
                        if (bottom < img_content.bottom) {
                            bottom = img_content.bottom;
                        }
                        // 气泡.frame
                        self.bubbleHidden = YES;
                        [self makeBubbleFrameWithLayout:img_content widthBubbleContentInsets:contentBubbleInsets isSender:YES];
                    }
                }
                
            }
            // 接收方
            else {
                // 头像
                JFImageLayout* img_avatar = [JFImageLayout new];
                img_avatar.tag = OTCMMessageLayoutsTagAvatar;
                img_avatar.image = message.senderAvator;
                img_avatar.contentMode = UIViewContentModeScaleAspectFill;
//                img_avatar.placeHolder = JFImageNamed(@"avatar");
                img_avatar.top = JFScaleWidth6(QQGapM);
                img_avatar.width = img_avatar.height = avatarWidth;
                img_avatar.left = JFScaleWidth6(QQGapM);
                img_avatar.backgroundColor = [UIColor avatarBgColorAtIndex:message.senderId.hash % 6];
                img_avatar.cornerRadius = CGSizeMake(img_avatar.width * 0.5, img_avatar.height * 0.5);
                [self addLayout:img_avatar];
                bottom = img_avatar.bottom;
                // 昵称
                JFTextStorage* name = [JFTextStorage storageWithText:@"1"];
                name.backgroundColor = img_avatar.backgroundColor;
                name.textColor = JFColorWhite;
                name.font = JFFontWithName(@"PingFangSC-Medium", 15);
                JFTextLayout* txt_name = [JFTextLayout textLayoutWithText:name];
                txt_name.backgroundColor = name.backgroundColor;
                txt_name.width = txt_name.height = 50;
                txt_name.centerX = img_avatar.centerX;
                txt_name.centerY = img_avatar.centerY;
                [self addLayout:txt_name];

                // 昵称
                // 内容: 文本|语音|图片|视频
                {
                    // 文本
                    if ([message.messageBody isKindOfClass:[OTCM_messageBodyText class]]) {
                        JFTextStorage* text = [JFTextStorage storageWithText:((OTCM_messageBodyText*)message.messageBody).text];
                        text.font = [UIFont systemFontOfSize:contentTextFontSize];
                        text.textColor = [UIColor blackColor];
                        text.lineSpacing = lineSpace;
                        text.backgroundColor = bubbleBgColorReceive;
                        JFTextLayout* txt_content = [JFTextLayout textLayoutWithText:text];
                        txt_content.tag = OTCMMessageLayoutsTagText;
                        txt_content.insets = contentInsets;
                        txt_content.numberOfLines = 0;
                        txt_content.width = JFSCREEN_WIDTH - img_avatar.right - JFScaleWidth6(QQGapS) - bubbleGap - contentBubbleInsets.left - contentBubbleInsets.right;
                        txt_content.height = 1000;
                        txt_content.top = img_avatar.top + JFScaleWidth6(QQGapXS + 2) + contentBubbleInsets.top;
                        txt_content.left = img_avatar.right + JFScaleWidth6(QQGapS) + contentBubbleInsets.left;
                        txt_content.backgroundColor = text.backgroundColor;
                        [self addLayout:txt_content];
                        if (bottom < txt_content.bottom + contentBubbleInsets.bottom) {
                            bottom = txt_content.bottom + contentBubbleInsets.bottom + QQGapXS;
                        }
                        // 气泡.frame
                        [self makeBubbleFrameWithLayout:txt_content widthBubbleContentInsets:contentBubbleInsets isSender:NO];
                    }
                    // 图片
                    else if ([message.messageBody isKindOfClass:[OTCM_messageBodyImage class]]) {
                        OTCM_messageBodyImage* imageBody = (OTCM_messageBodyImage*)message.messageBody;
                        JFImageLayout* img_content = [JFImageLayout new];
                        img_content.backgroundColor = JFColorWhite;
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
                        else {
                            // 占位图
                            //                            img_content.image = JFImageNamed(@"placeholder_circle_image");
                        }
                        CGSize imageSize = [self scaleSize:CGSizeMake(imageBody.imageWidth, imageBody.imageHeight) withMaxHeightOrWidth:mediaMaxHeight];
                        img_content.width = imageSize.width > 0 ? imageSize.width : 100;
                        img_content.height = imageSize.height > 0 ? imageSize.height : 100;
                        img_content.top = img_avatar.top + JFScaleWidth6(QQGapXS);
                        img_content.left = img_avatar.right + JFScaleWidth6(QQGapS);
                        img_content.cornerRadius = imgCornerSize;
                        [self addLayout:img_content];
                        if (bottom < img_content.bottom) {
                            bottom = img_content.bottom;
                        }
                        // 气泡.frame
                        self.bubbleHidden = YES;
                        [self makeBubbleFrameWithLayout:img_content widthBubbleContentInsets:contentBubbleInsets isSender:NO];
                    }
                }
            }
            self.viewFrame = CGRectMake(0, 0, JFSCREEN_WIDTH, bottom);

        }
    }
    return self;
}



// 计算气泡.frame
- (void) makeBubbleFrameWithLayout:(JFLayout*)layout
          widthBubbleContentInsets:(UIEdgeInsets)bubbleContentInsets
                          isSender:(BOOL)isSender
{
    self.bubbleFrame = CGRectMake(layout.viewOrigin.x - bubbleContentInsets.left,
                                  layout.viewOrigin.y - bubbleContentInsets.top,
                                  layout.suggustSize.width + bubbleContentInsets.left + bubbleContentInsets.right,
                                  layout.suggustSize.height + bubbleContentInsets.top + bubbleContentInsets.bottom);
    
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
