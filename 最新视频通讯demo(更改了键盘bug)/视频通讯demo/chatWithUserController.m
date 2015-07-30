//
//  chatWithUserController.m
//  视频通讯demo
//
//  Created by ozx on 15/7/16.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "chatWithUserController.h"
#import "EaseMob.h"
#import <AVFoundation/AVFoundation.h>
#import "CallViewController.h"
#import "NSDate+Category.h"
#import "EMChatViewCell.h"
#import "MessageModelManager.h"
#import "MessageReadManager.h"
#import "UIViewController+HUD.h"
#import "Masonry.h"

#define Swidth [UIScreen mainScreen].bounds.size.width
#define Shidth [UIScreen mainScreen].bounds.size.height
#define UITextViewTextFont 20.0
@interface ChatImageOptions : NSObject<IChatImageOptions>

@property (assign, nonatomic) CGFloat compressionQuality;

@end

@implementation ChatImageOptions

@end

@interface chatWithUserController ()<UIGestureRecognizerDelegate,IChatManagerDelegate, EMCallManagerDelegate,UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UITextViewDelegate>
{
    UITextView * sendContext;
    EMConversation *conversation ;
    UITextView * textview;
    UITableView * mytableview;
    
     dispatch_queue_t _messageQueue;
    
    CGFloat currentInputTextHeight;
    
    NSMutableArray * acc;
    
    UIView * toolView;//工具栏(图片,视频)
    UIView * editView ; //编辑栏 (输入文字,发送按钮,显示工具栏)
    
    MessageModel *modelChange ;//用于转化类型(EMMessage->MessageModel)
    
    int getobject[10];
    int flag;//标记键盘是否弹出, 1为弹出,0为没有弹出
    
    CGRect tableviewRect;
    CGRect editviewRect;
    
}
@property (nonatomic,strong) NSMutableArray * messages;;
@property (strong, nonatomic) MessageReadManager *messageReadManager;//message阅读的管理者

@end

@implementation chatWithUserController
@synthesize userName  = userName;

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
//    //注册为SDK的ChatManager的delegate
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
    [[EaseMob sharedInstance].callManager removeDelegate:self];
    [[EaseMob sharedInstance].callManager addDelegate:self delegateQueue:nil];
    
    
    
    //初始化
    acc = [NSMutableArray array];
    modelChange = [[MessageModel alloc] init];
    flag = 0;
    
    
    //开始新建会话/获取会话列表
    conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:userName conversationType:eConversationTypeChat];
    
    //注册消息中心
    [self registerTheNotification];
    
    _messageQueue = dispatch_queue_create("anjubao.com", NULL); //用于标记队列
    
    //添加uitableview
    [self addTheTableView];
    
    [self setupTheBtn];
    tableviewRect= mytableview.frame;
    editviewRect = editView.frame;
    //添加手势
    [self addTheGestureRecognizer];
    
    //先请求了照相隐私
    [self requestThePhoto];
    
//    [self scrollViewToBottom:NO];
    [self scrollViewToBottom:NO];
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:NO];
    [self scrollViewToBottom:NO];
}

-(void)registerTheNotification{
    //增加监听，当键盘出现或改变时收出消息
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    //增加监听，当键退出时收出消息
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

#pragma mark - 键盘监听
//当键盘出现或改变时调用
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    flag = 1;
    //判断toolView是否显示,如果在显示,则先将toolview搞掉
    if (!toolView.hidden) {
        CGPoint p = editView.center;
        CGRect rect = mytableview.frame;
        CGRect toolViewRect = toolView.frame;
        toolViewRect.origin.y = toolViewRect.origin.y + 80;
        [UIView animateWithDuration:.3 animations:^{
            mytableview.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+80);
            editView.center = CGPointMake(p.x, p.y + 80);
            toolView.frame = toolViewRect;
        }completion:^(BOOL finished) {
            toolView.hidden = YES;
        }];
    }
    //获取键盘的高度
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    int height = keyboardRect.size.height;
    
    CGRect rect = mytableview.frame;
    rect.size.height = tableviewRect.size.height - height;
    CGRect erecr = CGRectMake(0, keyboardRect.origin.y - editView.frame.size.height, Swidth, editView.frame.size.height);
    //改变editview 和tableview的高度
//    CGPoint p = CGPointMake(Swidth/2, keyboardRect.origin.y - 36/2);
    [UIView animateWithDuration:.2 animations:^{
        editView.frame = erecr;
        mytableview.frame = rect;
    } completion:^(BOOL finished) {
        [self scrollViewToBottom:YES];
    }];
    

}

