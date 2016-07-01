//
//  NativieVideoManager.h
//  VideoPayerTest
//
//  Created by Mango on 16/6/16.
//  Copyright © 2016年 Mango. All rights reserved.
//  博客地址：http://www.jianshu.com/users/f44f1b2d37a3
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,AVPlayerPlayState) {
    
    AVPlayerPlayStatePreparing = 0x0, // 准备播放
    AVPlayerPlayStateBeigin,       // 开始播放
    AVPlayerPlayStatePlaying,      // 正在播放
    AVPlayerPlayStatePause,        // 播放暂停
    AVPlayerPlayStateEnd,          // 播放结束
    AVPlayerPlayStateBufferEmpty,  // 没有缓存的数据供播放了
    AVPlayerPlayStateBufferToKeepUp,//有缓存的数据可以供播放
    
    AVPlayerPlayStateNotPlay,      // 不能播放
    AVPlayerPlayStateNotKnow       // 未知情况
};

@protocol PlayVideoDelegate <NSObject>

// 更新进度条的值
- (void)playProgressChange;
- (void)initPlayerPlayback;
- (void)playStatusChange:(AVPlayerPlayState)state;

// 视频缓冲数据进度
- (void)videoBufferDataProgress:(double)bufferProgress;

@end

/**
   主要用于播放本地视频，和网络视频
 
 注意：apple 原来提供的播放类
 视频播放
 1> AVPlayer
 能播放本地、远程的音频、视频文件
 基于Layer显示，得自己去编写控制面板
 
 2> MPMoviePlayerController （The MPMoviePlayerController class is formally deprecated in iOS 9）
 能播放本地、远程的音频、视频文件
 自带播放控制面板（暂停、播放、播放进度、是否要全屏）
 
 3> AVPlayerViewController （Available in iOS 8.0 and later ）
 能播放本地、远程的音频、视频文件
 内部是封装了MPMoviePlayerController
 播放界面默认就是全屏的
 如果播放功能比较简单，仅仅是简单地播放远程、本地的视频文件，建议用这个
 
 MPMoviePlayerController 在iOS9以后被弃用，
 AVPlayerViewController只能用于iOS8以后。我们的版本必须要支持iOS7以后
 
 */
@interface MFPlayerPlayVideoManager : NSObject

@property (nonatomic, weak) id<PlayVideoDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isPlaying;

+ (instancetype)sharedInstance;

- (void)playVideoFromhUrl:(NSURL *)url onView:(UIView *)playView;

- (CMTime)playerCurrentDuration;
- (CMTime)playerItemDuration;

- (void)updateMovieScrubberControl;
- (void)setVideoFillMode:(NSString *)fillMode;

// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing;
// 拖动值发生改变
- (void)sliderScrubbing:(CGFloat)time;

// 播放控制
- (void)play;
- (void)pause;
- (void)resum;
- (void)stop;
- (void)clear;

@end
