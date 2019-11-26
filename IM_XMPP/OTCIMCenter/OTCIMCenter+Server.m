//
//  OTCIMCenter+Server.m
//  ChatDemo
//
//  Created by cui on 2019/8/9.
//  Copyright © 2019 longerFeng. All rights reserved.
//

#import "OTCIMCenter.h"
#import <objc/runtime.h>

@implementation OTCIMCenter (Server) 
@dynamic xmppStream;
@dynamic xmppReconnect;
@dynamic didReceiveMessageFromServer;
@dynamic imageUploader;
@dynamic messageSendCache;

// 初始化服务器配置
- (void) initialServer {
    // 创建xmpp
    self.xmppStream = [XMPPStream new];
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    // 设置重连组件
    self.xmppReconnect = [XMPPReconnect new];
    [self.xmppReconnect activate:self.xmppStream];
}

// 清理服务器配置
- (void) releaseServer {
    [self.xmppStream removeDelegate:self];
}


// 链接服务器
- (void) connectServer {
    if (self.xmppStream.isConnected) {
        [self disconnectServer];
    }
    // 链接xmpp服务器
    XMPPJID* myJid = [XMPPJID jidWithUser:self.mineUserId domain:[self serverHost] resource:nil];
    [self IMServerLog:[NSString stringWithFormat:@"正在链接XMPP服务器[%@:%d], userId[%@],password[%@]", [self serverHost],[self serverPort], myJid.bare,self.minePassword]];
    
    self.xmppStream.myJID = myJid;
    self.xmppStream.hostName = [self serverHost];
    self.xmppStream.hostPort = [self serverPort];
    
    NSError* error = nil;
    if (![self.xmppStream connectWithTimeout:15 error:&error]) {
        [self IMServerLog:[NSString stringWithFormat:@"链接XMPP服务器失败:[%@]", error]];
    } else {
        [self IMServerLog:@"连接xmpp服务器成功"];

    }
}
// 断开服务器链接
- (void) disconnectServer {
    // 断开xmpp服务器
    [self offline];
    [self.xmppStream disconnectAfterSending];
}

// 发送消息到服务器
- (void) sendMessageToServer:(OTCM_message *)message
{
    WeakSelf(wself);
    if (!message) {
        return;
    }
    // 先添加到缓存;发送完毕就删除
    [self messageSendCacheAddMessage:message];
    
    // 文本消息:直接打包并发送
    if (message.messageBodyType == OTCMMessageBodyTypeText) {
        // 打包
        XMPPElement* xmppMessage = [self packXMPPMessage:message];
        if (xmppMessage) {
            // 发送消息
            [self.xmppStream sendElement:xmppMessage];
            [self IMServerLog:[NSString stringWithFormat:@"xmppStream开始发送[%@]消息:[%lld]", message.receiverId, message.messageId]];
        }
    }
    // 图片消息:先上传图片到服务器，然后回来打包并发送
    else if (message.messageBodyType == OTCMMessageBodyTypeImage) {
        NSString* messageId = [NSString stringWithFormat:@"%lld", message.messageId];
        OTCM_messageBodyImage* body = (OTCM_messageBodyImage*)message.messageBody;
        [self.imageUploader uploadIMImage:(UIImage*)body.imageUrl success:^(NSString*  _Nonnull imageUrl) {
            body.imageUrl = imageUrl;
            // 打包
            XMPPElement* xmppMessage = [wself packXMPPMessage:message];
            if (xmppMessage) {
                // 发送消息
                [wself.xmppStream sendElement:xmppMessage];
                [self IMServerLog:[NSString stringWithFormat:@"xmppStream开始发送[%@]消息:[%lld]", message.receiverId, message.messageId]];
            }
        } failure:^(id  _Nonnull responseObject) {
            // 调用上层处理
            dispatch_async(dispatch_get_main_queue(), ^{
                [wself __didFailToSendMessage:[wself messageInCacheWithId:messageId] error:[NSError jf_errorWithCode:99 localizedDescription:@"上传图片失败"]];
                // 移除消息缓存
                [wself messageSendCacheDelMessageWithId:messageId];
            });
        } serverFailure:^{
            // 调用上层处理
            dispatch_async(dispatch_get_main_queue(), ^{
                [wself __didFailToSendMessage:[wself messageInCacheWithId:messageId] error:[NSError jf_errorWithCode:99 localizedDescription:@"上传图片失败"]];
                // 移除消息缓存
                [wself messageSendCacheDelMessageWithId:messageId];
            });
        }];
    }
    
    
}