//当键退出时调用
- (void)keyboardWillHide:(NSNotification *)aNotification
{
    flag=0;
    [UIView animateWithDuration:.2
                          delay:0.
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         editView.center = CGPointMake(Swidth/2, Shidth - editView.frame.size.height/2);
         mytableview.frame = CGRectMake(0, 64, Swidth, Shidth - 36-64);
     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    
}

-(void)addTheTableView{
    mytableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, Swidth, Shidth - 36-64) style:UITableViewStylePlain];
    mytableview.backgroundColor = [UIColor greenColor];
    mytableview.delegate = self;
    mytableview.dataSource = self;
    [self.view addSubview:mytableview];
}

-(void)addTheGestureRecognizer{
    UITapGestureRecognizer *panRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.view addGestureRecognizer:panRecognizer];
    panRecognizer.delegate = self;
}

-(void)requestThePhoto{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {//请求访问照相功能.
            if(granted){//点击允许访问时调用
                //用户明确许可与否，媒体需要捕获，但用户尚未授予或拒绝许可。
                NSLog(@"Granted access to %@", mediaType);
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
            }
        }];
        
    }
}

-(void)dealloc{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].callManager removeDelegate:self];
}

#pragma mark - 布局
-(void)setupTheBtn{
    UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    [b setTitle:@"back" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b.backgroundColor = [UIColor clearColor];
    [b addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchDown];
    UIBarButtonItem * left = [[UIBarButtonItem alloc] initWithCustomView:b];
    //    self.navigationController.navigationItem.leftBarButtonItem = left;
    
    UIButton *b1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    [b1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [b1 setTitle:@"done" forState:UIControlStateNormal];
    b1.backgroundColor = [UIColor clearColor];
    [b1 addTarget:self action:@selector(hehe) forControlEvents:UIControlEventTouchDown];
    UIBarButtonItem * right = [[UIBarButtonItem alloc] initWithCustomView:b1];
    
    UINavigationBar * bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)];
    UINavigationItem * title = [[UINavigationItem alloc] initWithTitle:userName];
    NSLog(@"%@",userName);
    [bar pushNavigationItem:title animated:NO];
    title.leftBarButtonItem = left;
    title.rightBarButtonItem = right;
    [self.view addSubview:bar];
    self.view.backgroundColor = [UIColor yellowColor];
    
    
    //编辑view
    editView = [[UIView alloc] initWithFrame:CGRectMake(0, Shidth - 36, Swidth, 36)];
    [self.view addSubview:editView];
//    editView.backgroundColor = [UIColor blueColor];
    
    sendContext = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, Swidth-100, 36)];
    [editView addSubview:sendContext];
    currentInputTextHeight = 36;
//    sendContext.autoresizingMask = UIViewAutoresizingFlexibleHeight;//自适应高度
    sendContext.delegate = self;//设置它的委托方法
    sendContext.scrollEnabled = YES;  //是否可以拖动
    sendContext.layer.cornerRadius=5; //设置圆角
    [sendContext setFont:[UIFont systemFontOfSize:UITextViewTextFont]];
//    sendContext.maximumZoomScale = 2.0;//设置最大的显示行数
    
