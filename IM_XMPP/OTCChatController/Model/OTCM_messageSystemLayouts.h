//
//  OTCM_messageSystemLayouts.h
//  OTC
//
//  Created by LongerFeng on 2019/7/24.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#import "JFAsyncViewLayouts.h"
#import "OTCM_messageSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTCM_messageSystemLayouts : JFAsyncViewLayouts
+ (instancetype) layoutWithSystem:(OTCM_messageSystem*)system;
@end

NS_ASSUME_NONNULL_END
