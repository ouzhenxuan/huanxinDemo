//
//  chatViewController.m
//  视频通讯demo
//
//  Created by ozx on 15/7/15.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "chatViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "chatWithUserController.h"
#import "ChatListCell.h"
#import "CallViewController.h"

#define Swidth [UIScreen mainScreen].bounds.size.width

@interface chatViewController ()<UITableViewDataSource,UITableViewDelegate,IChatManagerDelegate, EMCallManagerDelegate>
{
    NSString * mes;
//    EMConversation *conversation;
    UILabel * unreadLabel;
    
    dispatch_queue_t _messageQueue;
    
    UITextField * sendToUser;
    
    UITableView * mytableview;
    
    NSMutableArray * huihuaArray;
}

@property (strong, nonatomic) EMConversation *conversation;//会话管理者
@property (strong, nonatomic) NSMutableArray *messages;



@property (nonatomic) BOOL isPlayingAudio;//判断是否已经播放了音频
@end

@implementation chatViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"chat";
    self.view.backgroundColor = [UIColor whiteColor];
    
//    初始化
    _isPlayingAudio = NO;
    huihuaArray = [[NSMutableArray alloc] init];
    

    
//    NSArray *cons2  =[[[EaseMob sharedInstance] chatManager] conversations];//从内存中读取列表
    NSArray *cons1 = [[EaseMob sharedInstance].chatManager loadAllConversationsFromDatabaseWithAppend2Chat:YES];
    
    [huihuaArray addObjectsFromArray:cons1];
    
    
#warning 以下三行代码必须写，注册为SDK的ChatManager的delegate
//    [EMCDDeviceManager sharedInstance].delegate = self;
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    //注册为SDK的ChatManager的delegate
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
#warning 把self注册为SDK的delegate
    [self registerNotifications];
    
#pragma mark - 注册消息中心,当call view消失以后就会启动这个方法.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callControllerClose:) name:@"callControllerClose" object:nil];
    
     unreadLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 150, 50, 30)];
    unreadLabel.text = @"hehe";
    unreadLabel.backgroundColor = [UIColor yellowColor];
    [unreadLabel setTextColor:[UIColor blackColor]];
    [self.view addSubview:unreadLabel];
    mes = @"";
    

    
     sendToUser= [[UITextField alloc] initWithFrame:CGRectMake(0, 64, 70, 44)];
    [self.view addSubview:sendToUser];
    [sendToUser setBorderStyle:UITextBorderStyleRoundedRect];
    
    
    UIButton *  btn_send = [[UIButton alloc ]initWithFrame:CGRectMake(100, 65, 50, 44)];
    UIButton *  btn_cheak = [[UIButton alloc ]initWithFrame:CGRectMake(200, 65, 50, 44)];
    
    btn_send.backgroundColor = [UIColor orangeColor];
    [btn_send setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_send setTitle:@"send" forState:UIControlStateNormal];
    [btn_send addTarget:self action:@selector(sendMes) forControlEvents:UIControlEventTouchUpInside];
    
    btn_cheak.backgroundColor = [UIColor orangeColor];
    [btn_cheak setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_cheak setTitle:@"cheak" forState:UIControlStateNormal];
    [btn_cheak addTarget:self action:@selector(cheakTheNew) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn_send];
    [self.view addSubview:btn_cheak];
    
    mytableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 200, Swidth, 300) style:UITableViewStylePlain];
    mytableview.dataSource = self;
    mytableview.delegate = self;
    
    [self.view addSubview:mytableview];

}

-(void) back{
    NSLog(@"laidaozhe ");
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
        if (!error && info) {
            NSLog(@"退出成功");
        }
    } onQueue:nil];
//    [self.navigationController popViewControllerAnimated:YES];
}


-(void)refreshDataSource
{
//    huihuaArray = huihuaArray;
    [mytableview reloadData];
}

#pragma mark - 设置是否是隐藏的 (Invisible)
- (void)setIsInvisible:(BOOL)isInvisible
{
    _isInvisible =isInvisible;
    if (!_isInvisible)
    {
        NSMutableArray *unreadMessages = [NSMutableArray array];
        for (EMMessage *message in self.messages)
        {
            if ([self shouldAckMessage:message read:NO])
            {
                [unreadMessages addObject:message];
            }
        }
        if ([unreadMessages count])
        {
            [self sendHasReadResponseForMessages:unreadMessages];
        }
        
        [_conversation markAllMessagesAsRead:YES];
    }
}

- (void)sendHasReadResponseForMessages:(NSArray*)messages
{
    dispatch_async(_messageQueue, ^{
        for (EMMessage *message in messages)
        {
            [[EaseMob sharedInstance].chatManager sendReadAckForMessage:message];
        }
    });
}

