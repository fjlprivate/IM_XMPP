//
//  OTCM_messageBodyImage.h
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCM_messageBody.h"


NS_ASSUME_NONNULL_BEGIN

static NSString* const kOTCLocalImagePre = @"file::"; // 本地图片地址在DB中的前缀


@interface OTCM_messageBodyImage : OTCM_messageBody
// 图片宽度
@property (nonatomic, assign) CGFloat imageWidth;
// 图片高度
@property (nonatomic, assign) CGFloat imageHeight;
// 图片链接;如果是本地,则要加上前缀 kOTCLocalImagePre;网络图片链接没有加上域名前缀;
@property (nonatomic, copy) NSString* imageUrl;
@end

NS_ASSUME_NONNULL_END
