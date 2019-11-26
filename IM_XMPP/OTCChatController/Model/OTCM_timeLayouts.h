//
//  OTCM_timeLayouts.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "JFAsyncViewLayouts.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTCM_timeLayouts : JFAsyncViewLayouts
+ (instancetype) layoutWithTime:(NSString*)time;

@end

NS_ASSUME_NONNULL_END
