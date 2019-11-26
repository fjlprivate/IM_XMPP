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

@interface OTCM_messageLayouts : JFAsyncViewLayouts

+ (instancetype) layoutWithMessage:(OTCM_message*)message;

// 气泡frame
@property (nonatomic, assign) CGRect bubbleFrame;
// 是否隐藏气泡
@property (nonatomic, assign) BOOL bubbleHidden;
// 状态标志frame
@property (nonatomic, assign) CGRect flagFrame;

// YES:发送方; NO:接收方;
@property (nonatomic, assign) BOOL isSender;
// 发送状态
@property (nonatomic, assign) OTCMMessageStatus status;

@end

NS_ASSUME_NONNULL_END
