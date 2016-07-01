//
//  MFPlayerPlayViewController.h
//  51talk
//
//  Created by Mango on 16/6/20.
//  Copyright © 2016年 Mango. All rights reserved.
//

#import <UIKit/UIKit.h>
/* 播放本或者在线视频 */
@interface MFPlayerPlayViewController : UIViewController

@property (nonatomic, copy) NSString *videoPlayUrl; // 地址
@property (nonatomic, assign) BOOL isLocalVideo;    // 区分本地视频和远程视频

@end
