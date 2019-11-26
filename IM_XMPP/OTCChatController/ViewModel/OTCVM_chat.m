//
//  OTCVM_chat.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCVM_chat.h"
#import "OTCM_messageBodyText.h"
#import "OTCM_messageBodyImage.h"
#import "APNetworkClient.h"
#import "JFKit.h"


@interface OTCVM_chat() <OTCIMCenterDelegate>

@property (nonatomic, copy) NSString* toUserName; // 接收人名称
@property (nonatomic, copy) NSURL* toUserAvatar; // 接收人头像


@property (nonatomic, weak) OTCIMCenter* imCenter; // IM管理器
@property (nonatomic, strong) NSMutableArray* messages; // 消息数组
@property (nonatomic, strong) NSMutableArray* messageLayouts; // 消息布局对象数组

@property (nonatomic, assign) NSTimeInterval latestMessageTime; // 当前最新消息的时间;初始-1
@property (nonatomic, assign) NSTimeInterval latestRecordTimestamp; // 最近一次记录的时间戳;用来计算是否显示时间

@property (nonatomic, assign) NSTimeInterval earlyMessageTime; // 最早一条消息的时间;初始当前时间戳
@property (nonatomic, assign) NSTimeInterval earlyRecordTimestamp; // 最早记录的时间戳;用来计算是否显示时间


@property (nonatomic, copy) void (^ didSendMessage) (NSInteger index);
@property (nonatomic, copy) void (^ didFailToSendMessage) (NSInteger index, NSError* error);

@property (nonatomic, strong) JFAsyncFlag* asyncFlag;
@property (nonatomic, assign) NSInteger lastestMessagesCount;
@end



@implementation OTCVM_chat

// 消息个数
- (NSInteger) numberOfMessages {
    return [self.messages count];
}
// 获取指定序号的消息
- (OTCM_message*) messageAtIndex:(NSInteger)index {
    if (index < self.messages.count) {
        return self.messages[index];
    }
    return nil;
}
// cell布局对象
- (OTCM_messageLayouts*) layoutsForMessageAtIndex:(NSInteger)index {
    if (index < self.messageLayouts.count) {
        return self.messageLayouts[index];
    }
    return nil;
}

/**
 查询接收方用户信息
 @param finishedBlock 回调:成功<receiverName接收人姓名>
 @param failedBlock 回调:失败<NSError>
 */
- (void) requestReceiverInfoOnFinished:(void (^) (NSString* receiverName))finishedBlock
                              orFailed:(void (^) (NSError* error))failedBlock
{
    // 请求接收方信息...
    // 查询成功回来填充 toUserName, toUserAvatar
    WeakSelf(wself);
    NSDictionary* param = @{@"userId":self.toUserId};
    [MBProgressHUD AP_showMessage:@""];
    [[APNetworkClient sharedClient] POSTUrl:@"/user/getPhoneByUserId" parameters:param success:^(id  _Nonnull responseObject) {
        [MBProgressHUD AP_hideHUD];
//        {
//            keyId = eb163727917cbba1eea208541a643e74;
//            mobilePhone = 15180132425;
//            email =
//            sign = 93f29df303e6727718666b7467edde9b;
//            timestamp = 1566459481000;
//            token = bc962fa137de466f9eaa828dbbb223fe;
//            userId = 209;
//            version = "v1.0";
//        }
//        DLog(@"-----查询接收方手机号:%@", responseObject);
        NSString* phone = [responseObject objectForKey:@"mobilePhone"];
        NSString* email = [responseObject objectForKey:@"email"];
        if (!IsNon(phone)) {
            wself.toUserName = phone;
            if (finishedBlock) {
                finishedBlock([wself securePhone:wself.toUserName]);
            }
        }
        else if (!IsNon(email)) {
            wself.toUserName = email;
            if (finishedBlock) {
                finishedBlock(wself.toUserName);
            }
        }
    }];
    if (finishedBlock) {
        finishedBlock(self.toUserId);
    }
}


