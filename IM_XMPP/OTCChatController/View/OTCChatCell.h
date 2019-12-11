//
//  OTCChatCell.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTCM_messageLayouts.h"

NS_ASSUME_NONNULL_BEGIN


@class OTCChatCell;
@protocol OTCChatCellDelegate <NSObject>

// 点击了头像
- (void) didClickedAvatorInchatCell:(OTCChatCell*)cell;
// 点击了正文图片
- (void) didClickedImageInchatCell:(OTCChatCell*)cell;
// 点击了正文
- (void) didClickedContentTextInchatCell:(OTCChatCell*)cell;
// 长按了正文
- (void) didLongpressedContentTextInchatCell:(OTCChatCell*)cell;
// 点击了重发图片
- (void) didClickedResendInchatCell:(OTCChatCell*)cell;

@end


@interface OTCChatCell : UITableViewCell

// 布局对象
@property (nonatomic, strong) OTCM_messageLayouts* layouts;
// 代理
@property (nonatomic, weak) id<OTCChatCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