-(void)cheakTheNew{
    NSLog(@"%lu",(unsigned long)[_conversation unreadMessagesCount]);
    
}

-(void) sendMes{
    
    //modal一个新的窗口出来进行通话.
    
    chatWithUserController * chatWvc = [[chatWithUserController alloc] init];
    chatWvc.userName= sendToUser.text;
    [self presentViewController:chatWvc animated:YES completion:^{
        
    }];
}

-(void)didReceiveMessage:(EMMessage *)message
{

    NSLog(@"收到了一条消息");
//    id<IEMMessageBody> messageBody = [message.messageBodies firstObject];
//    NSString *messageStr = nil;
//    messageStr = ((EMTextMessageBody *)messageBody).text;
    
//    NSString * name = message.from;//from和conversationChatter这两个是一样的
//    NSString * chat = message.conversationChatter;
    
}

- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage{
    NSLog(@"%s",__func__);
}

#pragma mark - 1
// 未读消息数量变化回调
-(void)didUnreadMessagesCountChanged
{
    [self setupUnreadMessageCount];
}

-(void)setupUnreadMessageCount
{
    //将没有阅读的会话加入到数组中
    NSArray *conversations = [[[EaseMob sharedInstance] chatManager] conversations];
    NSInteger unreadCount = 0;
    [huihuaArray removeAllObjects];
    [huihuaArray addObjectsFromArray:conversations];
    [mytableview reloadData];
    //conversation
    for (EMConversation *conversation1 in conversations) {
        unreadCount += conversation1.unreadMessagesCount;
    }
    
    
    UIApplication *application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:unreadCount];
    
    unreadLabel.text =[NSString stringWithFormat:@"%i",(int)unreadCount];
}


-(void)registerNotifications
{
    [self unregisterNotifications];
    
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    [[EaseMob sharedInstance].callManager addDelegate:self delegateQueue:nil];
}

-(void)unregisterNotifications
{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].callManager removeDelegate:self];
}


- (BOOL)shouldAckMessage:(EMMessage *)message read:(BOOL)read
{
    NSString *account = [[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername];//获取当前用户名
    if (message.messageType != eMessageTypeChat || message.isReadAcked || [account isEqualToString:message.from] || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) || self.isInvisible)
    {
        return NO;
    }
    
    id<IEMMessageBody> body = [message.messageBodies firstObject];
    if (((body.messageBodyType == eMessageBodyType_Video) ||
         (body.messageBodyType == eMessageBodyType_Voice) ||
         (body.messageBodyType == eMessageBodyType_Image)) &&
        !read)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma  mark -处理会话信息.
//处理会话信息.
- (void)handleCallNotification:(NSNotification *)notification
{
    id object = notification.object;
    if ([object isKindOfClass:[NSDictionary class]]) {
        //开始call
        self.isInvisible = YES;
    }
    else
    {
        //结束call
        self.isInvisible = NO;
    }
}

#pragma mark - uitableviewdelegate

#pragma mark - uitableviewdatasource
-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identify = @"chatListCell";
    ChatListCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    
    if (!cell) {
        cell = [[ChatListCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identify];
    }
    EMConversation *conversation = [huihuaArray objectAtIndex:indexPath.row];
    cell.name = conversation.chatter;
    if (conversation.conversationType == eConversationTypeChat) {
//        if ([[RobotManager sharedInstance] isRobotWithUsername:conversation.chatter]) {
//            cell.name = [[RobotManager sharedInstance] getRobotNickWithUsername:conversation.chatter];
//        }
//        cell.placeholderImage = [UIImage imageNamed:@"chatListCellHead.png"];
    }
    else{
        NSString *imageName = @"groupPublicHeader";
        if (![conversation.ext objectForKey:@"groupSubject"] || ![conversation.ext objectForKey:@"isPublic"])
        {
            NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
            for (EMGroup *group in groupArray) {
                if ([group.groupId isEqualToString:conversation.chatter]) {
                    cell.name = group.groupSubject;
                    imageName = group.isPublic ? @"groupPublicHeader" : @"groupPrivateHeader";
                    
                    NSMutableDictionary *ext = [NSMutableDictionary dictionaryWithDictionary:conversation.ext];
                    [ext setObject:group.groupSubject forKey:@"groupSubject"];
                    [ext setObject:[NSNumber numberWithBool:group.isPublic] forKey:@"isPublic"];
                    conversation.ext = ext;
                    break;
                }
            }
        }
        else
        {
            cell.name = [conversation.ext objectForKey:@"groupSubject"];
            imageName = [[conversation.ext objectForKey:@"isPublic"] boolValue] ? @"groupPublicHeader" : @"groupPrivateHeader";
        }
        cell.placeholderImage = [UIImage imageNamed:imageName];
    }
//    cell.detailMsg = [self subTitleMessageByConversation:conversation];
//    cell.time = [self lastMessageTimeByConversation:conversation];
    cell.unreadCount = [self unreadMessageCountByConversation:conversation];
//    if (indexPath.row % 2 == 1) {
//        cell.contentView.backgroundColor = RGBACOLOR(246, 246, 246, 1);
//    }else{
        cell.contentView.backgroundColor = [UIColor whiteColor];
//    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  huihuaArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [ChatListCell tableView:tableView heightForRowAtIndexPath:indexPath];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //获得点中的会话对象.
    EMConversation *conversation = [huihuaArray objectAtIndex:indexPath.row];
    [conversation markAllMessagesAsRead:YES];
    
    chatWithUserController *chatController;
    NSString *title = conversation.chatter;//获得当前联系人的名字
    if (conversation.conversationType != eConversationTypeChat) {
        if ([[conversation.ext objectForKey:@"groupSubject"] length])
        {
            title = [conversation.ext objectForKey:@"groupSubject"];
        }
        else
        {
            NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
            for (EMGroup *group in groupArray) {
                if ([group.groupId isEqualToString:conversation.chatter]) {
                    title = group.groupSubject;
                    break;
                }
            }
        }
    }
    
    chatController = [[chatWithUserController alloc] init];
    chatController.userName = title;
    chatController.title = title;
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].callManager removeDelegate:self];
    [self presentViewController:chatController animated:YES completion:^{
    }];
}



