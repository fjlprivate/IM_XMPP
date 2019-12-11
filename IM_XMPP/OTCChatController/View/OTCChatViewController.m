//
//  OTCChatViewController.m
//  PoPCoin
//
//  Created by LongerFeng on 2019/7/18.
//  Copyright © 2019 LongerFeng. All rights reserved.
//

#import "OTCChatViewController.h"
#import "OTCVM_chat.h"
#import <MJRefresh.h>
#import "OTCChatCell.h"
#import "OTCChatTimeCell.h"
#import "OTCChatSystemCell.h"
#import "OTCVM_chat.h"
#import <Masonry.h>
#import "JFKit.h"
#import "OTCChatToolBar.h"
#import <SDWebImage.h>
#import <TZImagePickerController.h>
#import "OTCM_messageBodyImage.h"
#import <IQKeyboardManager.h>
#import <MBProgressHUD.h>
#import "OTCChatToolView.h"
#import <YBImageBrowser.h>



@interface OTCChatViewController () <UITableViewDelegate,UITableViewDataSource, OTCChatCellDelegate, UITextFieldDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate,TZImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) OTCChatToolBar* toolBar;
@property (nonatomic, strong) OTCVM_chat* vmChat;
@property (nonatomic, strong) OTCChatToolView* vToolMenu;
@property (nonatomic, assign) BOOL isToolMenuShown;
@property (nonatomic, assign) BOOL isFirstRefresh;
@property (nonatomic, assign) NSInteger curMenuActionIndex;
@end

@implementation OTCChatViewController


