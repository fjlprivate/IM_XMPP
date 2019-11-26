//
//  OTCM_timeLayouts.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCM_timeLayouts.h"
#import "JFKit.h"

@implementation OTCM_timeLayouts

+ (instancetype) layoutWithTime:(NSString*)time {
    return [[OTCM_timeLayouts alloc] initWithTime:time];
}

- (instancetype)initWithTime:(NSString*)time {
    self = [super init];
    if (self) {
        if (time) {
            CGFloat gapTop = 15;
            CGFloat gapBottom = 2;

            JFTextStorage* timeStorage = [JFTextStorage storageWithText:time];
            timeStorage.textColor = JFRGBAColor(0xb3b3b3, 1);
            timeStorage.font = [UIFont systemFontOfSize:11];
            timeStorage.backgroundColor = JFRGBAColor(0xebebeb, 1);
            JFTextLayout* layout = [JFTextLayout textLayoutWithText:timeStorage];
            layout.insets = UIEdgeInsetsMake(5, JFScaleWidth6(15), 5, JFScaleWidth6(15));
            layout.backgroundColor = timeStorage.backgroundColor;
            layout.width = layout.height = 200;
            layout.left = (JFSCREEN_WIDTH - layout.width) * 0.5;
            layout.top = gapTop;
            layout.cornerRadius = CGSizeMake(layout.height * 0.5, layout.height * 0.5);
            [self addLayout:layout];

            self.viewFrame = CGRectMake(0, 0, JFSCREEN_WIDTH, layout.bottom + gapBottom);

        }
    }
    return self;
}
@end