//    UIButton * send = [[UIButton alloc] initWithFrame:CGRectMake(Swidth-100+5, 0 , 40, 36)];
    UIButton * send = [[UIButton alloc] init];
    [editView addSubview:send];
    [send mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(editView).with.offset(0);
        make.right.equalTo(editView).with.offset(-60);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(36);
    }];
    send.backgroundColor  = [UIColor redColor];
    [send setTitle:@"send" forState:UIControlStateNormal];
    [send setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [send addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchDown];
    
//    UIButton * add = [[UIButton alloc] initWithFrame:CGRectMake(Swidth-100+50, 0, 40, 36)];
    UIButton * add = [[UIButton alloc] init];
    [editView addSubview:add];
    [add mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(editView).with.offset(0);
        make.right.equalTo(editView).with.offset( -5);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(36);
    }];
    add.backgroundColor  = [UIColor redColor];
    [add setTitle:@"+" forState:UIControlStateNormal];
    [add setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [add addTarget:self action:@selector(addTool:) forControlEvents:UIControlEventTouchDown];
    
    //工具View
    toolView = [[UIView alloc] initWithFrame:CGRectMake(0, Shidth, Swidth, 80)];
    [self.view addSubview:toolView];
    toolView.hidden = YES;
    
    UIButton * sendImage = [[UIButton alloc] initWithFrame:CGRectMake(0, 0 , Swidth, 40)];
    [toolView addSubview:sendImage];
    sendImage.backgroundColor  = [UIColor redColor];
    [sendImage setTitle:@"sendImage" forState:UIControlStateNormal];
    [sendImage setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sendImage addTarget:self action:@selector(sendImage:) forControlEvents:UIControlEventTouchDown];
    
    //视频聊天按钮
    UIButton * btn_video = [[UIButton alloc] initWithFrame:CGRectMake(0, 40, Swidth , 40)];
    btn_video.backgroundColor  = [UIColor redColor];
    [btn_video setTitle:@"视频聊天" forState:UIControlStateNormal];
    [btn_video setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [toolView addSubview:btn_video];
    [btn_video addTarget:self action:@selector(openTheVideo:) forControlEvents:UIControlEventTouchDown];
    
}

-(void)openTheVideo:(UIButton *)btn{
    BOOL isopen = [self canVideo];
    EMError *error = nil;
    EMCallSession *callSession = nil;
    if (!isopen) {
        NSLog(@"不能打开视频");
        return ;
    }
    //这里发送视频请求
    callSession = [[EaseMob sharedInstance].callManager asyncMakeVideoCall:userName timeout:50 error:&error];
    //请求完以后,开始做下面的
    if (callSession && !error) {
        [[EaseMob sharedInstance].callManager removeDelegate:self];
        
        CallViewController *callController = [[CallViewController alloc] initWithSession:callSession isIncoming:NO];
        callController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:callController animated:NO completion:nil];
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"error") message:error.description delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

-(BOOL)canVideo{
    BOOL canvideo = YES;
    NSString *mediaType = AVMediaTypeVideo;// Or AVMediaTypeAudio
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    NSLog(@"---cui--authStatus--------%d",authStatus);
    // This status is normally not visible—the AVCaptureDevice class methods for discovering devices do not return devices the user is restricted from accessing.
    if(authStatus ==AVAuthorizationStatusRestricted){//此应用程序没有被授权访问的照片数据。可能是家长控制权限。
        NSLog(@"Restricted");
        canvideo = NO;
        return canvideo;
    }else if(authStatus == AVAuthorizationStatusDenied){//用户已经明确否认了这一照片数据的应用程序访问.
        // The user has explicitly denied permission for media capture.
        NSLog(@"Denied");     //应该是这个，如果不允许的话
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"请在设备的\"设置-隐私-相机\"中允许访问相机。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        alert = nil;
        canvideo = NO;
        return canvideo;
    }
    else if(authStatus == AVAuthorizationStatusAuthorized){//允许访问,用户已授权应用访问照片数据.
        // The user has explicitly granted permission for media capture, or explicit user permission is not necessary for the media type in question.
        NSLog(@"Authorized");
        canvideo = YES;
        return canvideo;
    }else if(authStatus == AVAuthorizationStatusNotDetermined){//用户尚未做出了选择这个应用程序的问候
        // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {//请求访问照相功能.
            //应该在打开视频前就访问照相功能,不然下面返回不了值啊.
            if(granted){//点击允许访问时调用
                //用户明确许可与否，媒体需要捕获，但用户尚未授予或拒绝许可。
                NSLog(@"Granted access to %@", mediaType);
                
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
            }
        }];
    }else {
        NSLog(@"Unknown authorization status");
        canvideo = NO;
    }
    return canvideo;
}

-(NSMutableArray *)messages{
    if (_messages == nil) {
        //从会话管理者中获得当前会话.
        _messages = [[NSMutableArray alloc] init];
        EMConversation *conversation2 =  [[EaseMob sharedInstance].chatManager conversationForChatter:userName conversationType:0] ;
        
        NSArray * arrcon;
        //    NSArray * arr;
        //    arr = [conversation2 loadAllMessages]; // 获得内存中所有的会话.
        long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000 + 1;//制作时间戳
        arrcon = [conversation2 loadNumbersOfMessages:10 before:timestamp]; //根据时间获得5调会话. (时间戳作用:获得timestamp这个时间以前的所有/10会话)
//        NSArray * acc = [NSArray array];
        arrcon = [self formatMessages:arrcon];
        [_messages removeAllObjects];
        [_messages addObjectsFromArray:arrcon];
        
    }
    return _messages;
}


#pragma mark -点击事件
-(void)hehe{
    [self.view endEditing:YES];
    
}

-(void)handlePanFrom:(id)sender{
    [self.view endEditing:YES];
    if (flag == 0) {//在没有键盘的情况下.
        if (toolView.hidden==NO) {//如果还显示工具条,则令键盘消失
            CGPoint p = editView.center;
            CGRect rect = mytableview.frame;
            CGRect toolViewRect = toolView.frame;
            toolViewRect.origin.y = toolViewRect.origin.y + 80;
            [UIView animateWithDuration:.3 animations:^{
                mytableview.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+80);
                editView.center = CGPointMake(p.x, p.y + 80);
                toolView.frame = toolViewRect;
            }completion:^(BOOL finished) {
                toolView.hidden = YES;
            }];
        }
    }else//有键盘的情况(不会执行到这里,因为都已经[self.view endEditing:YES];)
    {}
    
}

