//
//  OTCIMCenter.m
//  OTC
//
//  Created by LongerFeng on 2019/7/19.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#import "OTCIMCenter.h"



@interface OTCIMCenter()
@property (nonatomic, strong) NSMutableArray* delegates;
// 是否已登录
@property (nonatomic, assign) BOOL isLogin;
@end

@implementation OTCIMCenter


# pragma mark - public

// 单例入口;app启动时就要创建;会打开webSocket，接收服务器的消息
+ (OTCIMCenter*) sharedCenter {
    static OTCIMCenter* center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [OTCIMCenter new];
    });
    return center;
}

/**
 添加|移除代理;注意:::添加的代理一定要移除，否则会内存泄漏
 */
- (void) addDelegate:(id<OTCIMCenterDelegate>)delegate {
    [self.delegates addObject:delegate];
}
- (void) removeDelegate:(id<OTCIMCenterDelegate>)delegate {
    if ([self.delegates containsObject:delegate]) {
        [self.delegates removeObject:delegate];
    }
}
- (void) removeAllDelegates {
    [self.delegates removeAllObjects];
}

// 链接服务器
- (void) im_connectServer {
    [self connectServer];
    // DB也要重建
    [self initialDB];
}
// 断开服务器链接
- (void) im_disconnectServer {
    [self disconnectServer];
    [self closeDB];
}




/**
 发送消息
 @param message 发送的消息
 */
- (void) im_sendMessage:(OTCM_message*)message
{
    // 未登录，不处理
    if (!self.isLogin) {
        for (id<OTCIMCenterDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(imCenter:didFailedToSendMessage:error:)]) {
                [delegate imCenter:self didFailedToSendMessage:message error:[NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"未登录IM系统", nil)]];
            }
        }
        return;
    }
    // 1. 插入到DB
    WeakSelf(wself);
    [self insertDBWithMessage:message onFinished:^{
        // 2. 发送到服务器
        [wself sendMessageToServer:message];
    } orFailed:^(NSError * _Nonnull error) {
    }];
}


/**
 重发消息
 @param message 重发的消息
 @param finishedBlock 回调:成功<更新状态的message>
 @param failedBlock 回调:失败<NSError>
 */
- (void) im_reSendMessage:(OTCM_message*)message
               onFinished:(void (^) (OTCM_message* message))finishedBlock
                 orFailed:(void (^) (NSError* error))failedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        for (id<OTCIMCenterDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(imCenter:didFailedToSendMessage:error:)]) {
                [delegate imCenter:self didFailedToSendMessage:message error:[NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"未登录IM系统", nil)]];
            }
        }
        return;
    }
    if (finishedBlock) {
        finishedBlock(message);
    }
}

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
                                   orFailed:(void (^) (NSError* error))failedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        if (failedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"未登录IM系统", nil)]);
            });
        }
        return;
    }
    if (!conversationId || conversationId.length == 0) {
        if (failedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"请输入要查询的会话id", nil)]);
            });
        }
        return;
    }
    // 都小于0:设置toTime为当前时间
    if (fromTime < 0 && toTime < 0) {
        toTime = [self __curTimestamp];
//        if (failedBlock) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                failedBlock([NSError jf_errorWithCode:99 localizedDescription:@"请输入具体的查询区间"]);
//            });
//        }
//        return;
    }
//    DLog(@"---------------当前请求刷新数据的时间区间[%lf]-[%lf];;", fromTime, toTime);
    [self requestMessagesWithConversation:conversationId fromTime:fromTime toTime:toTime onFinished:^(NSArray<OTCM_message *> *messages) {
        if (finishedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishedBlock(messages);
            });
        }
    } orFailed:^(NSError *error) {
        if (failedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"请输入具体的查询区间", nil)]);
            });
        }
    }];
}

/**
 查询会话列表
 @param finishedBlock 回调:成功<NSArray<OTCM_conversation*>>
 @param failedBlock 回调:失败<NSError>
 */
- (void) im_requestConversationsOnFinished:(void (^) (NSArray<OTCM_conversation*>* conversations))finishedBlock
                                  orFailed:(void (^) (NSError* error))failedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        if (failedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"未登录IM系统", nil)]);
            });
        }
        return;
    }
    [self requestConversationsOnFinished:finishedBlock orFailed:failedBlock];
}


// 删除消息
- (void) im_deleteMessage:(OTCM_message*)message
               onFinished:(void (^) (void))finishedBlock
                 orFailed:(void (^) (NSError* error))failedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        return;
    }

}

// 撤回消息
- (void) im_revokeMessage:(OTCM_message*)message
               onFinished:(void (^) (void))finishedBlock
                 orFailed:(void (^) (NSError* error))failedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        return;
    }

}

