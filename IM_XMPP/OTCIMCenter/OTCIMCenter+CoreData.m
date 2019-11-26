//
//  OTCIMCenter+CoreData.m
//  ChatDemo
//
//  Created by cui on 2019/8/9.
//  Copyright © 2019 longerFeng. All rights reserved.
//

#import "OTCIMCenter.h"
#import <objc/runtime.h>

// sqlite数据文件名
static NSString* const OTCIMDBFileName = @"IMMessage.db";
// 消息表的表名称前缀;后面加上当前用户的userID;每个账号对应一个表
static NSString* const OTCIMDBNamePre = @"IMTB_";
// 目前可以预估的就只存放图片和视频
static NSString* const OTCIMFileDir = @"IMFiles";

static sqlite3* database;


@implementation OTCIMCenter (CoreData)
@dynamic dbReadQueue;
@dynamic dbWriteQueue;

// 初始化DB
- (void) initialDB {
    [self createDBIfNeeded];
}
// 关闭DB
- (void) closeDB {
    dispatch_async(self.dbWriteQueue, ^{
        if (sqlite3_close_v2(database) != SQLITE_OK) {
//            DLog(@"\n---------------关闭数据库失败::%s\n-----------\n", sqlite3_errmsg(database));
        }
        else {
//            DLog(@"\n---------------关闭数据库成功\n-----------\n");
        }
        database = nil;
    });
}


// 插入新消息到DB
- (void) insertDBWithMessage:(OTCM_message*)message
                  onFinished:(void (^) (void))finishedBlock
                    orFailed:(void (^) (NSError* error))failedBlock
{
    dispatch_async(self.dbWriteQueue, ^{
        // 准备插入sql
        NSMutableString* insertSQL = [NSMutableString stringWithFormat:@"INSERT INTO %@ ", self.dbName];
        [insertSQL appendString:@"(createTime,messageId,sendUserId,receiveUserId,messageStatus,conversationId,isRead,messageType,messageContent) VALUES  "];
        [insertSQL appendString:@"("];
        [insertSQL appendFormat:@"%lf,", message.timestamp];
        [insertSQL appendFormat:@"%lld,", message.messageId];
        [insertSQL appendFormat:@"'%@',", message.senderId];
        [insertSQL appendFormat:@"'%@',", message.receiverId];
        [insertSQL appendFormat:@"%ld,", message.status];
        [insertSQL appendFormat:@"'%@',", message.conversationId];
        [insertSQL appendFormat:@"%d,", message.isRead];
        [insertSQL appendFormat:@"%ld,", message.messageBodyType];
        [insertSQL appendFormat:@"'%@'", [self getContentFromMessage:message]];
        [insertSQL appendString:@");"];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", insertSQL);
        // 执行插入
        char* errmsg;
        if (sqlite3_exec(database, insertSQL.UTF8String, NULL, NULL, &errmsg) == SQLITE_OK) {
            
//            DLog(@"::IMCenter::插入数据成功:[%lld], timestamp[%lf], errmsg:%s\n", message.messageId, message.timestamp, errmsg);
            if (finishedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finishedBlock();
                });
            }
        }
        else {
//            DLog(@"::IMCenter::插入数据失败:%@", [NSString stringWithUTF8String:errmsg]);
            if (failedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failedBlock([NSError jf_errorWithCode:99 localizedDescription:[self stringWithCharString:errmsg]]);
                });
            }
            sqlite3_free(errmsg);
        }
    });
}

/**
 更新消息的状态
 @param message 消息
 */
