//
//  OTCM_message.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTCM_messageBody.h"
#import "OTCIMConstants.h"

NS_ASSUME_NONNULL_BEGIN


@interface OTCM_message : NSObject

// 发送方-接收方
@property (nonatomic, assign) OTCMMessageSC sendReceive;

// 时间戳;单位毫秒
@property (nonatomic, assign) NSTimeInterval timestamp;

// 发送人id
@property (nonatomic, copy) NSString* senderId;
// 发送人name
@property (nonatomic, copy) NSString* senderName;
// 发送人avator
@property (nonatomic, copy) NSURL* senderAvator;

// 接收人id
@property (nonatomic, copy) NSString* receiverId;
// 接收人name
@property (nonatomic, copy) NSString* receiverName;
// 接收人avator
@property (nonatomic, copy) NSURL* receiverAvator;

// 会话id
@property (nonatomic, copy) NSString* conversationId;
// 创建消息时被创建
@property (nonatomic, assign) int64_t messageId;
// 是否已读;默认:NO
@property (nonatomic, assign) BOOL isRead;
// 消息状态
@property (nonatomic, assign) OTCMMessageStatus status;

// 消息体类型
@property (nonatomic, assign) OTCMMessageBodyType messageBodyType;
// 内容body
@property (nonatomic, strong) OTCM_messageBody* messageBody;

@end

NS_ASSUME_NONNULL_END
