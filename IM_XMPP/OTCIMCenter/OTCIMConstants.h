//
//  OTCIMConstants.h
//  OTC
//
//  Created by LongerFeng on 2019/7/20.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#ifndef OTCIMConstants_h
#define OTCIMConstants_h


// 消息体类型
typedef NS_ENUM(NSInteger, OTCMMessageBodyType) {
    OTCMMessageBodyTypeText         = 1, // 文本
    OTCMMessageBodyTypeImage        = 2  // 图片
};

// 消息发送-接收方向
typedef NS_ENUM(NSInteger, OTCMMessageSC) {
    OTCMMessageSCSend,                   // 发送
    OTCMMessageSCReceive                 // 接收
};


// 消息状态
typedef NS_ENUM(NSInteger, OTCMMessageStatus) {
    OTCMMessageStatusNotSend        = 1,  // 未发送
    OTCMMessageStatusSendSuc        = 2,  // 发送成功
    OTCMMessageStatusSendFail       = 3   // 发送失败
};

#endif /* OTCIMConstants_h */
