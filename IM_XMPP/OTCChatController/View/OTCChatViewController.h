//
//  OTCChatViewController.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OTCChatViewController : UIViewController


/**
 初始化
 @param conversationId 会话id
 @param toUserId 对方userId
 @return 聊天页面
 */
- (instancetype)initWithConversation:(NSString*)conversationId toUser:(NSString*)toUserId;

@property (nonatomic, copy) NSString* conversationId;
@property (nonatomic, copy) NSString* toUserId;
//@property (nonatomic, copy) NSString *accountName;

@end

NS_ASSUME_NONNULL_END
