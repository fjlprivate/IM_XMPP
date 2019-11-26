//
//  OTCChatTimeCell.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCChatTimeCell.h"
#import "JFKit.h"
#import <Masonry.h>

@interface OTCChatTimeCell()
@property (nonatomic, strong) JFAsyncView* asynvView;
@end

@implementation OTCChatTimeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.asynvView];
        [self.asynvView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
    return self;
}


# pragma mark - getter

- (JFAsyncView *)asynvView {
    if (!_asynvView) {
        _asynvView = [JFAsyncView new];
    }
    return _asynvView;
}

# pragma mark - setter
- (void)setLayouts:(OTCM_timeLayouts *)layouts {
    _layouts = layouts;
    self.asynvView.layouts = layouts;
    self.asynvView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
}

@end
