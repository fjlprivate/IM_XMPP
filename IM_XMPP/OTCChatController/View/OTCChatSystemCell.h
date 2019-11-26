//
//  OTCChatSystemCell.h
//  OTC
//
//  Created by LongerFeng on 2019/7/24.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTCM_messageSystemLayouts.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTCChatSystemCell : UITableViewCell
// 布局对象
@property (nonatomic, strong) OTCM_messageSystemLayouts* layouts;
@end

NS_ASSUME_NONNULL_END