- (void) popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) cacheConversation {
    if (!IsNon(self.conversationId)) {
        [[NSUserDefaults standardUserDefaults] setObject:self.conversationId forKey:AP_USERDEFAULT_KEY_CURRENT_CONVERSATION];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (void) clearConversation {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:AP_USERDEFAULT_KEY_CURRENT_CONVERSATION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

# pragma mark - tools:数据加载

// 加载历史消息
- (void) loadEarlierMessages {
    WeakSelf(wself);
    [self.vmChat loadHistoryMessagesOnFinished:^(NSInteger messagesCount) {
        [wself.tableView.mj_header endRefreshing];
        if (messagesCount > 0) {
            NSMutableArray* list = @[].mutableCopy;
            for (NSInteger row = 0; row < messagesCount; row++) {
                [list addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            [UIView performWithoutAnimation:^{
                [wself.tableView insertRowsAtIndexPaths:list withRowAnimation:UITableViewRowAnimationNone];
                [wself.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messagesCount - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }];
        }
    } orFailed:^(NSError * _Nonnull error) {
        [wself.tableView.mj_header endRefreshing];
    }];
}

/**
 刷新消息;
 */
- (void) refreshMessages {
    WeakSelf(wself);
    NSInteger curCount = [self.vmChat  numberOfMessages];
    [self.vmChat refreshMessagesOnFinished:^(NSArray * _Nonnull rowList) {
//        DLog(@"==============当前行数:%ld,刷新消息返回的序号列表:%@",curCount, rowList);
        if (IsNon(rowList)) {
            return ;
        }
        NSMutableArray* list = @[].mutableCopy;
        NSIndexPath* lastIndexPath = nil;
        for (NSNumber* row in rowList) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row.integerValue inSection:0];
            if (row == rowList.lastObject) {
                lastIndexPath = indexPath;
            }
            [list addObject:indexPath];
        }
        [wself.tableView insertRowsAtIndexPaths:list withRowAnimation:UITableViewRowAnimationNone];
        if (rowList.count > 0) {
            [wself.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:!wself.isFirstRefresh];
        }
        wself.isFirstRefresh = NO;
    } orFailed:^(NSError * _Nonnull error) {
        wself.isFirstRefresh = NO;
    }];
}

// 刷新对方用户信息
- (void) refreshToUserInfo {
    WeakSelf(wself);
    [self.vmChat requestReceiverInfoOnFinished:^(NSString * _Nonnull receiverName) {
        if (!IsNon(receiverName)) {
            wself.title = receiverName;
        } else {
            wself.title = wself.toUserId;
//            wself.title = wself.accountName;
        }
    } orFailed:^(NSError * _Nonnull error) {
        
    }];
}


# pragma mark - tools:动画处理
// 键盘frame变动:处理输入框滑动
- (void) keyboardWillShowNoti:(NSNotification*)noti {
    NSDictionary* userInfo = noti.userInfo;
    // 键盘终点位置
    CGRect endFrame = [userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    // 加速度
    UIViewAnimationCurve curve = [userInfo[@"UIKeyboardAnimationCurveUserInfoKey"] integerValue];
    // 设置toolBar.bottom = keyboard.top - toolBar.height
    CGRect toolBarFrame = self.toolBar.frame;
    toolBarFrame.origin.y = CGRectGetMinY(endFrame) - CGRectGetHeight(toolBarFrame);
    // 设置tableView.frame
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height = CGRectGetMinY(toolBarFrame) - CGRectGetMinY(tableViewFrame);
    // 动画移动toolBar和tableView
    [self animateMoveToolBarToFrame:toolBarFrame tableViewToFrame:tableViewFrame curve:curve animations:nil onFinished:nil];
}
- (void) keyboardWillHideNoti:(NSNotification*)noti {
    NSDictionary* userInfo = noti.userInfo;
    UIViewAnimationCurve curve = [userInfo[@"UIKeyboardAnimationCurveUserInfoKey"] integerValue];
    CGRect toolBarFrame = self.toolBar.frame;
    toolBarFrame.origin.y = JFSCREEN_HEIGHT - JFScreenSafeBottom() - CGRectGetHeight(toolBarFrame);
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height = CGRectGetMinY(toolBarFrame) - CGRectGetMinY(tableViewFrame);

    // 动画移动toolBar和tableView
    [self animateMoveToolBarToFrame:toolBarFrame tableViewToFrame:tableViewFrame curve:curve animations:nil onFinished:nil];

}

// 动画移动toolBar和tableView
- (void) animateMoveToolBarToFrame:(CGRect)toolBarFrame
                  tableViewToFrame:(CGRect)tableViewFrame
                             curve:(UIViewAnimationCurve)curve
                        animations:(void (^) (void))animations // 额外的动画添加;比如:toolMenu的移动
                        onFinished:(void (^) (void))finishedBlock
{
    [UIView animateWithDuration:0.25 animations:^{
        [UIView setAnimationCurve:curve];
        if (animations) {
            animations();
        }
        self.toolBar.frame = toolBarFrame;
        self.tableView.frame = tableViewFrame;
        if ([self.vmChat numberOfMessages] > 0) {
            NSInteger row = [self.vmChat numberOfMessages] > 0 ? [self.vmChat numberOfMessages] - 1 : 0;
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } completion:^(BOOL finished) {
        if (finished && finishedBlock) {
            finishedBlock();
        }
    }];
}

- (void) animateShowToolMenu {
    if (!self.isToolMenuShown) {
        CGRect toolMenuFrame = CGRectMake(0,
                                          JFSCREEN_HEIGHT - JFScreenSafeBottom() - [OTCChatToolView viewHeight],
                                          JFSCREEN_WIDTH,
                                          [OTCChatToolView viewHeight]);
        CGRect toolBarFrame = self.toolBar.frame;
        toolBarFrame.origin.y = CGRectGetMinY(toolMenuFrame) - [OTCChatToolBar toolBarHeight];
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.size.height = CGRectGetMinY(toolBarFrame) - JFNaviStatusBarHeight;
        [self animateMoveToolBarToFrame:toolBarFrame tableViewToFrame:tableViewFrame curve:UIViewAnimationCurveEaseInOut animations:^{
            self.vToolMenu.frame = toolMenuFrame;
            self.toolBar.btnMore.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI * 0.25);
        } onFinished:^{
            self.isToolMenuShown = YES;
        }];
    }
}
- (void) animateHideToolMenu {
    if (self.isToolMenuShown) {
        CGRect toolMenuFrame = CGRectMake(0, JFSCREEN_HEIGHT, JFSCREEN_WIDTH, [OTCChatToolView viewHeight]);
        CGRect toolBarFrame = self.toolBar.frame;
        toolBarFrame.origin.y = JFSCREEN_HEIGHT - JFScreenSafeBottom() - [OTCChatToolBar toolBarHeight];
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.size.height = CGRectGetMinY(toolBarFrame) - JFNaviStatusBarHeight;
        [self animateMoveToolBarToFrame:toolBarFrame tableViewToFrame:tableViewFrame curve:UIViewAnimationCurveEaseInOut animations:^{
            self.vToolMenu.frame = toolMenuFrame;
            self.toolBar.btnMore.transform = CGAffineTransformIdentity;
        } onFinished:^{
            self.isToolMenuShown = NO;
        }];
    }
}

# pragma mark - tools:发送消息

// 发送文本消息
- (void) sendMessageWithText:(NSString*)text {
    WeakSelf(wself);
    // 发送消息
    NSArray* indexes = [self.vmChat sendMessageWithText:text onFinished:^(NSInteger index) {
//        [wself delayReloadingMessageAtIndex:index];
    } orFailed:^(NSInteger index, NSError * _Nonnull error) {
        [wself delayReloadingMessageAtIndex:index];
    }];
    [self addMessagesAfterSending:indexes];
}
// 发送图片消息
- (void) sendMessageWithImage:(UIImage*)image {
    WeakSelf(wself);
    // 发送消息
    NSArray* indexes = [self.vmChat sendMessageWithImage:image onFinished:^(NSInteger index) {
//        [wself delayReloadingMessageAtIndex:index];
    } orFailed:^(NSInteger index, NSError * _Nonnull error) {
        [wself delayReloadingMessageAtIndex:index];
    }];
    [self addMessagesAfterSending:indexes];
}

// 发送消息后的新增消息个数处理:插入表格，并滚动到最后一条消息
- (void) addMessagesAfterSending:(NSArray*) indexes {
    NSInteger latestIndex = [indexes.lastObject integerValue];
    NSMutableArray* indexPathes = @[].mutableCopy;
    for (NSNumber* row in indexes) {
        [indexPathes addObject:[NSIndexPath indexPathForRow:[row integerValue] inSection:0]];
    }
    [UIView performWithoutAnimation:^{
        [self.tableView insertRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
    }];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:latestIndex inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

// 重发
- (void) resendMessageAtCell:(OTCChatCell*)cell {
    NSInteger index = cell.tag;
    OTCM_message* message = [self.vmChat messageAtIndex:index];
    @weakify(self);
    [self.vmChat resendMessage:message onFinished:^(NSInteger index) {
        @strongify(self);
        [self.tableView reloadRow:index inSection:0 withRowAnimation:UITableViewRowAnimationFade];
    } orFailed:^(NSInteger index, NSError * _Nonnull error) {
        
    }];
}

// 延迟重载消息,防止阻塞动画
- (void) delayReloadingMessageAtIndex:(NSInteger)index {
    if (index != NSNotFound) {
        [UIView performWithoutAnimation:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView reloadRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] withRowAnimation:UITableViewRowAnimationNone];
            });
        }];
    }
}

# pragma mark - tools:拷贝

- (void) showCopyAtCell:(OTCChatCell*)cell {
    self.curMenuActionIndex = cell.tag;
    UIMenuController* menu = [UIMenuController sharedMenuController];
    UIMenuItem* copy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(doCopyAtItem:)];
    menu.menuItems = @[copy];
    [menu setTargetRect:cell.layouts.bubbleFrame inView:cell];
    [menu setMenuVisible:YES animated:YES];
}

- (void) doCopyAtItem:(id)item {
    OTCM_message* message = [self.vmChat messageAtIndex:self.curMenuActionIndex];
    if (message && message.messageBodyType == OTCMMessageBodyTypeText) {
        OTCM_messageBodyText* body = (OTCM_messageBodyText*)message.messageBody;
        [UIPasteboard generalPasteboard].string = body.text;
        [MBProgressHUD AP_showSuccess:NSLocalizedString(@"已拷贝", nil)];
    }
}
- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(doCopyAtItem:);
}

