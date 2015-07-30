//
//  publicValue.h
//  视频通讯demo
//
//  Created by ozx on 15/7/16.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface publicValue : NSObject

{
    BOOL isLogin;
}

+ (publicValue *)shareValue;
@end