- (void) updateMessage:(OTCM_message*)message
            onFinished:(void (^) (void))finishedBlock
              orFailed:(void (^) (NSError* error))failedBlock
{
    dispatch_async(self.dbWriteQueue, ^{
        // 准备插入sql
        NSMutableString* insertSQL = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", self.dbName];
        [insertSQL appendFormat:@" createTime = %lf,", message.timestamp];
        [insertSQL appendFormat:@" messageStatus = %ld, ", message.status];
        [insertSQL appendFormat:@" isRead = %d, ", message.isRead];
        [insertSQL appendFormat:@" messageContent = \"%@\" ", [self getContentFromMessage:message]];
        [insertSQL appendFormat:@" WHERE messageId = %lld;", message.messageId];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", insertSQL);
        // 执行更新
        char* errmsg;
        if (sqlite3_exec(database, insertSQL.UTF8String, NULL, NULL, &errmsg) == SQLITE_OK) {
//            DLog(@"::IMCenter::更新数据成功:[%lld], timestamp[%lf]", message.messageId, message.timestamp);
            if (finishedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finishedBlock();
                });
            }
        }
        else {
//            DLog(@"::IMCenter::更新数据失败:%@", [NSString stringWithUTF8String:errmsg]);
            if (failedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failedBlock([NSError jf_errorWithCode:99 localizedDescription:[self stringWithCharString:errmsg]]);
                });
            }
            sqlite3_free(errmsg);
        }
    });
}



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
                                orFailed:(void (^) (NSError* error))failedBlock
{
    WeakSelf(wself);
    dispatch_async(self.dbReadQueue, ^{
        NSMutableString* selectSQL = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE conversationId = '%@'", self.dbName, conversationId];
        // 区间: startTime - toTime
        if (fromTime > 0 && toTime > 0) {
            [selectSQL appendFormat:@" AND createTime BETWEEN %lf AND %lf ORDER BY createTime DESC", fromTime, toTime];
        }
        // 区间: 最早 - toTime
        else if (fromTime < 0) {
            [selectSQL appendFormat:@" AND createTime <= %lf ORDER BY createTime DESC", toTime];
        }
        // 区间: fromTime - 现在
        else if (toTime < 0) {
            [selectSQL appendFormat:@" AND createTime >= %lf ORDER BY createTime ASC", fromTime];
        }
        [selectSQL appendString:@";"];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", selectSQL);

        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, selectSQL.UTF8String, -1, &statement, NULL) == SQLITE_OK) {
            NSMutableArray* messages = @[].mutableCopy;
            while (sqlite3_step(statement) == SQLITE_ROW) {
                OTCM_message* msg = [OTCM_message new];
                msg.messageId = sqlite3_column_int64(statement, 0);
                msg.conversationId = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 1)];
                msg.messageBodyType = sqlite3_column_int(statement, 2);
                char* content = (char*)sqlite3_column_text(statement, 3);
                if (content != NULL && strlen(content) > 0) {
                    NSString* msgContent = [NSString stringWithUTF8String:content];
                    // 文本消息内容
                    if (msg.messageBodyType == OTCMMessageBodyTypeText) {
                        OTCM_messageBodyText* body = [OTCM_messageBodyText new];
                        body.text = msgContent;
                        msg.messageBody = body;
                    }
                    // 图片内容格式: imageUrl,width,height
                    else if (msg.messageBodyType == OTCMMessageBodyTypeImage) {
                        NSArray* items = [msgContent componentsSeparatedByString:@","];
                        OTCM_messageBodyImage* body = [OTCM_messageBodyImage new];
                        if (!IsNon(items) && items.count == 3) {
                            body.imageUrl = items[0];
                            body.imageWidth = [items[1] doubleValue];
                            body.imageHeight = [items[2] doubleValue];
                        }
                        msg.messageBody = body;
                    }
                }
                msg.receiverId = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 4)];
                msg.senderId = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 5)];
                msg.sendReceive = [msg.senderId isEqualToString:wself.mineUserId] ? OTCMMessageSCSend : OTCMMessageSCReceive;
                msg.isRead = sqlite3_column_int(statement, 6);
                msg.status = sqlite3_column_int(statement, 7);
                msg.timestamp = sqlite3_column_double(statement, 8);
                [messages addObject:msg];
                // 一次最多返回20条
                if (messages.count >= 20) {
                    break;
                }
            }
            // 最终的结果还是升序返回给外部
            [messages sortUsingComparator:^NSComparisonResult(OTCM_message*  _Nonnull obj1, OTCM_message*  _Nonnull obj2) {
                return [@(obj1.timestamp) compare:@(obj2.timestamp)];
            }];
            
            if (finishedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finishedBlock(messages);
                });
            }
        }
        else {
            const char* msg = sqlite3_errmsg(database);
//            DLog(@"::IMCenter::查询数据失败:%@", [NSString stringWithUTF8String:msg]);
            if (failedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"查询数据库失败", nil)]);
                });
            }
        }
    });
}

