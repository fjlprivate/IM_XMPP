//
//  OTCM_messageBodyText.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCM_messageBody.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTCM_messageBodyText : OTCM_messageBody
// 消息类型
@property (nonatomic, copy) NSString* text;
@end

NS_ASSUME_NONNULL_END