// 加载新消息
- (void) refreshMessagesOnFinished:(void (^) (NSArray* messages))finishedBlock orFailed:(void (^) (NSError* error))failedBlock
{
    [self.asyncFlag incrementFlag];
    int curFlag = self.asyncFlag.curFlag;
    
    BOOL (^ isCancelled) (void) = ^ BOOL {
        return curFlag != self.asyncFlag.curFlag;
    };
    
    WeakSelf(wself);
    NSTimeInterval fromTime = self.latestMessageTime < 0 ? self.latestMessageTime : self.latestMessageTime + 1;
    NSTimeInterval toTime = [self curTimestamp];
    [self.imCenter im_requestMessagesWithConversation:self.conversationId fromTime:fromTime toTime:toTime onFinished:^(NSArray<OTCM_message *> * _Nonnull messages) {
        if (isCancelled()) {
            return ;
        }
        NSMutableArray* rowList = @[].mutableCopy;
        // 将上次取消未回调的消息序号都打包
        if ([wself numberOfMessages] > wself.lastestMessagesCount) {
            for (NSInteger row = wself.lastestMessagesCount; row < [wself numberOfMessages]; row++) {
                [rowList addObject:@(row)];
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 填充senderAvator,name; receiverAvator, name等信息
            for (OTCM_message* message in messages) {
                if (isCancelled()) {
                    return ;
                }
                // 打印当前senderUserId的hash值
//                DLog(@"------------------消息发送人的hash值：%lu", (unsigned long)message.senderId.hash);
                // 更新最新消息的时间
                if (wself.latestMessageTime < message.timestamp) {
                    wself.latestMessageTime = message.timestamp;
                }
                // 更新最早的消息的时间
                if (wself.earlyMessageTime > message.timestamp) {
                    wself.earlyMessageTime = message.timestamp;
                }
                // 系统消息
                if ([message.senderId isEqualToString:@"0"]) {
                    // 添加流程在后面
                }
                // 我是接收人
                else if ([message.senderId isEqualToString:self.toUserId]) {
                    message.senderName = wself.toUserName;
                    message.senderAvator = wself.toUserAvatar;
                    message.receiverName = [wself mineNickName];
                    message.receiverAvator = [wself mineAvatarURL];
                    message.sendReceive = OTCMMessageSCReceive;
                }
                // 我是发送人
                else {
                    message.receiverName = wself.toUserName;
                    message.receiverAvator = wself.toUserAvatar;
                    message.senderName = [wself mineNickName];
                    message.senderAvator = [wself mineAvatarURL];
                    message.sendReceive = OTCMMessageSCSend;
                }
                NSArray* rows = [wself addMessage:message];
                [rowList addObjectsFromArray:rows];
            }
            if (isCancelled()) {
                return ;
            }
            // 在即将回调的时候更新最新的消息总数
            wself.lastestMessagesCount = [wself numberOfMessages];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (finishedBlock) {
                    finishedBlock(rowList);
                }
            });
        });
    } orFailed:failedBlock];

}
/**
 加载历史消息
 @param finishedBlock 回调:成功<加载的消息节点个数>
 @param failedBlock 回调:失败<NSError>
 */
