//
//  OTCChatToolBar.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OTCChatToolBar : UIView

+ (CGFloat) toolBarHeight;

@property (nonatomic, strong) UIButton* btnPhoto;
@property (nonatomic, strong) UITextField* txtInput;
@property (nonatomic, strong) UIButton* btnMore;

@property (nonatomic, strong) UIView* separator;


@end

NS_ASSUME_NONNULL_END
