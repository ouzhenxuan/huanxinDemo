/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "UIImageView+EMWebCache.h"
#import "EMChatImageBubbleView.h"
#import "UIImageView+WebCache.h"

NSString *const kRouterEventImageBubbleTapEventName = @"kRouterEventImageBubbleTapEventName";

@interface EMChatImageBubbleView ()
{
    UIButton * he;
}
@end

@implementation EMChatImageBubbleView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
    }
    
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize retSize = self.model.size;
    if (retSize.width == 0 || retSize.height == 0) {
        retSize.width = MAX_SIZE;
        retSize.height = MAX_SIZE;
    }
    if (retSize.width > retSize.height) {
        CGFloat height =  MAX_SIZE / retSize.width  *  retSize.height;
        retSize.height = height;
        retSize.width = MAX_SIZE;
    }else {
        CGFloat width = MAX_SIZE / retSize.height * retSize.width;
        retSize.width = width;
        retSize.height = MAX_SIZE;
    }
    
    return CGSizeMake(retSize.width + BUBBLE_VIEW_PADDING * 2 + BUBBLE_ARROW_WIDTH, 2 * BUBBLE_VIEW_PADDING + retSize.height);
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    frame.size.width -= BUBBLE_ARROW_WIDTH;
    frame = CGRectInset(frame, BUBBLE_VIEW_PADDING, BUBBLE_VIEW_PADDING);
    if (self.model.isSender) {
        frame.origin.x = BUBBLE_VIEW_PADDING;
    }else{
        frame.origin.x = BUBBLE_VIEW_PADDING + BUBBLE_ARROW_WIDTH;
    }
    
    frame.origin.y = BUBBLE_VIEW_PADDING;
    [self.imageView setFrame:frame];
}

#pragma mark - setter

- (void)setModel:(MessageModel *)model
{
    [super setModel:model];
    
    UIImage *image = _model.isSender ? _model.image : _model.thumbnailImage;
    if (!image) {
        image = _model.image;
        if (!image) {
#warning 没有加载图片
            
        [self.imageView sd_setImageWithURL:_model.imageRemoteURL placeholderImage:[UIImage imageNamed:@"imageDownloadFail.png"]];//加载网络图片吧
        } else {
             self.imageView.image = image;
        }
    } else {
        self.imageView.image = image;
    }
}

#pragma mark - public

-(void)bubbleViewPressed:(id)sender
{
    NSLog(@"按了一下");
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    CGSize size =  _imageView.frame.size;
    CGFloat iw = size.width;
    CGFloat ih = size.height;
    
    CGFloat percent = w/iw > h/ih ? h/ih : w/iw;//取小
    
    NSLog(@"%f,%f,%f",percent,w/iw,h/ih);
    
    
    he = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, w , h)];
    he.backgroundColor = [UIColor blackColor];
    [he addTarget:self action:@selector(hehe) forControlEvents:UIControlEventTouchUpInside];
    //利用多线程.当没有加载完图片之前一直转菊花.
    
    
    
    NSArray* windows = [UIApplication sharedApplication].windows;
    UIWindow * _window = [windows objectAtIndex:0];//获得最上面的window
    //keep the first subview
    if(_window.subviews.count > 0){
        UIView * view = [_window.subviews objectAtIndex:0];//获得最上面的view
        
        
        
        dispatch_queue_t queye;
        
        queye =  dispatch_queue_create("hehe", NULL);
        
        
        UIActivityIndicatorView * ac = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        [view addSubview:ac];
        NSLog(@"菊花在转了");
        
        UIImageView * i = [[UIImageView alloc] init];
        
        NSString * path = self.model.localPath;
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (image!=nil) {
            i.image = image;
        }else{
            [i sd_setImageWithURL:self.model.imageRemoteURL placeholderImage:[UIImage imageNamed:@"noImageBig.png"]];
            if (i.image == nil) {//如果没有找到图片
                i.image = self.model.image;
            }
        }
        
        i.frame = CGRectMake(0, 0, iw*percent, ih*percent);
        i.center = CGPointMake(w/2, h/2);
        i.userInteractionEnabled = NO;
        [he addSubview:i];
        
        
        [view addSubview:he];
//        dispatch_async(queye, ^{
//            //长时间处理
//            
//            
//            //从URL中获取图片
//            NSData * data = [NSData dataWithContentsOfURL:self.model.imageRemoteURL];
//            [imageV sd_setImageWithURL:self.model.imageRemoteURL placeholderImage:[UIImage imageNamed:@"noImageBig.png"]];
//            NSLog(@"下载好图片了？");
//            
//            
//            
//            //长时间处理结束，利用主线程处理结果
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"在这里更新页面");
//                
//                [ac removeFromSuperview];
//                if (data==nil) {
//                    image = self.model.image;
//                }else{
//                    image= [UIImage imageWithData:data];
//                }
//                UIImageView * i = [[UIImageView alloc] initWithImage:image];
//                i.frame = CGRectMake(0, 0, iw*percent, ih*percent);
//                i.center = CGPointMake(w/2, h/2);
//                i.userInteractionEnabled = NO;
//                [he addSubview:i];
//            });
//            
//            
//            
//            
//        });
        
        
        
        
    }
    
//    [self routerEventWithName:kRouterEventImageBubbleTapEventName
//                     userInfo:@{KMESSAGEKEY:self.model}];
}

-(void)hehe{
    [he removeFromSuperview];
    he = nil;
}

+(CGFloat)heightForBubbleWithObject:(MessageModel *)object
{
    CGSize retSize = object.size;
    if (retSize.width == 0 || retSize.height == 0) {
        retSize.width = MAX_SIZE;
        retSize.height = MAX_SIZE;
    }else if (retSize.width > retSize.height) {
        CGFloat height =  MAX_SIZE / retSize.width  *  retSize.height;
        retSize.height = height;
        retSize.width = MAX_SIZE;
    }else {
        CGFloat width = MAX_SIZE / retSize.height * retSize.width;
        retSize.width = width;
        retSize.height = MAX_SIZE;
    }
    return 2 * BUBBLE_VIEW_PADDING + retSize.height;
}

@end
