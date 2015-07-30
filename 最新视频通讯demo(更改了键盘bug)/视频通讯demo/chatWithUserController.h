//
//  chatWithUserController.h
//  视频通讯demo
//
//  Created by ozx on 15/7/16.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol chatWithUserControllerDelegate <NSObject>

- (NSString *)avatarWithChatter:(NSString *)chatter;
- (NSString *)nickNameWithChatter:(NSString *)chatter;
@optional
-(void)markTheMes;

@end
@interface chatWithUserController : UIViewController

{
    NSString * userName ;
}

@property (nonatomic,copy) NSString *userName;
@property (nonatomic,assign) id<chatWithUserControllerDelegate> delegate;
@end
