//
//  OTCChatToolView.m
//  ChatDemo
//
//  Created by cui on 2019/8/8.
//  Copyright © 2019 longerFeng. All rights reserved.
//

#import "OTCChatToolView.h"
#import "JFKit.h"
#import <Masonry/Masonry.h>

@interface OTCChatToolViewCellModel : NSObject
+ (instancetype) itemWithTitle:(NSString*)title icon:(NSString*)icon;
@property (nonatomic, copy) NSString* itemTitle;
@property (nonatomic, copy) NSString* itemIcon;
@end
@implementation OTCChatToolViewCellModel
+ (instancetype) itemWithTitle:(NSString*)title icon:(NSString*)icon {
    OTCChatToolViewCellModel* model = [OTCChatToolViewCellModel new];
    model.itemTitle = title;
    model.itemIcon = icon;
    return model;
}
@end

@interface OTCChatToolViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView* imgIcon;
@property (nonatomic, strong) UILabel* labTitle;
@end


@interface OTCChatToolView() <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView* menuView;
@property (nonatomic, strong) NSArray<OTCChatToolViewCellModel*>* items;
@end

@implementation OTCChatToolView

+ (CGFloat) viewHeight {
    CGFloat hGap = JFScaleWidth6(15);
    CGFloat vInset = JFScaleWidth6(25);
    // 上边距 + item高度 * 2 + 中间间距 + 下边距
    return vInset * 2 + hGap + [self itemHeight] * 1;
}
+ (CGFloat) itemWidth {
    CGFloat gap = JFScaleWidth6(15);
    NSInteger itemCount = 6;
    CGFloat itemWidth = (JFSCREEN_WIDTH - gap * (itemCount + 1)) / itemCount;
    itemWidth = floor(itemWidth);
    return itemWidth;
}
+ (CGFloat) itemHeight {
    CGFloat tGap = JFScaleWidth6(10);
    CGFloat tHeight = JFScaleWidth6(15);
    return [self itemWidth] + tGap + tHeight;
}

# pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTCChatToolViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OTCChatToolViewCell" forIndexPath:indexPath];
    OTCChatToolViewCellModel* item = self.items[indexPath.row];
    cell.imgIcon.image = JFImageNamed(item.itemIcon);
    cell.labTitle.text = item.itemTitle;
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    OTCChatToolViewCellModel* item = self.items[indexPath.row];
    if (self.didSelectedMenuItem) {
        self.didSelectedMenuItem(item.itemTitle);
    }
}

# pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.menuView];
        [self.menuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
    return self;
}

# pragma mark - getter
- (UICollectionView *)menuView {
    if (!_menuView) {
        UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake([OTCChatToolView itemWidth], [OTCChatToolView itemHeight]);
        layout.minimumLineSpacing = JFScaleWidth6(15);
        layout.minimumInteritemSpacing = JFScaleWidth6(15);
        layout.sectionInset = UIEdgeInsetsMake(JFScaleWidth6(25), JFScaleWidth6(15), JFScaleWidth6(25), JFScaleWidth6(15));
        _menuView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_menuView registerClass:[OTCChatToolViewCell class] forCellWithReuseIdentifier:@"OTCChatToolViewCell"];
        _menuView.delegate = self;
        _menuView.dataSource = self;
        _menuView.backgroundColor = JFColorWhite;
        _menuView.backgroundView.backgroundColor = JFColorWhite;
    }
    return _menuView;
}
- (NSArray<OTCChatToolViewCellModel *> *)items {
    if (!_items) {
        _items = @[[OTCChatToolViewCellModel itemWithTitle:APLocalizedString(APLocalStringPicture) icon:@"icon_chat_toolMenu_photo"]];
    }
    return _items;
}

@end



@implementation OTCChatToolViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imgIcon];
        [self.contentView addSubview:self.labTitle];
        [self.imgIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.mas_equalTo(0);
            make.height.equalTo(self.imgIcon.mas_width);
        }];
        [self.labTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.mas_equalTo(0);
        }];
    }
    return self;
}

- (UIImageView *)imgIcon {
    if (!_imgIcon) {
        _imgIcon = [UIImageView new];
        _imgIcon.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imgIcon;
}
- (UILabel *)labTitle {
    if (!_labTitle) {
        _labTitle = [UILabel new];
        _labTitle.textColor = JFRGBAColor(0xb3b3b3, 1);
        _labTitle.font = JFFontWithName(@"PingFangSC-Regular", 12);
        _labTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _labTitle;
}

@end