-(void)back:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

-(void) addTool:(id)sender{//其实只有tableview的frame需要改,其他的只需要改center
    [self.view endEditing:YES];
    CGPoint p = editView.center;
    CGRect rect = mytableview.frame;
    CGRect toolViewRect = toolView.frame;
    if (toolView.hidden) {
        toolView.hidden = NO;
        
        toolViewRect.origin.y = toolViewRect.origin.y - 80;
        [UIView animateWithDuration:.3 animations:^{
            mytableview.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height-80);
            editView.center = CGPointMake(p.x, p.y-80);
            toolView.frame = toolViewRect;
        }];
        
    }else{
        toolViewRect.origin.y = toolViewRect.origin.y + 80;
        [UIView animateWithDuration:.3 animations:^{
            mytableview.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+80);
            editView.center = CGPointMake(p.x, p.y + 80);
            toolView.frame = toolViewRect;
        }completion:^(BOOL finished) {
            toolView.hidden = YES;
        }];
    }
}


#pragma mark - IChatManagerDelegate
#pragma mark - 发送信息
-(void) send:(UIButton *)sender{
    
    EMChatText *txtChat = [[EMChatText alloc] initWithText:sendContext.text];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:txtChat];

    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:userName bodies:@[body]];
    message.messageType = eMessageTypeChat;//单聊
    

    EMError *error = nil;
    
    id <IChatManager> chatManager = [[EaseMob sharedInstance] chatManager];
//    [chatManager asyncResendMessage:message progress:nil];
    [chatManager sendMessage:message progress:nil error:&error];
    if (error) {
        UIAlertView * a = [[UIAlertView alloc] initWithTitle:@"error" message:@"发送失败" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [a show];
    }
    [self addMessage:message];
//    }else {
//        textview.text = [NSString stringWithFormat:@"%@\n\t\t\t\t\t我说:%@",textview.text,sendContext.text];
//    }
}
-(void)sendImage:(id)button{
    //打开相册选择图片,然后发送.
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];//sourceType用来确定用户界面显示的样式,三种(照相,相册,图画.)
    [picker setVideoQuality:UIImagePickerControllerQualityTypeLow];//如果有视频,设定视频的质量.
    picker.delegate = self ;
    [self presentViewController:picker animated:YES completion:^{
    }];
}

#pragma mark - 接收消息

/*!
 @method
 @brief 收到消息时的回调
 @param message      消息对象
 @discussion 当EMConversation对象的enableReceiveMessage属性为YES时, 会触发此回调
 针对有附件的消息, 此时附件还未被下载.
 附件下载过程中的进度回调请参考didFetchingMessageAttachments:progress:,
 下载完所有附件后, 回调didMessageAttachmentsStatusChanged:error:会被触发
 */
-(void)didReceiveMessage:(EMMessage *)message
{
    NSLog(@"%s",__func__);
    if ([conversation.chatter isEqualToString:message.conversationChatter]) {
        [self addMessage:message];
    }
//    if ([conversation.chatter isEqualToString:message.conversationChatter]) {
//        [self addMessage:message];
//        if ([self shouldAckMessage:message read:NO])
//        {
//            [self sendHasReadResponseForMessages:@[message]];
//        }
//        if ([self shouldMarkMessageAsRead])
//        {
//            [self markMessagesAsRead:@[message]];
//        }
//    }
}
/*!
 @method
 @brief 收到消息时的回调
 @param cmdMessage      消息对象
 @discussion 当EMConversation对象的enableReceiveMessage属性为YES时, 会触发此回调
 针对有附件的消息, 此时附件还未被下载.
 附件下载过程中的进度回调请参考didFetchingMessageAttachments:progress:,
 下载完所有附件后, 回调didMessageAttachmentsStatusChanged:error:会被触发
 */
-(void)didReceiveCmdMessage:(EMMessage *)message
{
        NSLog(@"%s",__func__);//然并卵
//    if ([_conversation.chatter isEqualToString:message.conversationChatter]) {
//        [self showHint:NSLocalizedString(@"receiveCmd", @"receive cmd message")];
//    }
}


-(void)didUnreadMessagesCountChanged
{
    NSLog(@"%s",__func__);
}

#pragma  mark - UITableView datasource & delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id obj = [self.messages objectAtIndex:indexPath.row];
    
    MessageModel *model = (MessageModel *)obj;
    NSString *cellIdentifier = [EMChatViewCell cellIdentifierForMessageModel:model];//拼接好一个cellid
    NSLog(@"%@",cellIdentifier);
    EMChatViewCell *cell = (EMChatViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[EMChatViewCell alloc] initWithMessageModel:model reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.messageModel = model;//加完子控件以后再确定高度,再确定frame
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *obj = [self.messages objectAtIndex:indexPath.row];
//    if ([obj isKindOfClass:[NSString class]]) {
//        return 40;
//    }
//    else{
        return [EMChatViewCell tableView:tableView heightForRowAtIndexPath:indexPath withObject:(MessageModel *)obj];
//    }
}



