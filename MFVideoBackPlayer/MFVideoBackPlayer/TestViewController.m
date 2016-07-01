//
//  ViewController.m
//  MFVideoBackPlayer
//
//  Created by Mango on 16/6/29.
//  Copyright © 2016年 Mango. All rights reserved.
//  博客地址：http://www.jianshu.com/users/f44f1b2d37a3/latest_articles
//

#import "TestViewController.h"
#import "MFPlayerPlayViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)enterVideoPlayClick:(id)sender {

    MFPlayerPlayViewController *controller = [[MFPlayerPlayViewController alloc] init];
    /**
     *  播放远程视频 （去掉下面两行 注释代码）
     */
//    controller.videoPlayUrl = @"http://bm1.43.play.bokecc.com/flvs/ca/QxhMs/umkILXXGVl-10.mp4?t=1467200728&key=E9F6262005AA3015A7641ECD8A0711EB";
//    controller.isLocalVideo = NO;
    /**
     *  播放本地视频
     */
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"testvide.mp4" ofType:nil];
    controller.videoPlayUrl = videoPath;
    controller.isLocalVideo = YES;
    
    [self presentViewController:controller animated:YES completion:nil];
}

@end
