//
//  ViewController.m
//  视频通讯demo
//
//  Created by ozx on 15/7/15.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "ViewController.h"
#import "EMError.h"
#import "EaseMob.h"
#import "chatViewController.h"
#import "publicValue.h"

#define Swidth [UIScreen mainScreen].bounds.size.width
#define Sheight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()
{
    UITextField * name ;
    UITextField * password;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%s",__func__);
    
    //判断是否已经登录
    BOOL isAutoLogin = [[EaseMob sharedInstance].chatManager isAutoLoginEnabled];
    
    NSString *name1 =[[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername];
    
    
    if (isAutoLogin) {
        [self thisToChatViewController];
    }
    self.title = @"login";
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupLogin];

    
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"%s",__func__);
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupLogin{
    name =  [[UITextField alloc] initWithFrame:CGRectMake(30, 100, Swidth-60, 30)];
    password = [[UITextField alloc] initWithFrame:CGRectMake(30, 150, Swidth-60, 30)];
    [self.view addSubview:name];
    [self.view addSubview:password];
    
    name.font = [UIFont fontWithName:@"ArialMT"size:18];
    name.placeholder = @"123.";
    [name setBorderStyle:UITextBorderStyleBezel];
    name.backgroundColor = [UIColor grayColor];
    
    password.font = [UIFont fontWithName:@"ArialMT"size:18];
    password.placeholder = @"123.";
    [password setBorderStyle:UITextBorderStyleBezel];
    password.backgroundColor = [UIColor grayColor];
    
    UIButton *btn_register = [[UIButton alloc] initWithFrame:CGRectMake(30, 200, 50, 40)];
    UIButton *btn_login = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 50, 40)];
    UIButton *btn_signout = [[UIButton alloc] initWithFrame:CGRectMake(180, 200, 50, 40)];
    
    [btn_signout setBackgroundColor:[UIColor orangeColor]];
    [btn_signout setTitle:@"退出" forState:UIControlStateNormal];
    [btn_signout setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:btn_signout];
    [btn_signout addTarget:self action:@selector(signout) forControlEvents:UIControlEventTouchUpInside];
    
    [btn_login setBackgroundColor:[UIColor orangeColor]];
    [btn_login setTitle:@"登录" forState:UIControlStateNormal];
    [btn_login setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [btn_register setBackgroundColor:[UIColor orangeColor]];
    [btn_register setTitle:@"注册" forState:UIControlStateNormal];
    [btn_register setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.view addSubview:btn_register];
    [self.view addSubview:btn_login];
    
    
    [btn_register addTarget:self action:@selector(UserRegister) forControlEvents:UIControlEventTouchUpInside];
    [btn_login addTarget:self action:@selector(UserLogin) forControlEvents:UIControlEventTouchUpInside];
}


-(void)UserRegister{
    BOOL a = [self isEmpty];
    if (!a) {
        
        //异步注册账号
        [[EaseMob sharedInstance].chatManager asyncRegisterNewAccount:name.text
                                                             password:password.text
                                                       withCompletion:
         ^(NSString *username, NSString *password, EMError *error) {
             
             if (!error) {
                 UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:@"注册成功，请登陆"
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             }else{
                 switch (error.errorCode) {
                     case EMErrorServerNotReachable:
                         TTAlertNoTitle(@"连接服务器失败");
                         break;
                     case EMErrorServerDuplicatedAccount:
                         TTAlertNoTitle(@"该用户已经申请过了");
                         break;
                     case EMErrorNetworkNotConnected:
                         TTAlertNoTitle(@"没有网络连接");
                         break;
                     case EMErrorServerTimeout:
                         TTAlertNoTitle(@"超时");
                         break;
                     default:
                         TTAlertNoTitle(@"其他错误,反正一大堆拉");
                         break;
                 }
             }
         } onQueue:nil];
    }
    
}

#pragma mark -自动登录
- (void)willAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    
    NSLog(@"%s",__func__);
}

- (void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    NSLog(@"%s",__func__);
}

-(void)UserLogin{
    BOOL a = [self isEmpty];
    if (!a) {
    
    
        //异步登陆账号
        [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:name.text
                                                            password:password.text
                                                          completion:
         ^(NSDictionary *loginInfo, EMError *error) {
             
             if (loginInfo && !error) {
                 //设置是否自动登录
                 [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:YES];
                 
                 // 旧数据转换 (如果您的sdk是由2.1.2版本升级过来的，需要家这句话)
                 [[EaseMob sharedInstance].chatManager importDataToNewDatabase];
                 //获取数据库中数据
                 [[EaseMob sharedInstance].chatManager loadDataFromDatabase];
                 
                 //获取群组列表
                 [[EaseMob sharedInstance].chatManager asyncFetchMyGroupsList];
                 
#warning 开始跳转,然后开始聊天
                 NSLog(@"登录成功");
                 TTAlertNoTitle(@"登录成功");
                 
                 [self thisToChatViewController];
                 //发送自动登陆状态通知
                 //             [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@YES];
                 
             }
             else
             {
                 switch (error.errorCode)
                 {
                     case EMErrorNotFound:
                         TTAlertNoTitle(error.description);
                         break;
                     case EMErrorNetworkNotConnected:
                         TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                         break;
                     case EMErrorServerNotReachable:
                         TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                         break;
                     case EMErrorServerAuthenticationFailure:
                         TTAlertNoTitle(error.description);
                         break;
                     case EMErrorServerTimeout:
                         TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                         break;
                     default:
                         TTAlertNoTitle(NSLocalizedString(@"login.fail", @"Login failure"));
                         break;
                 }
             }
         } onQueue:nil];
    }
    
}

-(void)thisToChatViewController{
    chatViewController * chatVc = [[chatViewController alloc] init];
    UIButton * b = (UIButton *) chatVc.navigationItem.backBarButtonItem ;
//    chatVc.navigationItem.backBarButtonItem.title = @"hehe";
    [b addTarget:self action:@selector(back ) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController pushViewController:chatVc animated:YES];
    
}


-(void)signout{
    NSLog(@"laidaozhe ");
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
        if (!error && info) {
            NSLog(@"退出成功");
        }
    } onQueue:nil];
}



void TTAlertNoTitle(NSString* message) {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (BOOL)isEmpty{
    BOOL ret = NO;
    NSString *username = name.text;
    NSString *pas = password.text;
    if (username.length == 0 || pas.length == 0) {
        ret = YES;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"输入不能为空"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    return ret;
}

@end