- (NSArray *)formatMessages:(NSArray *)messagesArray
{
    NSMutableArray *formatArray = [[NSMutableArray alloc] init];
    if ([messagesArray count] > 0) {
        for (EMMessage *message in messagesArray) {
            NSDate *createDate = [NSDate dateWithTimeIntervalInMilliSecondSince1970:(NSTimeInterval)message.timestamp];
            //如果要显示时间需要下面的.
//            NSTimeInterval tempDate = [createDate timeIntervalSinceDate:self.chatTagDate];
//            if (tempDate > 60 || tempDate < -60 || (self.chatTagDate == nil)) {
//                [formatArray addObject:[createDate formattedTime]];
//                self.chatTagDate = createDate;//获得信息的时间.
//            }
            
            MessageModel *model = [MessageModelManager modelWithMessage:message];
            //昵称这些都不需要//获得信息的时间.
//            if ([_delelgate respondsToSelector:@selector(nickNameWithChatter:)]) {
//                NSString *showName = [_delelgate nickNameWithChatter:model.username];
//                model.nickName = showName?showName:model.username;
//            }else {
//                model.nickName = model.username;
//            }
//            
//            if ([_delelgate respondsToSelector:@selector(avatarWithChatter:)]) {
//                model.headImageURL = [NSURL URLWithString:[_delelgate avatarWithChatter:model.username]];
//            }
            
            if (model) {
                [formatArray addObject:model];
            }
        }
    }
    
    return formatArray;
}