/**
 先更新tableView.inset.bottom,然后滑动到底部
 @param insetBottom tableView.inset.bottom
 */
- (void) tbScrollToBottomWithInsetBottomUpdate:(CGFloat)insetBottom {
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = insetBottom;
    self.tableView.contentInset = insets;
    CGPoint offset = CGPointMake(0, self.tableView.contentSize.height + insetBottom - self.tableView.bounds.size.height);
    [self.tableView setContentOffset:offset animated:YES];
}


# pragma mark - 回调:UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.vmChat numberOfMessages];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    JFAsyncViewLayouts* layouts = [self.vmChat layoutsForMessageAtIndex:indexPath.row];
    return layouts.viewFrame.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id model = [self.vmChat messageAtIndex:indexPath.row];
    // 聊天消息
    if ([model isKindOfClass:[OTCM_message class]]) {
        OTCChatCell* cell = [tableView dequeueReusableCellWithIdentifier:@"OTCChatCell"];
        cell.tag = indexPath.row;
        cell.delegate = self;
        cell.layouts = (OTCM_messageLayouts*)[self.vmChat layoutsForMessageAtIndex:indexPath.row];
        return cell;

    }
    // 系统消息
    else if ([model isKindOfClass:[OTCM_messageSystem class]]) {
        OTCChatSystemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"OTCChatSystemCell"];
        cell.layouts = (OTCM_messageSystemLayouts*)[self.vmChat layoutsForMessageAtIndex:indexPath.row];
        return cell;
    }
    // 时间
    else {
        OTCChatTimeCell* cell = [tableView dequeueReusableCellWithIdentifier:@"OTCChatTimeCell"];
        cell.layouts = (OTCM_timeLayouts*)[self.vmChat layoutsForMessageAtIndex:indexPath.row];
        return cell;
    }
}

