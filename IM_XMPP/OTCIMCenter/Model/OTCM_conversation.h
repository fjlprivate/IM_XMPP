//
//  OTCM_conversation.h
//  AntPocket
//
//  Created by cui on 2019/8/19.
//  Copyright © 2019 AntPocket. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTCM_message.h"

NS_ASSUME_NONNULL_BEGIN

/* 消息会话类 */
@interface OTCM_conversation : NSObject

// 会话id
@property (nonatomic, copy) NSString* conversationId;

// 未读消息个数
@property (nonatomic, assign) NSInteger unreadMessagesCount;

// 会话标题
@property (nonatomic, copy) NSString* conversationTitle;
// 最新的消息
@property (nonatomic, strong) OTCM_message* latestMessage;

@end

NS_ASSUME_NONNULL_END
