//
//  OTCM_message.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCM_message.h"

static int16_t kIMMessageMainKey = 0;

@implementation OTCM_message

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messageId = [self newMessageId];
    }
    return self;
}

// 新建主键
- (int64_t) newMessageId {
    int64_t advance = 10000;
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyMMddHHmmss"];
    // 取当前时间作高位，比如:190816092910
    NSString* dateString = [dateFormatter stringFromDate:[NSDate date]];
    // 将时间位移到高位，并加上平台标记，比如:1908160929101000(ios), 1908160929102000(android)
    int64_t key = [dateString integerValue] * advance + 1 * advance / 10; // 倒数第4位，iOS:1, Android:2
    @synchronized (self) {
        kIMMessageMainKey += 1;
        if (kIMMessageMainKey >= advance) {
            kIMMessageMainKey = 0;
        }
        key += kIMMessageMainKey;
    }
    return key;
}

@end