# pragma mark - 上下线
- (void) online {
    if (self.xmppStream && self.xmppStream.isConnected) {
        XMPPPresence* presence = [XMPPPresence presenceWithType:@"available"];
        [self.xmppStream sendElement:presence];
    }
}
- (void) offline {
    if (self.xmppStream && self.xmppStream.isConnected) {
        XMPPPresence* presence = [XMPPPresence presenceWithType:@"unavailable"];
        [self.xmppStream sendElement:presence];
    }
}

# pragma mark - XMPPStreamDelegate


// 已与xmpp服务器建立连接
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    //  验证密码
    [self IMServerLog:@"xmpp服务器已经建立连接，正在登陆.."];
    NSError* error = nil;
    if (![sender authenticateWithPassword:self.minePassword error:&error]) {
        [self IMServerLog:[NSString stringWithFormat:@"xmpp验证密码失败:[%@]", error]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __didFailToConnectServer:error];
        });
    }
}

// 与服务器断开链接
- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender {
    [self IMServerLog:@"与xmpp服务器断开链接"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self __didFailToConnectServer:[NSError jf_errorWithCode:99 localizedDescription:@"与服务器断开链接"]];
    });
}
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(nullable NSError *)error {
    [self IMServerLog:[NSString stringWithFormat:@"######:xmppStreamDidDisconnect:%@", error]];
}
- (void)xmppStreamWasToldToAbortConnect:(XMPPStream *)sender {
    [self IMServerLog:@"######:xmppStreamWasToldToAbortConnect"];
}
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender {
    [self IMServerLog:@"######:xmppStreamConnectDidTimeout"];
}
- (void)xmppStreamDidSendClosingStreamStanza:(XMPPStream *)sender {
    [self IMServerLog:@"######:xmppStreamDidSendClosingStreamStanza"];
}



// xmpp验证密码结果:失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    [self IMServerLog:[NSString stringWithFormat:@"xmpp验证失败:[%@]", error]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self __didFailToConnectServer:[NSError jf_errorWithCode:99 localizedDescription:@"验证密码失败"]];
    });
}
// xmpp验证密码结果:成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    [self IMServerLog:@"xmpp验证成功"];
    [self online];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self __didConnectServer];
    });
}

// 发送结果:成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(nonnull XMPPMessage *)message {
    [self IMServerLog:[NSString stringWithFormat:@"xmpp发送消息成功:[%@]", message.elementID]];
    NSString* type = [message attributeStringValueForName:@"type"];
    if ([type isEqualToString:@"chat"]) {
        // 调用上层处理
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __didSucToSendMessage:[self messageInCacheWithId:message.elementID]];
            // 移除消息缓存
            [self messageSendCacheDelMessageWithId:message.elementID];
        });
    }
    
}
// 发送结果:失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(nonnull XMPPMessage *)imMessage error:(nonnull NSError *)error {
    [self IMServerLog:[NSString stringWithFormat:@"发送消息失败:[%@]", error]];
    NSString* type = [imMessage attributeStringValueForName:@"type"];
    if ([type isEqualToString:@"chat"]) {
        // 调用上层处理
        dispatch_async(dispatch_get_main_queue(), ^{
            OTCM_message* message = [self messageInCacheWithId:imMessage.elementID];
            [self __didFailToSendMessage:message error:error];
            // 移除消息缓存
            [self messageSendCacheDelMessageWithId:imMessage.elementID];
        });
    }

}
// 接收到消息
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    [self IMServerLog:[NSString stringWithFormat:@"xmpp接收到消息:[%@]", message]];
    OTCM_message* imMessage = [self unpackXMPPMessage:message];
    // 拆包成功
    if (imMessage) {
        // 调用上层处理
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __didReceiveMessage:imMessage];
        });
    }
}


# pragma mark - tools

