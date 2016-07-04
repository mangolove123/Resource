//
//  MFPlayerPlayViewController.m
//  51talk
//
//  Created by Mango on 16/6/20.
//  Copyright © 2016年 Mango. All rights reserved.
//  博客地址：http://www.jianshu.com/users/f44f1b2d37a3
//

#import "MFPlayerPlayViewController.h"
#import "MFPlayerPlayVideoView.h"

@implementation MFPlayerPlayViewController{

    MFPlayerPlayVideoView *_playVideoView;
    UIButton *_topBackbtn;
    
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
#pragma mark - deal with Rotation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    if ([self respondsToSelector: @selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self prefersStatusBarHidden];
        [self performSelector: @selector(setNeedsStatusBarAppearanceUpdate)];
    }
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat width = bounds.size.width < bounds.size.height ? bounds.size.height : bounds.size.width;
    CGFloat height = bounds.size.width < bounds.size.height ? bounds.size.width : bounds.size.height;
    CGRect tempFrame = self.view.frame;
    tempFrame.size.width = width;
    tempFrame.size.height = height;
    self.view.frame = tempFrame;
    
    // 1. 创建一个播放视频的 View
    _playVideoView = [[MFPlayerPlayVideoView alloc] initWithFrame:CGRectMake(0, 0, width,height)];
    _playVideoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_playVideoView];

    //顶部视图
    _topBackbtn = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 44, 44)];
    _topBackbtn.alpha = 0.6f;
    [_topBackbtn setTitle:@"返回" forState:UIControlStateNormal];
    [_topBackbtn addTarget:self action:@selector(clickBack:)
          forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: _topBackbtn];
    
    // 加载视频
    [self startLoadVideo];
}
- (void)clickBack:(UIButton *)btn{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  开始加载视频
 */
- (void)startLoadVideo{
        /* 注意：本地视频和远程视频创建的URL有点不一样 */
        NSURL *URL = nil;
        if (_isLocalVideo) {
            URL = [NSURL fileURLWithPath:_videoPlayUrl];
        }else{
            URL = [NSURL URLWithString:_videoPlayUrl];
        }
        [_playVideoView bindData:URL];
}


@end