# pragma mark - 回调:OTCChatCellDelegate
// 点击了头像
- (void) didClickedAvatorInchatCell:(OTCChatCell*)cell {
    
}
// 点击了正文图片
- (void) didClickedImageInchatCell:(OTCChatCell*)cell {
    OTCM_message* message = [self.vmChat messageAtIndex:cell.tag];
    // 处理...
    if (message.messageBodyType != OTCMMessageBodyTypeImage) {
        return;
    }
    OTCM_messageBodyImage* image = (OTCM_messageBodyImage*)message.messageBody;
    NSURL* imageUrl = nil;
    if ([image.imageUrl isKindOfClass:[NSString class]]) {
        imageUrl = [NSURL URLWithString:[APNetworkClientAPIBaseURLString stringByAppendingPathComponent:image.imageUrl]];
    }
    else { // UIImage|NSURL
        imageUrl = (NSURL*)image.imageUrl;
    }
    
    YBImageBrowser* imageBrowser = [YBImageBrowser new];
    YBIBImageData* imageData = [YBIBImageData new];
    if ([image.imageUrl isKindOfClass:[NSString class]]) {
        imageData.imageURL = [NSURL URLWithString:[APNetworkClientAPIBaseURLString stringByAppendingPathComponent:image.imageUrl]];
    }
    else if ([image.imageUrl isKindOfClass:[NSURL class]]) {
        NSURL* url = (NSURL*)image.imageUrl;
        if ([url isFileURL]) {
            imageData.imagePath = url.absoluteString;
        } else {
            imageData.imageURL = url;
        }
    }
//    imageData.projectiveView =
    
    imageBrowser.dataSourceArray = @[imageData];
    imageBrowser.currentPage = 0;
    [imageBrowser show];
    
    
    
//    JFImageBrowserItem* item = [JFImageBrowserItem jf_itemWithMediaType:JFMediaTypeNormalImage
//                                                              thumbnail:nil
//                                                        mediaDisplaying:imageUrl
//                                                            mediaOrigin:imageUrl
//                                                            originFrame:CGRectZero cornerRadius:0
//                                                              mediaSize:CGSizeMake(image.imageWidth, image.imageHeight)
//                                                      originContentMode:UIViewContentModeScaleAspectFit];
//    JFImageBrowserHandler* save = [JFImageBrowserHandler jf_handlerWithTitle:APLocalizedString(APLocalStringSavePicInLibrary) type:JFIBHandlerTypeDefault handle:^(NSInteger index) {
//        [JFHelper saveImageToPhotoLibrary:imageUrl onFinished:^(NSError *error) {
//            UIViewController* vc = JFCurrentViewController();
//            MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:vc.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.removeFromSuperViewOnHide = YES;
//            if (error) {
//                hud.label.text = error.localizedDescription;
//            } else {
//                hud.label.text = APLocalizedString(APLocalStringIsSaved);
//            }
//            [hud hideAnimated:YES afterDelay:1.5];
//        }];
//    }];
//    [JFImageBrowserViewController jf_showFromVC:self withImageList:@[item] andHandlers:@[save] startAtIndex:0];
}
// 长按了正文
- (void) didLongpressedContentTextInchatCell:(OTCChatCell*)cell {
    // 提示拷贝
    [self showCopyAtCell:cell];
}
// 点击了重发
- (void) didClickedResendInchatCell:(OTCChatCell*)cell {
    [self resendMessageAtCell:cell];
}


# pragma mark - 回调:toolBar事件
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self animateHideToolMenu];
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text && textField.text.length > 0) {
        // 回车不管
        if (!(textField.text.length == 1 && [textField.text isEqualToString:@"\n"])) {
            [self sendMessageWithText:textField.text];
        }
    }
    textField.text = nil;
    return YES;
}

// 点击了toolBar.更多按钮
- (IBAction) clickedToolBarMore:(id)sender {
    if (self.toolBar.txtInput.isEditing) {
        [self.toolBar.txtInput endEditing:YES];
    }
    // toolView正在显示:隐藏它
    if (self.isToolMenuShown) {
        [self animateHideToolMenu];
    }
    // toolView没有显示:显示它
    else {
        [self animateShowToolMenu];
    }
}