- (XMPPElement*) packXMPPMessage:(OTCM_message*)message {
    if (!message) {
        return nil;
    }
    // 消息节点
    XMPPElement* xmppMessage = [XMPPElement elementWithName:@"message"];
    [xmppMessage addAttributeWithName:@"type" stringValue:@"chat"];
    NSString* from = [NSString stringWithFormat:@"%@@%@", message.senderId, [self serverHost]];
    NSString* to = [NSString stringWithFormat:@"%@@%@", message.receiverId, [self serverHost]];
    NSString* messageId = [NSString stringWithFormat:@"%lld", message.messageId];
    [xmppMessage addAttributeWithName:@"from" stringValue:from];
    [xmppMessage addAttributeWithName:@"to" stringValue:to];
    [xmppMessage addAttributeWithName:@"id" stringValue:messageId];
    // 子节点-orderId
    XMPPElement* orderId = [XMPPElement elementWithName:@"orderId"];
    [orderId setStringValue:message.conversationId];
    [xmppMessage addChild:orderId];
    // 子节点-typeId消息类型
    XMPPElement* typeId = [XMPPElement elementWithName:@"typeId"];
    [typeId setStringValue:[NSString stringWithFormat:@"%ld", (long)message.messageBodyType]];
    [xmppMessage addChild:typeId];

    if (message.messageBodyType == OTCMMessageBodyTypeText) {
        OTCM_messageBodyText* messageBody = (OTCM_messageBodyText*)message.messageBody;
        // 子节点-body
        XMPPElement* body = [XMPPElement elementWithName:@"body"];
        [body setStringValue:messageBody.text];
        [xmppMessage addChild:body];
    }
    else if (message.messageBodyType == OTCMMessageBodyTypeImage) {
        OTCM_messageBodyImage* messageBody = (OTCM_messageBodyImage*)message.messageBody;
        // 子节点-body
        XMPPElement* body = [XMPPElement elementWithName:@"body"];
        [body setStringValue:messageBody.imageUrl];
        [xmppMessage addChild:body];
        // 子节点-width
        XMPPElement* width = [XMPPElement elementWithName:@"width"];
        [width setStringValue:[NSString stringWithFormat:@"%lf", messageBody.imageWidth]];
        [xmppMessage addChild:width];
        // 子节点-height
        XMPPElement* height = [XMPPElement elementWithName:@"height"];
        [height setStringValue:[NSString stringWithFormat:@"%lf", messageBody.imageHeight]];
        [xmppMessage addChild:height];
    }
    return xmppMessage;
}
- (OTCM_message*) unpackXMPPMessage:(XMPPElement*)message {
    if (!message) {
        return nil;
    }
    NSString* type = [message attributeStringValueForName:@"type"];
    // 确定是聊天消息才拆包
    OTCM_message* msg = nil;
    if ([type isEqualToString:@"chat"]) {
        NSString* from = message.from.user;
        NSString* to = message.to.user;
        XMPPElement* body = (XMPPElement*)[message elementForName:@"body"];
        XMPPElement* orderId = (XMPPElement*)[message elementForName:@"orderId"];
        XMPPElement* typeId = (XMPPElement*)[message elementForName:@"typeId"];
        // 创建业务上的消息对象
        msg = [OTCM_message new];
        //        msg.sendReceive
        msg.timestamp = [self __curTimestamp];
        msg.senderId = from;
        msg.receiverId = to;
        msg.conversationId = [orderId stringValue];
        msg.sendReceive = OTCMMessageSCReceive;
        msg.messageBodyType = [typeId.stringValue intValue];
        // 拆包:文本
        if (msg.messageBodyType == OTCMMessageBodyTypeText) {
            OTCM_messageBodyText* messageBody = [OTCM_messageBodyText new];
            messageBody.text = [body stringValue];
            msg.messageBody = messageBody;
        }
        // 拆包:图片
        else if (msg.messageBodyType == OTCMMessageBodyTypeImage) {
            OTCM_messageBodyImage* messageBody = [OTCM_messageBodyImage new];
            messageBody.imageUrl = body.stringValue;
            XMPPElement* width = (XMPPElement*)[message elementForName:@"width"];
            if (width) {
                messageBody.imageWidth = [width.stringValue doubleValue];
            }
            XMPPElement* height = (XMPPElement*)[message elementForName:@"height"];
            if (height) {
                messageBody.imageHeight = [height.stringValue doubleValue];
            }
            msg.messageBody = messageBody;
        }
    }
    // 发送失败:可能是对方不在线??503错误
    else if ([type isEqualToString:@"error"]) {
        // 移除消息缓存
        [self messageSendCacheDelMessageWithId:message.elementID];
    }
    return msg;
}

