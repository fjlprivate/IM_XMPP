//
//  OTCM_messageLayouts.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "JFAsyncViewLayouts.h"
#import "OTCM_message.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, OTCMMessageLayoutsTag) {
    OTCMMessageLayoutsTagAvatar          = 100,              // 头像
    OTCMMessageLayoutsTagNickName,                           // 昵称
    OTCMMessageLayoutsTagText,                               // 文本正文
    OTCMMessageLayoutsTagImage,                              // 图片

};

static CGFloat const kOTCAvatarWidth = 32.f;    // 头像宽度
static CGFloat const kOTCTextInsetsV = 10.f;    // 垂直方向的间距
static CGFloat const kOTCTextInsetsH = 15.f;    // 水平方向的间距
static CGFloat const kOTCCornerRadius = 10.f;   // 圆角值



@interface OTCM_messageLayouts : JFAsyncViewLayouts

+ (instancetype) layoutWithMessage:(OTCM_message*)message;

@property (nonatomic, strong) OTCM_message* message;

// 气泡frame
@property (nonatomic, assign) CGRect bubbleFrame;
// 昵称frame
@property (nonatomic, assign) CGRect nickNameFrame;
// 状态标志frame
@property (nonatomic, assign) CGRect flagFrame;

// 是否隐藏气泡
@property (nonatomic, assign) BOOL bubbleHidden;

// YES:发送方; NO:接收方;
@property (nonatomic, assign) BOOL isSender;
// 发送状态
@property (nonatomic, assign) OTCMMessageStatus status;

@end

NS_ASSUME_NONNULL_END