/**
 查询会话列表
 @param finishedBlock 回调:成功<NSArray<OTCM_conversation*>>
 @param failedBlock 回调:失败<NSError>
 */
- (void) requestConversationsOnFinished:(void (^) (NSArray<OTCM_conversation*>* conversations))finishedBlock
                               orFailed:(void (^) (NSError* error))failedBlock
{
    WeakSelf(wself);
    dispatch_async(self.dbReadQueue, ^{
        NSString* sqlConvList = [NSString stringWithFormat:@"SELECT DISTINCT conversationId FROM %@;", self.dbName];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", sqlConvList);
        // 然后针对每个会话查询它的最新的消息,以及它的未读数个数
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, sqlConvList.UTF8String, -1, &statement, NULL) == SQLITE_OK) {
            NSMutableArray* conversations = @[].mutableCopy;
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const unsigned char* convId = sqlite3_column_text(statement, 0);
                if (convId != NULL && strlen((const char *)convId) > 0) {
                    OTCM_conversation* conv = [OTCM_conversation new];
                    conv.conversationId = [NSString stringWithUTF8String:(const char *)convId];
                    [conversations addObject:conv];
                }
            }
            // 分别查询每个会话的未读数,最后一条消息
            dispatch_group_t group = dispatch_group_create();
            for (OTCM_conversation* conversation in conversations) {
                // 查询未读数
                dispatch_group_enter(group);
                [wself getUnreadCountForConversation:conversation.conversationId onFinished:^(NSInteger count) {
                    conversation.unreadMessagesCount = count;
                    dispatch_group_leave(group);
                }];
                // 查询最后一条消息
                dispatch_group_enter(group);
                [wself requestMessagesWithConversation:conversation.conversationId fromTime:-1 toTime:[wself __curTimestamp] onFinished:^(NSArray<OTCM_message *> * _Nonnull messages) {
                    if (!IsNon(messages)) {
                        // 降序排序
                        NSArray* list = [messages sortedArrayUsingComparator:^NSComparisonResult(OTCM_message*  _Nonnull obj1, OTCM_message*  _Nonnull obj2) {
                            return [@(obj2.timestamp) compare:@(obj1.timestamp)];
                        }];
                        conversation.latestMessage = list.firstObject;
                    }
                    dispatch_group_leave(group);
                } orFailed:^(NSError * _Nonnull error) {
                    dispatch_group_leave(group);
                }];
            }
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                // 将会话列表以最后一条消息的时间戳的降序来排序
                [conversations sortUsingComparator:^NSComparisonResult(OTCM_conversation*  _Nonnull obj1, OTCM_conversation*  _Nonnull obj2) {
                    if (!obj1.latestMessage) {
                        return NSOrderedDescending;
                    }
                    else if (!obj2.latestMessage) {
                        return NSOrderedAscending;
                    }
                    return [@(obj2.latestMessage.timestamp) compare:@(obj1.latestMessage.timestamp)];
                }];
                if (finishedBlock) {
                    finishedBlock(conversations);
                }
            });
        }
        else {
            const char* msg = sqlite3_errmsg(database);
//            DLog(@"::IMCenter::查询会话列表失败:%@", [NSString stringWithUTF8String:msg]);
            if (failedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failedBlock([NSError jf_errorWithCode:99 localizedDescription:NSLocalizedString(@"查询会话列表失败", nil)]);
                });
            }
        }
    });
    
}


