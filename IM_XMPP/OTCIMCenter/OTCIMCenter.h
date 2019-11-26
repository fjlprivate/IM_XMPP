//
//  OTCIMCenter.h
//  OTC
//
//  Created by LongerFeng on 2019/7/19.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTCM_conversation.h"
#import "OTCM_messageBodyText.h"
#import "OTCM_messageBodyImage.h"
#import "JFKit.h"
#import <SDWebImage.h>
// 服务器相关
#import <XMPPFramework/XMPPFramework.h>
#import "APOTCUpLoadImageLogic.h"
// DB相关
#import <sqlite3.h>


NS_ASSUME_NONNULL_BEGIN





@class OTCIMCenter;
@protocol OTCIMCenterDelegate <NSObject>

@optional


/**
 链接服务器成功
 @param center 消息中心
 */
- (void) imCenterDidConnectServer:(OTCIMCenter*)center;

/**
 链接服务器失败
 @param center 消息中心
 @param error 错误信息
 */
- (void) imCenter:(OTCIMCenter*)center didFailedToConnectServere:(NSError*)error;

/**
 发送消息成功
 @param center 消息中心
 @param message 发送的消息
 */
- (void) imCenter:(OTCIMCenter*)center didSendMessage:(OTCM_message*)message;

/**
 发送消息失败
 @param center 消息中心
 @param message 发送的消息
 @param error 失败信息
 */
- (void) imCenter:(OTCIMCenter*)center didFailedToSendMessage:(OTCM_message*)message error:(NSError*)error;

/**
 接收到了消息
 @param center 消息中心
 @param message 接收到的消息
 */
- (void) imCenter:(OTCIMCenter*)center didReceivedMessage:(OTCM_message*)message;

@end





@interface OTCIMCenter : NSObject

// 是否已登录
@property (nonatomic, readonly, assign) BOOL isLogin;

/**
 单例入口;
 app启动时就要创建;会打开webSocket，接收服务器的消息
 @return OTCIMCenter
 */
+ (OTCIMCenter*) sharedCenter;


/**
 添加|移除代理;注意:::添加的代理一定要移除，否则会内存泄漏
 */
- (void) addDelegate:(id<OTCIMCenterDelegate>)delegate;
- (void) removeDelegate:(id<OTCIMCenterDelegate>)delegate;
- (void) removeAllDelegates;

/**
 链接服务器
 */
- (void) im_connectServer;

/**
 断开服务器链接
 */
- (void) im_disconnectServer;

/**
 发送消息
 @param message 发送的消息
 */
- (void) im_sendMessage:(OTCM_message*)message;


/**
 重发消息
 @param message 重发的消息
 */
- (void) im_reSendMessage:(OTCM_message*)message;

/**
 查询消息;分页返回;一页20条数据;
 @param conversationId 会话id
 @param fromTime 起始时间:-1时,表示所有toTime之前的
 @param toTime 结束时间:-1时,表示所有fromTime之后的
 @param finishedBlock 回调:成功<NSArray消息列表,20条>
 @param failedBlock 回调:失败<NSError>
 */
- (void) im_requestMessagesWithConversation:(NSString*)conversationId
                                   fromTime:(NSTimeInterval)fromTime
                                     toTime:(NSTimeInterval)toTime
                                 onFinished:(void (^) (NSArray<OTCM_message*>* messages))finishedBlock
                                   orFailed:(void (^) (NSError* error))failedBlock;


/**
 查询会话列表
 @param finishedBlock 回调:成功<NSArray<OTCM_conversation*>>
 @param failedBlock 回调:失败<NSError>
 */
- (void) im_requestConversationsOnFinished:(void (^) (NSArray<OTCM_conversation*>* conversations))finishedBlock
                                  orFailed:(void (^) (NSError* error))failedBlock;

/**
 删除消息
 @param message 需要删除的消息
 @param finishedBlock 回调:删除成功
 @param failedBlock 回调:删除失败
 */
- (void) im_deleteMessage:(OTCM_message*)message
               onFinished:(void (^) (void))finishedBlock
                 orFailed:(void (^) (NSError* error))failedBlock;

/**
 撤回消息
 @param message 需要撤回的消息
 @param finishedBlock 回调:撤回成功
 @param failedBlock 回调:撤回失败
 */
- (void) im_revokeMessage:(OTCM_message*)message
               onFinished:(void (^) (void))finishedBlock
                 orFailed:(void (^) (NSError* error))failedBlock;



/**
 查询所有的未读消息条数
 @param finishedBlock 回调:未读数
 @param failedBlock 回调:查询失败
 */
- (void) im_requestAllUnreadCountOnFinished:(void (^) (NSInteger count))finishedBlock
                                   orFailed:(void (^) (NSError* error))failedBlock;