# pragma mark - 回调:toolView事件
- (void) handleWithToolMenuItem:(NSString*)toolMenuItemName {
    // 图片
    if ([toolMenuItemName isEqualToString:APLocalizedString(APLocalStringPicture)]) {
        [self handleWithTakePhoto];
    }
}

// 处理事件:拍照|相册
- (void) handleWithTakePhoto {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* camera = [UIAlertAction actionWithTitle:APLocalizedString(APLocalStringTakeCamera) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController* imagePicker = [UIImagePickerController new];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    UIAlertAction* library = [UIAlertAction actionWithTitle:APLocalizedString(APLocalStringChooseFromLibrary) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        TZImagePickerController* picker = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        picker.allowPickingVideo = NO;
        picker.allowTakePicture = NO;
        picker.allowTakeVideo = NO;
        [self presentViewController:picker animated:YES completion:nil];
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:APLocalizedString(APLocalStringCancel) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:camera];
    [alert addAction:library];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
# pragma mark - 回调:UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self sendMessageWithImage:image];
}

# pragma mark - 回调:TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
{
    UIImage* image = [photos firstObject];
    [self sendMessageWithImage:image];
}


# pragma mark - life cycle
/**
 初始化
 @param conversationId 会话id
 @param toUserId 对方userId
 @return 聊天页面
 */
- (instancetype)initWithConversation:(NSString*)conversationId toUser:(NSString*)toUserId {
    self = [super init];
    if (self) {
        self.conversationId = conversationId;
        self.toUserId = toUserId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.toolBar];
    [self.view addSubview:self.vToolMenu];
    self.isFirstRefresh = YES;
    
    self.toolBar.frame = CGRectMake(0, JFSCREEN_HEIGHT - JFScreenSafeBottom() - [OTCChatToolBar toolBarHeight], JFSCREEN_WIDTH, [OTCChatToolBar toolBarHeight]);
    self.tableView.frame = CGRectMake(0, JFNaviStatusBarHeight, JFSCREEN_WIDTH, CGRectGetMinY(self.toolBar.frame) - JFNaviStatusBarHeight);
    self.vToolMenu.frame = CGRectMake(0, JFSCREEN_HEIGHT, JFSCREEN_WIDTH, [OTCChatToolView viewHeight]);
    
    // 刷新对方用户信息
    [self refreshToUserInfo];
    // 刷新消息
    [self refreshMessages];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNoti:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNoti:) name:UIKeyboardWillHideNotification object:nil];
    [IQKeyboardManager sharedManager].enable = NO;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    [self cacheConversation];
    self.navigationController.navigationBar.translucent = YES;

}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.vmChat resetAllUnread];
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].enableAutoToolbar = YES;
    [self clearConversation];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearConversation];
}

- (void) cancelInput {
    [self.view endEditing:YES];
}

# pragma mark - getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[OTCChatCell class] forCellReuseIdentifier:@"OTCChatCell"];
        [_tableView registerClass:[OTCChatTimeCell class] forCellReuseIdentifier:@"OTCChatTimeCell"];
        [_tableView registerClass:[OTCChatSystemCell class] forCellReuseIdentifier:@"OTCChatSystemCell"];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        _tableView.backgroundColor = JFRGBAColor(0xf5f5f5, 1);
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0);
        MJRefreshNormalHeader* header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadEarlierMessages)];
        _tableView.mj_header = header;
        UITapGestureRecognizer* tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInput)];
        tapGes.cancelsTouchesInView = NO; // 默认:YES；设置为NO:表示当前控件响应后会继续传递给它的响应链上的其他响应者
        [_tableView addGestureRecognizer:tapGes];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
    }
    return _tableView;
}
- (OTCChatToolBar *)toolBar {
    if (!_toolBar) {
        _toolBar = [OTCChatToolBar new];
        _toolBar.txtInput.delegate = self;
        [_toolBar.btnMore addTarget:self action:@selector(clickedToolBarMore:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toolBar;
}
- (OTCVM_chat *)vmChat {
    if (!_vmChat) {
        _vmChat = [[OTCVM_chat alloc] initWithConversation:self.conversationId toUser:self.toUserId];
        WeakSelf(wself);
        _vmChat.didReceiveMessges = ^{
            // 有新消息到来就请求新消息
            [wself refreshMessages];
        };
    }
    return _vmChat;
}
- (OTCChatToolView *)vToolMenu {
    if (!_vToolMenu) {
        _vToolMenu = [OTCChatToolView new];
        WeakSelf(wself);
        _vToolMenu.didSelectedMenuItem = ^(NSString * _Nonnull itemName) {
            [wself handleWithToolMenuItem:itemName];
        };
    }
    return _vToolMenu;
}

@end