// 查询指定会话的未读消息的个数
- (void) getUnreadCountForConversation:(NSString*)conversationId onFinished:(void (^) (NSInteger count))finishedBlock
{
    dispatch_async(self.dbReadQueue, ^{
        NSString* selectSQL = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE conversationId = '%@' AND isRead = %d;", self.dbName, conversationId, false];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", selectSQL);
        NSInteger count = 0;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, selectSQL.UTF8String, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                count = sqlite3_column_int(statement, 0);
            }
        }
        else {
            const char* msg = sqlite3_errmsg(database);
//            DLog(@"::IMCenter::查询[%@]未读数失败:%@", conversationId,[NSString stringWithUTF8String:msg]);
        }
        if (finishedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishedBlock(count);
            });
        }
    });
}

// 重置指定会话的所有未读为已读
- (void) resetAllUnreadForConversation:(NSString*)conversationId {
    dispatch_async(self.dbWriteQueue, ^{
        // 准备插入sql
        NSMutableString* insertSQL = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", self.dbName];
        [insertSQL appendFormat:@" isRead = %d ", true];
        [insertSQL appendFormat:@" WHERE conversationId = '%@' AND isRead = %d;", conversationId, false];
//        DLog(@"\n-----SQL语句::\n%@\n-------\n", insertSQL);
        // 执行更新
        char* errmsg;
        if (sqlite3_exec(database, insertSQL.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
//            DLog(@"::IMCenter::更新数据失败:%s\n", errmsg);
        }
        sqlite3_free(errmsg);
    });
}


# pragma mark - tools



// 从消息中取出消息内容,要转换成string
- (NSString*) getContentFromMessage:(OTCM_message*) message {
    if (message.messageBodyType == OTCMMessageBodyTypeText) {
        OTCM_messageBodyText* body = (OTCM_messageBodyText*)message.messageBody;
        return body.text;
    }
    else if (message.messageBodyType == OTCMMessageBodyTypeImage) {
        OTCM_messageBodyImage* body = (OTCM_messageBodyImage*)message.messageBody;
        NSMutableString* imageContent = [NSMutableString string];
        // 如果是UIImage表示要缓存到本地，并将url返回用于DB
        if ([body.imageUrl isKindOfClass:[UIImage class]]) {
            NSString* imageUrl = [self imageSavedInLocal:(UIImage*)body.imageUrl];
            // 给本地相对路径添加一个自定义的前缀；方便取DB的时候识别是本地还是网络图片
            [imageContent appendFormat:@"%@%@", kOTCLocalImagePre, imageUrl];
        }
        else if ([body.imageUrl isKindOfClass:[NSString class]]) {
            [imageContent appendString:body.imageUrl];
        }
        else {
            return nil;
        }
        // 添加宽高
        [imageContent appendFormat:@",%d", (int)floor(body.imageWidth)];
        [imageContent appendFormat:@",%d", (int)floor(body.imageHeight)];
        return [imageContent copy];
    }
    else {
        return nil;
    }
}

// 保存图片到本地;返回图片的地址(仅返回documents后面的相对路径)
- (NSString*) imageSavedInLocal:(UIImage*)image {
    if (!image || ![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentDir = [dirs lastObject];
    NSString* imageDir = [documentDir stringByAppendingPathComponent:OTCIMFileDir];
    NSFileManager* fileMan = [NSFileManager defaultManager];
    if (![fileMan fileExistsAtPath:imageDir]) {
//        DLog(@"-=-=-=-=-=没有文件目录，正在创建");
        NSError* error = nil;
        [fileMan createDirectoryAtPath:imageDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
//            DLog(@"---------创建目录[%@]失败:[%@]", imageDir,error);
            abort();
        }
        else {
//            DLog(@"---------创建目录成功");
        }
    }
    else {
//        DLog(@"-=-=-=-=-=文件目录已存在");
    }
    // 生成图片在本地的路径
    NSDateFormatter* dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"YYYYMMddHHmmss"];
    NSString* date = [dateFormat stringFromDate:[NSDate date]];
    NSString* imageName = [NSString stringWithFormat:@"%@/%@.jpeg", imageDir, date];
    // 保存图片到本地
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* imageData = UIImageJPEGRepresentation(image, 0.6);
        BOOL isWrote = [imageData writeToFile:imageName atomically:YES];
//        DLog(@"---------图片保存到[%@]%@", imageName, isWrote ? @"成功":@"失败" );
    });
    //仅返回documents后面的相对路径
    return [imageName substringFromIndex:[imageName rangeOfString:OTCIMFileDir].location];
}