- (void) loadHistoryMessagesOnFinished:(void (^) (NSInteger messagesCount))finishedBlock
                              orFailed:(void (^) (NSError* error))failedBlock
{
    NSTimeInterval fromTime = -1;
    NSTimeInterval toTime = self.earlyMessageTime - 1;
    WeakSelf(wself);
    [self.imCenter im_requestMessagesWithConversation:self.conversationId fromTime:fromTime toTime:toTime onFinished:^(NSArray<OTCM_message *> * _Nonnull messages) {
        __block NSInteger messagesCount = 0;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 填充senderAvator,name; receiverAvator, name等信息
            for (NSInteger i = messages.count - 1; i >= 0; i--) {
                OTCM_message* message = messages[i];
                // 更新最新消息的时间
                if (self.latestMessageTime < message.timestamp) {
                    self.latestMessageTime = message.timestamp;
                }
                // 更新最早的消息的时间
                if (self.earlyMessageTime > message.timestamp) {
                    self.earlyMessageTime = message.timestamp;
                }
                // 系统消息
                if ([message.senderId isEqualToString:@"0"]) {
                    // 添加流程在后面
                }
                // 我是接收人
                else if ([message.senderId isEqualToString:self.toUserId]) {
                    message.senderName = self.toUserName;
                    message.senderAvator = self.toUserAvatar;
                    message.receiverName = [self mineNickName];
                    message.receiverAvator = [self mineAvatarURL];
                    message.sendReceive = OTCMMessageSCReceive;
                }
                // 我是发送人
                else {
                    message.receiverName = self.toUserName;
                    message.receiverAvator = self.toUserAvatar;
                    message.senderName = [self mineNickName];
                    message.senderAvator = [self mineAvatarURL];
                    message.sendReceive = OTCMMessageSCSend;
                }
                NSInteger count = [self insertEarlyMessage:message];
                messagesCount += count;
            }
            // 在即将回调的时候更新最新的消息总数
            wself.lastestMessagesCount = [wself numberOfMessages];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (finishedBlock) {
                    finishedBlock(messagesCount);
                }
            });
        });
    } orFailed:failedBlock];
}


/**
 发送消息:文本
 @param text 要发送的文本
 @param finishedBlock 回调:成功<index新消息的序号>
 @param failedBlock 回调:失败<index新消息的序号,NSError>
 @return <NSArray:被插入的消息组的序号,因为可能插入了时间,所以返回数组>
 */
- (NSArray*) sendMessageWithText:(NSString*)text
                      onFinished:(void (^) (NSInteger index))finishedBlock
                        orFailed:(void (^) (NSInteger index, NSError* error))failedBlock
{
    self.didSendMessage = finishedBlock;
    self.didFailToSendMessage = failedBlock;
    
    // 组包消息
    OTCM_message* message = [OTCM_message new];
    message.conversationId = self.conversationId;
    message.sendReceive = OTCMMessageSCSend;
    message.messageBodyType = OTCMMessageBodyTypeText;
    message.timestamp = [self curTimestamp];
    message.senderId = [self mineUserId];
    message.senderName = [self mineNickName];
    message.isRead = YES;
    message.senderAvator = [self mineAvatarURL];
    message.receiverId = self.toUserId;
    message.receiverName = self.toUserName;
    message.receiverAvator = self.toUserAvatar;
    OTCM_messageBodyText* body = [OTCM_messageBodyText new];
    body.text = text;
    message.messageBody = body;
    // 发送到总控
    [self.imCenter im_sendMessage:message];
    // 添加消息到数据源
    NSArray* indexes = [self addMessage:message];
    // 在即将回调的时候更新最新的消息总数
    self.lastestMessagesCount = [self numberOfMessages];
    return indexes;
}



/**
 发送消息:图片
 @param image 要发送的图片
 @param finishedBlock 回调:成功<index新消息的序号>
 @param failedBlock 回调:失败<index新消息的序号,NSError>
 @return <NSArray:被插入的消息组的序号,因为可能插入了时间,所以返回数组>
 */
- (NSArray*) sendMessageWithImage:(UIImage*)image
                       onFinished:(void (^) (NSInteger index))finishedBlock
                         orFailed:(void (^) (NSInteger index, NSError* error))failedBlock
{
    self.didSendMessage = finishedBlock;
    self.didFailToSendMessage = failedBlock;

    // 这里只考虑发送成功的处理
    OTCM_message* message = [OTCM_message new];
    message.conversationId = self.conversationId;
    message.sendReceive = OTCMMessageSCSend;
    message.messageBodyType = OTCMMessageBodyTypeImage;
    message.timestamp = [self curTimestamp];
    message.senderId = [self mineUserId];
    message.senderName = [self mineNickName];
    message.isRead = YES;
    message.senderAvator = [self mineAvatarURL];
    message.receiverId = self.toUserId;
    message.receiverName = self.toUserName;
    message.receiverAvator = self.toUserAvatar;
    OTCM_messageBodyImage* body = [OTCM_messageBodyImage new];
    body.imageUrl = image;
    body.imageWidth = image.size.width;
    body.imageHeight = image.size.height;
    message.messageBody = body;
    // 发送到总控
    [self.imCenter im_sendMessage:message];
    NSArray* indexes = [self addMessage:message];
    // 在即将回调的时候更新最新的消息总数
    self.lastestMessagesCount = [self numberOfMessages];
    return indexes;
}