/**
 查询所有的未读消息条数
 @param finishedBlock 回调:未读数
 @param failedBlock 回调:查询失败
 */
- (void) im_requestAllUnreadCountOnFinished:(void (^) (NSInteger count))finishedBlock
                                   orFailed:(void (^) (NSError* error))failedBlock
{
    WeakSelf(wself);
    __block NSUInteger badgeCount = 0;
    [self im_requestConversationsOnFinished:^(NSArray<OTCM_conversation *> * _Nonnull conversations) {
        dispatch_group_t group = dispatch_group_create();
        for (OTCM_conversation* conv in conversations) {
            dispatch_group_enter(group);
            [wself im_getUnreadCountForConversation:conv.conversationId onFinished:^(NSInteger count) {
                badgeCount += count;
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (finishedBlock) {
                finishedBlock(badgeCount);
            }
        });
    } orFailed:failedBlock];
}


/**
 查询指定会话的未读消息的个数
 @param conversationId 会话id
 @param finishedBlock 回调:未读数
 */
- (void) im_getUnreadCountForConversation:(NSString*)conversationId
                               onFinished:(void (^) (NSInteger count))finishedBlock
{
    // 未登录，不处理
    if (!self.isLogin) {
        if (finishedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishedBlock(0);
            });
        }
        return;
    }
    [self getUnreadCountForConversation:conversationId onFinished:finishedBlock];
}

/**
 重置指定会话的所有未读为已读
 @param conversationId 会话id
 */
- (void) im_resetAllUnreadForConversation:(NSString*)conversationId {
    // 未登录，不处理
    if (!self.isLogin) {
        return;
    }
    [self resetAllUnreadForConversation:conversationId];
}

# pragma mark - Server的回调处理

// 发送消息到服务器后的处理
- (void) __didSucToSendMessage:(OTCM_message*)message {
    // 3. 更新DB状态:测试发现这个时候还没有插入数据
    message.status = OTCMMessageStatusSendSuc;
    [self updateMessage:message onFinished:^{
    } orFailed:^(NSError * _Nonnull error) {
    }];
    // 4. 回调结果
    for (id<OTCIMCenterDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imCenter:didSendMessage:)]) {
            [delegate imCenter:self didSendMessage:message];
        }
    }
}
// 发送消息到服务器失败后的处理
- (void) __didFailToSendMessage:(OTCM_message*)message error:(NSError*)error{
    // 3. 更新DB状态
    message.status = OTCMMessageStatusSendFail;
    [self updateMessage:message onFinished:^{
    } orFailed:^(NSError * _Nonnull error) {
    }];
    // 4. 回调结果
    for (id<OTCIMCenterDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imCenter:didFailedToSendMessage:error:)]) {
            [delegate imCenter:self didFailedToSendMessage:message error:error];
        }
    }
}

// 接收到新消息的处理
- (void) __didReceiveMessage:(OTCM_message*)message {
    // 消息写入DB
    WeakSelf(wself);
    [self insertDBWithMessage:message onFinished:^{
        // 回调
        for (id<OTCIMCenterDelegate> delegate in wself.delegates) {
            if ([delegate respondsToSelector:@selector(imCenter:didReceivedMessage:)]) {
                [delegate imCenter:wself didReceivedMessage:message];
            }
        }
    } orFailed:^(NSError * _Nonnull error) {
        
    }];
}

// 连接服务器成功的回调
- (void) __didConnectServer {
    DLog(@"\n------------\n------------\n已连接IM服务器\n-------------\n--------------\n");
    self.isLogin = YES;
    for (id<OTCIMCenterDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imCenterDidConnectServer:)]) {
            [delegate imCenterDidConnectServer:self];
        }
    }
}

// 连接服务器失败的回调
- (void) __didFailToConnectServer:(NSError*)error {
    DLog(@"\n------------\n------------\n已断开IM服务器\n-------------\n--------------\n");
    self.isLogin = NO;
    for (id<OTCIMCenterDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imCenter:didFailedToConnectServere:)]) {
            [delegate imCenter:self didFailedToConnectServere:error];
        }
    }
}

// 获取当前系统时间戳
- (NSTimeInterval) __curTimestamp {
    NSDate* date = [NSDate date];
    return [date timeIntervalSince1970] * 1000; // 单位:毫秒
}


# pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialServer];
    }
    return self;
}
- (void)dealloc {
    [self releaseServer];
}

# pragma mark - getter
- (NSMutableArray *)delegates {
    if (!_delegates) {
        _delegates = @[].mutableCopy;
    }
    return _delegates;
}
- (NSString *)mineUserId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
}
- (NSString *)minePassword {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"passWord"];
}

@end