// 创建DB
- (void) createDBIfNeeded {
    // 异步创建DB
    dispatch_async(self.dbWriteQueue, ^{
        NSString* documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString* databaseName = [documentDir stringByAppendingPathComponent:OTCIMDBFileName];
        // 打开数据库(如果没有文件会创建文件)
        int result = sqlite3_open_v2(databaseName.UTF8String, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL);
        if (result != SQLITE_OK) {
            NSAssert(YES, @"打开数据库失败");
            return;
        }
        char *errmsg;

        if (sqlite3_exec(database, "PRAGMA journal_mode=WAL;", NULL, NULL, &errmsg) == SQLITE_OK) {
            DLog(@"::IMCenter::设置WAL成功");
        }
        else {
            DLog(@"::IMCenter::设置WAL失败:%s\n", errmsg);
        }
        
        NSMutableString* sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ", self.dbName];
        [sql appendString:@"("];
        [sql appendString:@"messageId INTEGER PRIMARY KEY, "];      // messageId消息id int64_t
        [sql appendString:@"conversationId TEXT, "];                // 会话id(当前业务定为订单号)
        [sql appendString:@"messageType INTEGER, "];                // 消息类型:OTCMMessageBodyType
        [sql appendString:@"messageContent TEXT, "];                // 消息内容
        [sql appendString:@"receiveUserId TEXT, "];                 // 接收人userID
        [sql appendString:@"sendUserId TEXT, "];                    // 发送人userID
        [sql appendString:@"isRead BOOLEAN, "];                     // 是否已读
        [sql appendString:@"messageStatus INTEGER, "];              // 消息状态:OTCMMessageStatus
        [sql appendString:@"createTime TIMESTAMP, "];               // 时间戳; 单位:毫秒
        [sql appendString:@"desc TEXT "];                           // 描述
        [sql appendString:@");"];
        // 创建表(如果表存在则不会创建)
        if (sqlite3_exec(database, sql.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
            sqlite3_close_v2(database);
            NSAssert(YES, ([NSString stringWithFormat:@"创建表失败:%s\n", errmsg]));
            sqlite3_free(errmsg);
            return;
        }
        DLog(@"::IMCenter::创建表成功");
    });
}


- (NSString*) stringWithCharString:(char*)charString {
    if (charString != NULL && strlen(charString) > 0) {
        return [NSString stringWithUTF8String:charString];
    }
    return @"";
}

# pragma mark - getter|setter


- (dispatch_queue_t)dbReadQueue {
    dispatch_queue_t queue = objc_getAssociatedObject(self, "kDBReadQueueKey");
    if (!queue) {
        queue = dispatch_queue_create("com.IMDBQueue.read", DISPATCH_QUEUE_CONCURRENT);
        objc_setAssociatedObject(self, "kDBReadQueueKey", queue, OBJC_ASSOCIATION_RETAIN);
    }
    return queue;
}
- (dispatch_queue_t)dbWriteQueue {
    dispatch_queue_t queue = objc_getAssociatedObject(self, "kDBWriteQueueKey");
    if (!queue) {
        queue = dispatch_queue_create("com.IMDBQueue.write", DISPATCH_QUEUE_SERIAL);
        objc_setAssociatedObject(self, "kDBWriteQueueKey", queue, OBJC_ASSOCIATION_RETAIN);
    }
    return queue;
}

- (int)mainkey {
    return [objc_getAssociatedObject(self, "kMainKeyKey") intValue];
}
- (void)setMainkey:(int)mainkey {
    objc_setAssociatedObject(self, "kMainKeyKey", @(mainkey), OBJC_ASSOCIATION_RETAIN);
}

- (NSString*) dbName {
    NSString* mineUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    NSString* name = [OTCIMDBNamePre stringByAppendingString:mineUserId];
    return name;
}

@end