// 重置用户聊天的所有未读为已读
- (void) resetAllUnread {
    [self.imCenter im_resetAllUnreadForConversation:self.conversationId];
}

# pragma mark - OTCIMCenterDelegate
/**
 发送消息成功
 @param center 消息中心
 @param message 发送的消息
 */
- (void) imCenter:(OTCIMCenter*)center didSendMessage:(OTCM_message*)message {
    // 更新layout的状态
    NSInteger index = NSNotFound;
    for (OTCM_message* msg in self.messages) {
        if ([msg isKindOfClass:[OTCM_message class]] && msg.messageId == message.messageId) {
            index = [self.messages indexOfObject:msg];
            break;
        }
    }
    if (index != NSNotFound) {
        OTCM_messageLayouts* layout = [self.messageLayouts objectAtIndex:index];
        layout.status = message.status;
    }
    if (self.didSendMessage) {
        self.didSendMessage(index);
    }
}

/**
 发送消息失败
 @param center 消息中心
 @param message 发送的消息
 @param error 失败信息
 */
- (void) imCenter:(OTCIMCenter*)center didFailedToSendMessage:(OTCM_message*)message error:(NSError*)error {
    // 更新layout的状态
    NSInteger index = NSNotFound;
    for (OTCM_message* msg in self.messages) {
        if ([msg isKindOfClass:[OTCM_message class]] && msg.messageId == message.messageId) {
            index = [self.messages indexOfObject:msg];
            break;
        }
    }
    
    if (index != NSNotFound) {
        OTCM_messageLayouts* layout = [self.messageLayouts objectAtIndex:index];
        layout.status = message.status;
    }
    if (self.didFailToSendMessage) {
        self.didFailToSendMessage(index, error);
    }
}

/**
 接收到了消息
 @param center 消息中心
 @param message 接收到的消息
 */
- (void) imCenter:(OTCIMCenter*)center didReceivedMessage:(OTCM_message*)message {
    // 不是当前会话的消息不处理
    if (![message.senderId isEqualToString:self.toUserId]) {
        return;
    }
    
    if (self.didReceiveMessges) {
        self.didReceiveMessges();
    }
}


# pragma mark - tools


/**
 添加新消息;
 如果超过了提示时间5分钟，需要新增一个时间节点，并更新最新的时间节点
 @param message 新消息
 @return 新增的消息的索引数组
 */
- (NSArray* ) addMessage:(OTCM_message*)message {
    if (!message) {
        return nil;
    }
    NSMutableArray* list = @[].mutableCopy;
    NSInteger row = [self numberOfMessages];
    [list addObject:@(row)];

    // 超过5分钟的新消息要显示时间
    if (message.timestamp - self.latestRecordTimestamp > 5 * 60 * 1000) {
        // 第一次更新latestRecordTimestamp的同时更新earlyRecordTimestamp
        if (self.latestRecordTimestamp < 0) {
            self.earlyRecordTimestamp = message.timestamp;
        }
        self.latestRecordTimestamp = message.timestamp;
        NSString* timestring = [self formatedTimeStringForTimestamp:self.latestRecordTimestamp];
        [self.messages addObject:timestring];
        OTCM_timeLayouts* timeLayout = [OTCM_timeLayouts layoutWithTime:timestring];
        [self.messageLayouts addObject:timeLayout];
        [list addObject:@(row + 1)];
    }
    // 然后添加消息
    if ([message.senderId isEqualToString:@"0"]) {
        OTCM_messageSystem* system = [OTCM_messageSystem new];
        OTCM_messageBodyText* body = (OTCM_messageBodyText*)message.messageBody;
        system.content = body.text;
        OTCM_messageSystemLayouts* layouts = [OTCM_messageSystemLayouts layoutWithSystem:system];
        [self.messageLayouts addObject:layouts];
        [self.messages addObject:system];
    }
    // 正常消息
    else {
        OTCM_messageLayouts* layout = [OTCM_messageLayouts layoutWithMessage:message];
        [self.messageLayouts addObject:layout];
        [self.messages addObject:message];
    }
    if (self.latestMessageTime < message.timestamp) {
        self.latestMessageTime = message.timestamp;
    }
    return list;
}


