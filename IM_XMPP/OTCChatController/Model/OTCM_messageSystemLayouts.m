//
//  OTCM_messageSystemLayouts.m
//  OTC
//
//  Created by LongerFeng on 2019/7/24.
//  Copyright © 2019 Sim.Liu. All rights reserved.
//

#import "OTCM_messageSystemLayouts.h"
#import "JFKit.h"

@implementation OTCM_messageSystemLayouts

+ (instancetype) layoutWithSystem:(OTCM_messageSystem *)system {
    return [[OTCM_messageSystemLayouts alloc] initWithSystem:system];
}

- (instancetype)initWithSystem:(OTCM_messageSystem *)system {
    self = [super init];
    if (self) {
        if (system) {
            CGFloat gapTop = 15;
            CGFloat gapBottom = 2;
            
            JFTextStorage* timeStorage = [JFTextStorage storageWithText:system.content];
            timeStorage.textColor = JFRGBAColor(0x333333, 1);
            timeStorage.font = [UIFont systemFontOfSize:11];
            timeStorage.backgroundColor = JFRGBAColor(0xCCCCCC, 1);
//            timeStorage.textAlignment = NSTextAlignmentCenter;
            JFTextLayout* layout = [JFTextLayout textLayoutWithText:timeStorage];
            layout.insets = UIEdgeInsetsMake(5, 15, 5, 15);
            layout.backgroundColor = JFRGBAColor(0xe5e5e5, 1);//timeStorage.backgroundColor;
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
