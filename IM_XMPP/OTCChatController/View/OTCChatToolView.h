//
//  OTCChatToolView.h
//  ChatDemo
//
//  Created by cui on 2019/8/8.
//  Copyright © 2019 longerFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface OTCChatToolView : UIView

+ (CGFloat) viewHeight;


/**
 * 点击了选项的回调;
 * itemName: 选项的名称<kOTCChatToolItemNameXXX>
 */
@property (nonatomic, copy) void (^ didSelectedMenuItem) (NSString* itemName);


@end

NS_ASSUME_NONNULL_END