/**
 插入历史消息
 如果消息的时间小于时间节点5分钟了，则要新增一个时间节点，并更新时间节点
 @param message 历史消息
 @return 插入的消息的个数
 */
- (NSInteger) insertEarlyMessage:(OTCM_message*)message {
    if (!message) {
        return 0;
    }
    NSInteger count = 1;
    // 添加消息
    OTCM_messageLayouts* layout = [OTCM_messageLayouts layoutWithMessage:message];
    [self.messageLayouts insertObject:layout atIndex:0];
    [self.messages insertObject:message atIndex:0];
    // 超过5分钟的新消息要显示时间
    if (self.earlyRecordTimestamp - message.timestamp > 5 * 60 * 1000) {
        self.earlyRecordTimestamp = message.timestamp;
        NSString* timestring = [self formatedTimeStringForTimestamp:self.earlyRecordTimestamp];
        [self.messages insertObject:timestring atIndex:0];
        OTCM_timeLayouts* timeLayout = [OTCM_timeLayouts layoutWithTime:timestring];
        [self.messageLayouts insertObject:timeLayout atIndex:0];
        count ++;
    }
    return count;
}

- (NSString*) formatedTimeStringForTimestamp:(NSTimeInterval)timestamp {
//    NSDateFormatter* dateFormatter = [NSDateFormatter new];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
//    return [dateFormatter stringFromDate:]; // 毫秒->秒
    return [[NSDate dateWithTimeIntervalSince1970:timestamp / 1000] jf_readableString];
}

// 获取当前系统时间戳
- (NSTimeInterval) curTimestamp {
    NSDate* date = [NSDate date];
    return [date timeIntervalSince1970] * 1000; // 单位:毫秒
}

- (NSString*) mineNickName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"phone"];
}
- (NSString*) mineUserId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
}
- (NSURL*) mineAvatarURL {
    return [NSURL URLWithString:@"我的头像链接"];
}

- (NSString*) securePhone:(NSString*)phone {
    if (phone && phone.length > 3 + 4) {
        return [phone jf_transferXingAtRange:NSMakeRange(3, 4)];
    }
    return nil;
}

# pragma mark - getter

- (NSMutableArray *)messages {
    if (!_messages) {
        _messages = @[].mutableCopy;
    }
    return _messages;
}
- (NSMutableArray *)messageLayouts {
    if (!_messageLayouts) {
        _messageLayouts = @[].mutableCopy;
    }
    return _messageLayouts;
}
# pragma mark - life cycle

/**
 初始化
 @param conversationId 会话id
 @param toUserId 对方userId
 @return 聊天页面
 */
- (instancetype)initWithConversation:(NSString*)conversationId toUser:(NSString*)toUserId {
    self = [self init];
    if (self) {
        _conversationId = conversationId;
        _toUserId = toUserId;
    }
    return self;
}



- (instancetype)init {
    self = [super init];
    if (self) {
        NSTimeInterval curTime = [self curTimestamp];
        _latestRecordTimestamp = -1;
        _latestMessageTime = -1;
        _earlyRecordTimestamp = curTime;
        _earlyMessageTime = curTime;
        _hasEarlierMessages = YES;
        _asyncFlag = [JFAsyncFlag new];
        _imCenter = [OTCIMCenter sharedCenter];
        [_imCenter addDelegate:self];
    }
    return self;
}
- (void)dealloc {
    [self.imCenter removeDelegate:self];
}

@end
