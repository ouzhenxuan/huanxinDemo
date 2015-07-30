//
//  publicValue.m
//  视频通讯demo
//
//  Created by ozx on 15/7/16.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "publicValue.h"

@implementation publicValue

+ (publicValue *)shareValue
{
    static publicValue *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}

@end
