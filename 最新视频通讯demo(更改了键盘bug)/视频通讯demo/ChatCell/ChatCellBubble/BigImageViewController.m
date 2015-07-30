//
//  BigImageViewController.m
//  视频通讯demo
//
//  Created by ozx on 15/7/21.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "BigImageViewController.h"

@implementation BigImageViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    UIImageView * image = [[UIImageView alloc] initWithFrame:self.view.frame];
    image.image = _image;
    
    [self.view addSubview:image];
    
}

@end