-(void)addMessage:(EMMessage *)message
{
    
//    [acc removeAllObjects];
//    [acc addObject:message];
    modelChange = [MessageModelManager modelWithMessage:message];
    NSLog(@"modelChange.type:%ld",(long)modelChange.type);
//    __weak chatWithUserController *weakSelf = self;
    dispatch_async(_messageQueue, ^{
        
//        [self.messages addObjectsFromArray:[weakSelf formatMessages:acc]];
        [self.messages addObject:modelChange];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [mytableview reloadData];
            //将UITableview滑到最低
            [mytableview scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    });
}

#pragma mark 将tableview滑到底部
//将tableview滑到底部
- (void)scrollViewToBottom:(BOOL)animated
{
//    if (mytableview.contentSize.height > mytableview.frame.size.height)
//    {
//        CGPoint offset = CGPointMake(0, mytableview.contentSize.height - mytableview.frame.size.height);
//        [mytableview setContentOffset:offset animated:animated];
//    }
    if (self.messages.count > 0 ) {
        NSLog(@"self.messages.count:%d",self.messages.count);
        [mytableview scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - UIImagePickerController Deletage
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //取消选择图片
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    //选择了图片.
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image)
    {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //将图片发送出去.
    //构造message信息
    EMChatImage *chatImage = [[EMChatImage alloc] initWithUIImage:image displayName:@"image.jpg"];
    id <IChatImageOptions> options = [[ChatImageOptions alloc] init];
    [options setCompressionQuality:0.6];//设置压缩比例为0.6
    [chatImage setImageOptions:options];
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithChatObject:chatImage];
    
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:userName bodies:@[body]];
    message.messageType = eMessageTypeChat; // 设置为单聊消息
    message.requireEncryption = NO;
    message.ext = nil;
    //发送消息
    [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil];//只负责发送数据
    
    //如果需要用到回调,请用以下方法
//    [[EaseMob sharedInstance].chatManager asyncSendMessage:message
//                                                  progress:nil
//                                                   prepare:^(EMMessage *message, EMError *error)
//    {
//       
//        
//    } onQueue:nil
//                                                completion:^(EMMessage *message, EMError *error)
//    {
////       id<IEMMessageBody> messageBody = [message.messageBodies firstObject];
//        NSMutableDictionary * messageBody = [message.messageBodies firstObject];
//        NSString * url = ((EMImageMessageBody *)messageBody).remotePath;
//
//        for (int i = 0; i<10; i++) {
//            MessageModel * mess = self.messages[i];
//            if ([mess.messageId isEqualToString:message.messageId]) {
//                mess.imageRemoteURL = [NSURL URLWithString:url];
//                self.messages[i] = mess;
//            }
//        }
//    } onQueue:nil];
    
    [self addMessage:message];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark - UITextView Delegate
-(void) textViewDidChange:(UITextView *)inTextView {
    
    
    CGRect textFrame=[[sendContext layoutManager]usedRectForTextContainer:[sendContext textContainer]];
    CGFloat height = textFrame.size.height;
    
    if (height<36) {
        //设置高度为36；
        
        CGRect rect =  editView.frame;
        CGFloat Y = rect.origin.y;
        CGFloat H = rect.size.height;
        rect.origin.y = Y+H -36;
        rect.size.height = 36;
        editView.frame = rect;
        
        sendContext.frame = CGRectMake(0, 0, Swidth-100, 36);
        currentInputTextHeight = 36;
        return;
    }
    //当字体的大小 < currentInputTextHeight的时候就将UITextView的高度减低。
    CGFloat delta = height - currentInputTextHeight;
    NSLog(@"%f,%f,%f",delta,height,currentInputTextHeight);
    if (delta == 0) {
        return;
    }else if (delta>0) {
        if (currentInputTextHeight > 50) {
            return;
        }
        [self adjustTextViewHeight:delta];
        currentInputTextHeight = height;
    }
    else{
        if ((currentInputTextHeight + delta)>40) {
            [self adjustTextViewHeight:delta];
            currentInputTextHeight = currentInputTextHeight + delta;

        }
    }
    
}

-(void)adjustTextViewHeight:(CGFloat)delta{
    [self.view bringSubviewToFront:sendContext];
    CGRect rect =     sendContext.frame;
    CGRect rect1  = editView.frame;
    if (delta>0) {
        
        
//        rect.origin.y = rect.origin.y - UITextViewTextFont;
        rect.size.height = UITextViewTextFont + rect.size.height;

        rect1.origin.y = rect1.origin.y - UITextViewTextFont;
        rect1.size.height = UITextViewTextFont + rect1.size.height;
    }else{
        
//        rect.origin.y = rect.origin.y + UITextViewTextFont;
        rect.size.height =  rect.size.height - UITextViewTextFont;
        
        rect1.origin.y = rect1.origin.y + UITextViewTextFont;
        rect1.size.height = rect1.size.height - UITextViewTextFont;
    }
    
    sendContext.frame = rect;
    editView.frame = rect1;
}

#pragma mark - UIResponder actions
- (void)routerEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userInfo
{
    MessageModel *model = [userInfo objectForKey:KMESSAGEKEY];
    if ([eventName isEqualToString:kRouterEventTextURLTapEventName]) {
        [self chatTextCellUrlPressed:[userInfo objectForKey:@"url"]];
    }
    else if ([eventName isEqualToString:kRouterEventAudioBubbleTapEventName]) {
//        [self chatAudioCellBubblePressed:model];
    }
    else if ([eventName isEqualToString:kRouterEventImageBubbleTapEventName]){
        [self chatImageCellBubblePressed:model];
    }
    else if ([eventName isEqualToString:kRouterEventLocationBubbleTapEventName]){
//        [self chatLocationCellBubblePressed:model];
    }
    else if([eventName isEqualToString:kResendButtonTapEventName]){
        EMChatViewCell *resendCell = [userInfo objectForKey:kShouldResendCell];
        MessageModel *messageModel = resendCell.messageModel;
        if ((messageModel.status != eMessageDeliveryState_Failure) && (messageModel.status != eMessageDeliveryState_Pending))
        {
            return;
        }
        id <IChatManager> chatManager = [[EaseMob sharedInstance] chatManager];
        [chatManager asyncResendMessage:messageModel.message progress:nil];
        NSIndexPath *indexPath = [mytableview indexPathForCell:resendCell];
        [mytableview beginUpdates];
        [mytableview reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
        [mytableview endUpdates];
    }else if([eventName isEqualToString:kRouterEventChatCellVideoTapEventName]){
//        [self chatVideoCellPressed:model];
    }else if ([eventName isEqualToString:kRouterEventMenuTapEventName]) {
//        [self sendTextMessage:[userInfo objectForKey:@"text"]];
    }
}





//链接被点击
- (void)chatTextCellUrlPressed:(NSURL *)url
{
    if (url) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

//// 语音的bubble被点击
//-(void)chatAudioCellBubblePressed:(MessageModel *)model
//{
//    id <IEMFileMessageBody> body = [model.message.messageBodies firstObject];
//    EMAttachmentDownloadStatus downloadStatus = [body attachmentDownloadStatus];
//    if (downloadStatus == EMAttachmentDownloading) {
////        [self showHint:NSLocalizedString(@"message.downloadingAudio", @"downloading voice, click later")];
//        return;
//    }
//    else if (downloadStatus == EMAttachmentDownloadFailure)
//    {
////        [self showHint:NSLocalizedString(@"message.downloadingAudio", @"downloading voice, click later")];
//        [[EaseMob sharedInstance].chatManager asyncFetchMessage:model.message progress:nil];
//        
//        return;
//    }
//    
//    // 播放音频
//    if (model.type == eMessageBodyType_Voice) {
//        //发送已读回执
//        if ([self shouldAckMessage:model.message read:YES])
//        {
//            [self sendHasReadResponseForMessages:@[model.message]];
//        }
//        __weak ChatViewController *weakSelf = self;
//        BOOL isPrepare = [self.messageReadManager prepareMessageAudioModel:model updateViewCompletion:^(MessageModel *prevAudioModel, MessageModel *currentAudioModel) {
//            if (prevAudioModel || currentAudioModel) {
//                [weakSelf.tableView reloadData];
//            }
//        }];
//        
//        if (isPrepare) {
//            _isPlayingAudio = YES;
//            __weak ChatViewController *weakSelf = self;
//            [[EMCDDeviceManager sharedInstance] enableProximitySensor];
//            [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath:model.chatVoice.localPath completion:^(NSError *error) {
//                [weakSelf.messageReadManager stopMessageAudioModel];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [weakSelf.tableView reloadData];
//                    weakSelf.isPlayingAudio = NO;
//                    [[EMCDDeviceManager sharedInstance] disableProximitySensor];
//                });
//            }];
//        }
//        else{
//            _isPlayingAudio = NO;
//        }
//    }
//}

// 位置的bubble被点击
//-(void)chatLocationCellBubblePressed:(MessageModel *)model
//{
//    _isScrollToBottom = NO;
//    LocationViewController *locationController = [[LocationViewController alloc] initWithLocation:CLLocationCoordinate2DMake(model.latitude, model.longitude)];
//    [self.navigationController pushViewController:locationController animated:YES];
//}


//打开即时通讯
//- (void)chatVideoCellPressed:(MessageModel *)model
//{
//    EMVideoMessageBody *videoBody = (EMVideoMessageBody*)model.messageBody;
//    if (videoBody.attachmentDownloadStatus == EMAttachmentDownloadSuccessed)
//    {
//        NSString *localPath = model.message == nil ? model.localPath : [[model.message.messageBodies firstObject] localPath];
//        if (localPath && localPath.length > 0)
//        {
//            //发送已读回执
//            if ([self shouldAckMessage:model.message read:YES])
//            {
//                [self sendHasReadResponseForMessages:@[model.message]];
//            }
//            [self playVideoWithVideoPath:localPath];
//            return;
//        }
//    }
//    
//    __weak ChatViewController *weakSelf = self;
//    id <IChatManager> chatManager = [[EaseMob sharedInstance] chatManager];
//    [weakSelf showHudInView:weakSelf.view hint:NSLocalizedString(@"message.downloadingVideo", @"downloading video...")];
//    [chatManager asyncFetchMessage:model.message progress:nil completion:^(EMMessage *aMessage, EMError *error) {
//        [weakSelf hideHud];
//        if (!error) {
//            //发送已读回执
//            if ([weakSelf shouldAckMessage:model.message read:YES])
//            {
//                [weakSelf sendHasReadResponseForMessages:@[model.message]];
//            }
//            NSString *localPath = aMessage == nil ? model.localPath : [[aMessage.messageBodies firstObject] localPath];
//            if (localPath && localPath.length > 0) {
//                [weakSelf playVideoWithVideoPath:localPath];
//            }
//        }else{
//            [weakSelf showHint:NSLocalizedString(@"message.videoFail", @"video for failure!")];
//        }
//    } onQueue:nil];
//}

//播放视频是路径
//- (void)playVideoWithVideoPath:(NSString *)videoPath
//{
//    _isScrollToBottom = NO;
//    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
//    MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
//    [moviePlayerController.moviePlayer prepareToPlay];
//    moviePlayerController.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
//    [self presentMoviePlayerViewControllerAnimated:moviePlayerController];
//}

// 图片的bubble被点击
-(void)chatImageCellBubblePressed:(MessageModel *)model
{
    __weak chatWithUserController *weakSelf = self;
    id <IChatManager> chatManager = [[EaseMob sharedInstance] chatManager];
    if ([model.messageBody messageBodyType] == eMessageBodyType_Image) {
        EMImageMessageBody *imageBody = (EMImageMessageBody *)model.messageBody;
        if (imageBody.thumbnailDownloadStatus == EMAttachmentDownloadSuccessed) {
            if (imageBody.attachmentDownloadStatus == EMAttachmentDownloadSuccessed)
            {
                //发送已读回执
                if ([self shouldAckMessage:model.message read:YES])
                {
                    [self sendHasReadResponseForMessages:@[model.message]];
                }
                NSString *localPath = model.message == nil ? model.localPath : [[model.message.messageBodies firstObject] localPath];
                if (localPath && localPath.length > 0) {
                    UIImage *image = [UIImage imageWithContentsOfFile:localPath];
//                    self.isScrollToBottom = NO;//标记是否滑到最下面,(不用理)
                    if (image)
                    {
                        [self.messageReadManager showBrowserWithImages:@[image]];
                    }
                    else
                    {
                        NSLog(@"Read %@ failed!", localPath);
                    }
                    return ;
                }
            }
            [weakSelf showHudInView:weakSelf.view hint:NSLocalizedString(@"message.downloadingImage", @"downloading a image...")];
            [chatManager asyncFetchMessage:model.message progress:nil completion:^(EMMessage *aMessage, EMError *error) {
//                [weakSelf hideHud];
                if (!error) {
                    //发送已读回执
                    if ([weakSelf shouldAckMessage:model.message read:YES])
                    {
                        [weakSelf sendHasReadResponseForMessages:@[model.message]];
                    }
                    NSString *localPath = aMessage == nil ? model.localPath : [[aMessage.messageBodies firstObject] localPath];
                    if (localPath && localPath.length > 0) {
                        UIImage *image = [UIImage imageWithContentsOfFile:localPath];
//                        weakSelf.isScrollToBottom = NO;
                        if (image)
                        {
                            [weakSelf.messageReadManager showBrowserWithImages:@[image]];
                        }
                        else
                        {
                            NSLog(@"Read %@ failed!", localPath);
                        }
                        return ;
                    }
                }
//                [weakSelf showHint:NSLocalizedString(@"message.imageFail", @"image for failure!")];
            } onQueue:nil];
        }else{
            //获取缩略图
            [chatManager asyncFetchMessageThumbnail:model.message progress:nil completion:^(EMMessage *aMessage, EMError *error) {
                if (!error) {
                    [weakSelf reloadTableViewDataWithMessage:model.message];
                }else{
//                    [weakSelf showHint:NSLocalizedString(@"message.thumImageFail", @"thumbnail for failure!")];
                }
                
            } onQueue:nil];
        }
    }else if ([model.messageBody messageBodyType] == eMessageBodyType_Video) {
        //获取缩略图
        EMVideoMessageBody *videoBody = (EMVideoMessageBody *)model.messageBody;
        if (videoBody.thumbnailDownloadStatus != EMAttachmentDownloadSuccessed) {
            [chatManager asyncFetchMessageThumbnail:model.message progress:nil completion:^(EMMessage *aMessage, EMError *error) {
                if (!error) {
                    
                    [weakSelf reloadTableViewDataWithMessage:model.message];
                }else{
//                    [weakSelf showHint:NSLocalizedString(@"message.thumImageFail", @"thumbnail for failure!")];
                }
            } onQueue:nil];
        }
    }
}

//是否被阅读
- (BOOL)shouldAckMessage:(EMMessage *)message read:(BOOL)read
{
    NSString *account = [[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername];
    if (message.messageType != eMessageTypeChat || message.isReadAcked || [account isEqualToString:message.from] || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) )
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
//发送已读回执
- (void)sendHasReadResponseForMessages:(NSArray*)messages
{
    dispatch_async(_messageQueue, ^{
        for (EMMessage *message in messages)
        {
            [[EaseMob sharedInstance].chatManager sendReadAckForMessage:message];
        }
    });
}

- (void)reloadTableViewDataWithMessage:(EMMessage *)message{
    __weak chatWithUserController *weakSelf = self;
    dispatch_async(_messageQueue, ^{
        if ([userName isEqualToString:message.conversationChatter])
        {
            for (int i = 0; i < _messages.count; i ++) {
                id object = [weakSelf.messages objectAtIndex:i];
                if ([object isKindOfClass:[MessageModel class]]) {
                    MessageModel *model = (MessageModel *)object;
                    if ([message.messageId isEqualToString:model.messageId]) {
                        MessageModel *cellModel = [MessageModelManager modelWithMessage:message];
                        if ([self->_delegate respondsToSelector:@selector(nickNameWithChatter:)]) {
                            NSString *showName = [self->_delegate nickNameWithChatter:model.username];
                            cellModel.nickName = showName?showName:cellModel.username;
                        }else {
                            cellModel.nickName = cellModel.username;
                        }
                        
                        if ([self->_delegate respondsToSelector:@selector(avatarWithChatter:)]) {
                            cellModel.headImageURL = [NSURL URLWithString:[self->_delegate avatarWithChatter:cellModel.username]];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [mytableview beginUpdates];
                            [weakSelf.messages replaceObjectAtIndex:i withObject:cellModel];
                            [mytableview reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                            [mytableview endUpdates];
                        });
                        break;
                    }
                }
            }
        }
    });
}


@end