// 得到未读消息条数
- (NSInteger)unreadMessageCountByConversation:(EMConversation *)conversation
{
    NSInteger ret = 0;
    ret = conversation.unreadMessagesCount;
    
    return  ret;
}

#pragma mark - ICallManagerDelegate
#pragma mark  接收到视频请求的时候,视频这里开始
/*!
 @method
 @brief 实时通话状态发生变化时的回调
 @param callSession 实时通话的实例
 @param reason   变化原因
 @param error    错误信息
 */
- (void)callSessionStatusChanged:(EMCallSession *)callSession changeReason:(EMCallStatusChangedReason)reason error:(EMError *)error
{
    if (callSession.status == eCallSessionStatusConnected)
    {
        EMError *error = nil;
        do {
            BOOL isShowPicker = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowPicker"] boolValue];
            if (isShowPicker) {
                error = [EMError errorWithCode:EMErrorInitFailure andDescription:NSLocalizedString(@"call.initFailed", @"Establish call failure")];
                break;
            }
            
            if (![self canRecord]) {
                error = [EMError errorWithCode:EMErrorInitFailure andDescription:NSLocalizedString(@"call.initFailed", @"Establish call failure")];
                break;
            }
            
#warning 在后台不能进行视频通话
            if(callSession.type == eCallSessionTypeVideo && ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive || ![CallViewController canVideo])){
                error = [EMError errorWithCode:EMErrorInitFailure andDescription:NSLocalizedString(@"call.initFailed", @"Establish call failure")];
                break;
            }
            
            if (!isShowPicker){
                [[EaseMob sharedInstance].callManager removeDelegate:self];
                CallViewController *callController = [[CallViewController alloc] initWithSession:callSession isIncoming:YES];
                callController.modalPresentationStyle = UIModalPresentationOverFullScreen;
                [self presentViewController:callController animated:NO completion:nil];
                if ([self.navigationController.topViewController isKindOfClass:[chatWithUserController class]])
                {
                    chatWithUserController *chatVc = (chatWithUserController *)self.navigationController.topViewController;
//                    chatVc.isInvisible = YES;
                }
            }
        } while (0);
        
        if (error) {
            [[EaseMob sharedInstance].callManager asyncEndCall:callSession.sessionId reason:eCallReasonHangup];
            return;
        }
    }
}


- (void)callControllerClose:(NSNotification *)notification
{
    //    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    //    [audioSession setActive:YES error:nil];
    
    [[EaseMob sharedInstance].callManager addDelegate:self delegateQueue:nil];
}

#pragma mark - call
//请求打开录音功能
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                bCanRecord = granted;
            }];
        }
    }
    
    if (!bCanRecord) {
        UIAlertView * alt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"setting.microphoneNoAuthority", @"No microphone permissions") message:NSLocalizedString(@"setting.microphoneAuthority", @"Please open in \"Setting\"-\"Privacy\"-\"Microphone\".") delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
        [alt show];
    }
    
    return bCanRecord;
}


-(void)dealloc{
    [self back];
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].callManager removeDelegate:self];
}


@end