- (NSString*) serverHost {
    // @"http://192.168.1.120:8889"
    NSRange httpRange = [APNetworkClientAPIBaseURLString rangeOfString:@"http://"];
    NSString* ip = [APNetworkClientAPIBaseURLString substringFromIndex:httpRange.location + httpRange.length];
    NSRange portRange = [ip rangeOfString:@":"];
    ip = [ip substringToIndex:portRange.location];
    return ip;
}
- (int16_t) serverPort {
    return 5222;
}

- (OTCM_message*)messageInCacheWithId:(NSString*)messageId {
    if (IsNon(messageId)) {
        return nil;
    }
    for (OTCM_message* message in self.messageSendCache) {
        if (message.messageId == messageId.integerValue) {
            return message;
        }
    }
    return nil;
}
- (void) messageSendCacheAddMessage:(OTCM_message*)message {
    [self.messageSendCache addObject:message];
}
- (void) messageSendCacheDelMessageWithId:(NSString*)messageId {
    if (IsNon(messageId)) {
        return;
    }
    for (OTCM_message* message in self.messageSendCache) {
        if (message.messageId == messageId.integerValue) {
            [self.messageSendCache removeObject:message];
            return;
        }
    }
}

- (void) IMServerLog:(NSString*)logStr {
#ifdef DEBUG
    NSMutableString* log = [NSMutableString string];
    [log appendString:@"\n\n----------IM::XMPP---------\n"];
    [log appendString:logStr];
    [log appendString:@"\n---------------------------\n\n"];
//    DLog(@"%@", log);
#endif
}


# pragma mark - getter|setter

//@dynamic xmppStream;
//@dynamic xmppReconnect;
//@dynamic didReceiveMessageFromServer;

- (XMPPStream*) xmppStream {
    XMPPStream* __xmppStream = objc_getAssociatedObject(self, "kXmppStreamKey");
    if (!__xmppStream) {
        __xmppStream = [XMPPStream new];
        objc_setAssociatedObject(self, "kXmppStreamKey", __xmppStream, OBJC_ASSOCIATION_RETAIN);
    }
    return __xmppStream;
}
- (void)setXmppStream:(XMPPStream *)xmppStream {
    if (xmppStream) {
        objc_setAssociatedObject(self, "kXmppStreamKey", xmppStream, OBJC_ASSOCIATION_RETAIN);
    } else {
        objc_setAssociatedObject(self, "kXmppStreamKey", nil, OBJC_ASSOCIATION_RETAIN);
    }
}

- (XMPPReconnect *)xmppReconnect {
    XMPPReconnect* __xmppReconnect = objc_getAssociatedObject(self, "kXmppReconnectKey");
    if (!__xmppReconnect) {
        __xmppReconnect = [XMPPReconnect new];
        objc_setAssociatedObject(self, "kXmppReconnectKey", __xmppReconnect, OBJC_ASSOCIATION_RETAIN);
    }
    return __xmppReconnect;
}
- (void)setXmppReconnect:(XMPPReconnect *)xmppReconnect {
    objc_setAssociatedObject(self, "kXmppReconnectKey", xmppReconnect, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableArray<OTCM_message *> *)messageSendCache {
    NSMutableArray<OTCM_message *>* __cache = objc_getAssociatedObject(self, "kMessageSendCacheKey");
    if (!__cache) {
        __cache = @[].mutableCopy;
        objc_setAssociatedObject(self, "kMessageSendCacheKey", __cache, OBJC_ASSOCIATION_RETAIN);

    }
    return __cache;
}

- (void (^)(OTCM_message * _Nonnull))didReceiveMessageFromServer {
    void (^ __didReceiveMessageFromServer) (OTCM_message * _Nonnull message) = objc_getAssociatedObject(self, "kDidReceiveMessageFromServer");
    return __didReceiveMessageFromServer;
}
- (void)setDidReceiveMessageFromServer:(void (^)(OTCM_message * _Nonnull))didReceiveMessageFromServer {
    objc_setAssociatedObject(self, "kDidReceiveMessageFromServer", didReceiveMessageFromServer, OBJC_ASSOCIATION_COPY);
}
- (APOTCUpLoadImageLogic *)imageUploader {
    APOTCUpLoadImageLogic* __imageUploader = objc_getAssociatedObject(self, "kImageLoaderKey");
    if (!__imageUploader) {
        __imageUploader = [[APOTCUpLoadImageLogic alloc] init];
        __imageUploader.fileType = @"1"; // fileType
        objc_setAssociatedObject(self, "kImageLoaderKey", __imageUploader, OBJC_ASSOCIATION_RETAIN);
    }
    return __imageUploader;
}


@end
