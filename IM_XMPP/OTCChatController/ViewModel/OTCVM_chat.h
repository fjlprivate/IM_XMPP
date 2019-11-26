//
//  OTCVM_chat.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTCM_message.h"
#import "OTCIMCenter.h"
#import "OTCM_messageLayouts.h"
#import "OTCM_timeLayouts.h"
#import "OTCM_messageSystemLayouts.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTCVM_chat : NSObject

/**
 初始化
 @param conversationId 会话id
 @param toUserId 对方userId
 @return 聊天页面
 */
- (instancetype)initWithConversation:(NSString*)conversationId toUser:(NSString*)toUserId;

@property (nonatomic, copy) NSString* conversationId; // 会话id
@property (nonatomic, copy) NSString* toUserId; // 接收人id

/**
 查询接收方用户信息
 @param finishedBlock 回调:成功<receiverName接收人姓名>
 @param failedBlock 回调:失败<NSError>
 */
- (void) requestReceiverInfoOnFinished:(void (^) (NSString* receiverName))finishedBlock
                              orFailed:(void (^) (NSError* error))failedBlock;

/**
 加载新消息
 @param finishedBlock 回调:成功<NSArray<NSNumber<新增的row>>*>
 @param failedBlock 回调:失败<NSError>
 */
- (void) refreshMessagesOnFinished:(void (^) (NSArray* messages))finishedBlock
                          orFailed:(void (^) (NSError* error))failedBlock;

/**
 加载历史消息
 @param finishedBlock 回调:成功<加载的消息节点个数>
 @param failedBlock 回调:失败<NSError>
 */
- (void) loadHistoryMessagesOnFinished:(void (^) (NSInteger messagesCount))finishedBlock
                              orFailed:(void (^) (NSError* error))failedBlock;


/**
 发送消息:文本
 @param text 要发送的文本
 @param finishedBlock 回调:成功<index新消息的序号>
 @param failedBlock 回调:失败<index新消息的序号,NSError>
 @return <NSArray:被插入的消息组的序号,因为可能插入了时间,所以返回数组>
 */
- (NSArray*) sendMessageWithText:(NSString*)text
                      onFinished:(void (^) (NSInteger index))finishedBlock
                        orFailed:(void (^) (NSInteger index, NSError* error))failedBlock;



/**
 发送消息:图片
 @param image 要发送的图片
 @param finishedBlock 回调:成功<index新消息的序号>
 @param failedBlock 回调:失败<index新消息的序号,NSError>
 @return <NSArray:被插入的消息组的序号,因为可能插入了时间,所以返回数组>
 */
- (NSArray*) sendMessageWithImage:(UIImage*)image
                       onFinished:(void (^) (NSInteger index))finishedBlock
                         orFailed:(void (^) (NSInteger index, NSError* error))failedBlock;

// 重置用户聊天的所有未读为已读
- (void) resetAllUnread;

// dataSource

// 消息个数
- (NSInteger) numberOfMessages;
// 获取指定序号的消息
- (OTCM_message*) messageAtIndex:(NSInteger)index;
// cell布局对象
- (JFAsyncViewLayouts*) layoutsForMessageAtIndex:(NSInteger)index;

// 是否还有更多历史消息;默认:yes
@property (nonatomic, assign) BOOL hasEarlierMessages;

// 接收到消息的回调
@property (nonatomic, copy) void (^ didReceiveMessges) (void);


@end

NS_ASSUME_NONNULL_END