/**
 查询指定会话的未读消息的个数
 @param conversationId 会话id
 @param finishedBlock 回调:未读数
 */
- (void) im_getUnreadCountForConversation:(NSString*)conversationId
                               onFinished:(void (^) (NSInteger count))finishedBlock;

/**
 重置指定会话的所有未读为已读
 @param conversationId 会话id
 */
- (void) im_resetAllUnreadForConversation:(NSString*)conversationId;


# pragma mark - private
// 发送消息到服务器后的处理
- (void) __didSucToSendMessage:(OTCM_message*)message;
// 发送消息到服务器失败后的处理
- (void) __didFailToSendMessage:(OTCM_message*)message error:(NSError*)error;
// 接收到新消息的处理
- (void) __didReceiveMessage:(OTCM_message*)message;
// 连接服务器成功的回调
- (void) __didConnectServer;
// 连接服务器失败的回调
- (void) __didFailToConnectServer:(NSError*)error;

// 获取当前系统时间戳
- (NSTimeInterval) __curTimestamp;

// 我的userId
@property (nonatomic, copy) NSString* mineUserId;
// 我的密码
@property (nonatomic, copy) NSString* minePassword;

@end


# pragma mark - ****************** 以下是私有方法，外部不要调用 *******************
# pragma mark - ****************** 以下是私有方法，外部不要调用 *******************
# pragma mark - ****************** 以下是私有方法，外部不要调用 *******************


@interface OTCIMCenter (Server)  <XMPPStreamDelegate>

// 消息管理器
@property (nonatomic, strong) XMPPStream* xmppStream;
// 重连组件
@property (nonatomic, strong) XMPPReconnect* xmppReconnect;
// 发送消息的缓存
@property (nonatomic, strong) NSMutableArray<OTCM_message*>* messageSendCache;
// 图片上传器
@property (nonatomic, strong) APOTCUpLoadImageLogic* imageUploader;

// 回调:接收到了服务器的消息
@property (nonatomic, copy) void (^ didReceiveMessageFromServer) (OTCM_message* message);


// 初始化服务器配置
- (void) initialServer;
// 清理服务器配置
- (void) releaseServer;

// 链接服务器
- (void) connectServer;
// 断开服务器链接
- (void) disconnectServer;

// 发送消息到服务器
- (void) sendMessageToServer:(OTCM_message *)message;

@end




@interface OTCIMCenter (CoreData)
//@property (nonatomic, strong) NSPersistentContainer* pContainer; // 消息持久化
@property (nonatomic, strong) dispatch_queue_t dbReadQueue; // 读队列:异步
@property (nonatomic, strong) dispatch_queue_t dbWriteQueue; // 写队列:同步

// 初始化DB
- (void) initialDB;
// 关闭DB
- (void) closeDB;


// 插入新消息到DB
- (void) insertDBWithMessage:(OTCM_message*)message
                  onFinished:(void (^) (void))finishedBlock
                    orFailed:(void (^) (NSError* error))failedBlock;

/**
 更新消息的状态
 @param message 消息
 @param status OTCMMessageStatus
 */
//- (void) updateMessage:(OTCM_message*)message withStatus:(OTCMMessageStatus)status;
- (void) updateMessage:(OTCM_message*)message
            onFinished:(void (^) (void))finishedBlock
              orFailed:(void (^) (NSError* error))failedBlock;

/**
 查询消息;分页返回;一页20条数据;
 @param conversationId 会话id
 @param fromTime 起始时间:-1时,表示所有toTime之前的
 @param toTime 结束时间:-1时,表示所有fromTime之后的
 @param finishedBlock 回调:成功<NSArray消息列表,20条>
 @param failedBlock 回调:失败<NSError>
 */
- (void) requestMessagesWithConversation:(NSString*)conversationId
                                fromTime:(NSTimeInterval)fromTime
                                  toTime:(NSTimeInterval)toTime
                              onFinished:(void (^) (NSArray<OTCM_message*>* messages))finishedBlock
                                orFailed:(void (^) (NSError* error))failedBlock;

/**
 查询会话列表
 @param finishedBlock 回调:成功<NSArray<OTCM_conversation*>>
 @param failedBlock 回调:失败<NSError>
 */
- (void) requestConversationsOnFinished:(void (^) (NSArray<OTCM_conversation*>* conversations))finishedBlock
                               orFailed:(void (^) (NSError* error))failedBlock;


// 查询指定会话的未读消息的个数
- (void) getUnreadCountForConversation:(NSString*)conversationId onFinished:(void (^) (NSInteger count))finishedBlock;

// 重置指定会话的所有未读为已读
- (void) resetAllUnreadForConversation:(NSString*)conversationId;

@end



NS_ASSUME_NONNULL_END
