//
//  AVPlayerPlayVideoView.m
//  VideoPayerTest
//
//  Created by Mango on 16/6/16.
//  Copyright © 2016年 Mango. All rights reserved.
//  博客地址：http://www.jianshu.com/users/f44f1b2d37a3
//

#import "MFPlayerPlayVideoView.h"
#import "MFPlayerPlayVideoManager.h"
#import "MyPlayProgressView.h"
#import "MBProgressHUD.h"

#define RGBCOLOR_HEX(hexColor) [UIColor colorWithRed: (((hexColor >> 16) & 0xFF))/255.0f         \
green: (((hexColor >> 8) & 0xFF))/255.0f          \
blue: ((hexColor & 0xFF))/255.0f                 \
alpha: 1]

@interface MFPlayerPlayVideoView () <PlayVideoDelegate, MyPlayProgressViewDelegate>

@end
@implementation MFPlayerPlayVideoView{
    
    UILabel *_currentPlayTimeLabel;
    UILabel *_totalPlayTimeLabel;

    UIView *_playerVideoView;
    MyPlayProgressView *_slider;
    UIButton *_playOrPauseBtn;
    
    UIView *_controlerView;
    MBProgressHUD *_loadingView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
 
        // 1. the view of video show
        _playerVideoView = [[UIView alloc] initWithFrame:self.bounds];
        _playerVideoView.backgroundColor = [UIColor blackColor];
        [self addSubview:_playerVideoView];
        
        // 4. 显示loading
        _loadingView = [[MBProgressHUD alloc] initWithView: self];
        _loadingView.userInteractionEnabled = YES;
        [self addSubview: _loadingView];
        
        _loadingView.labelText = @"加载中...";
        [_loadingView show: NO];
        
        
        _controlerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 42, self.frame.size.width, 42)];
        [self addSubview:_controlerView];
        _controlerView.alpha = 0.8f;
        _controlerView.backgroundColor = RGBCOLOR_HEX(0x4c4c4c);
        
        // 2. 播放暂停按钮
        CGFloat btnWith = 35;
        CGFloat btnHeight = btnWith;
        _playOrPauseBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, 0.5*(_controlerView.frame.size.height - btnHeight), btnWith, btnHeight)];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"vide_play_back_normal"] forState:UIControlStateNormal];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"vide_play_back_pause"] forState:UIControlStateSelected];
        [_controlerView addSubview:_playOrPauseBtn];
        [_playOrPauseBtn addTarget:self action:@selector(playBtnClick:)
                  forControlEvents:UIControlEventTouchUpInside];

        // 播放时长
        _currentPlayTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_playOrPauseBtn.frame.origin.x + _playOrPauseBtn.frame.size.width + 10, 0.5*(_controlerView.frame.size.height - 14), 60, 14)];
        _currentPlayTimeLabel.font = [UIFont systemFontOfSize:13];
        _currentPlayTimeLabel.textColor = [UIColor whiteColor];
        _currentPlayTimeLabel.text = @"00:00:00";
        [_controlerView addSubview:_currentPlayTimeLabel];
        
        CGPoint currentPlayCenter = _currentPlayTimeLabel.center;
        currentPlayCenter.y = _playOrPauseBtn.center.y;
        _currentPlayTimeLabel.center = currentPlayCenter;

        // 3. 拖动条
        _slider = [[MyPlayProgressView alloc] initWithFrame:CGRectMake(_currentPlayTimeLabel.frame.origin.x + _currentPlayTimeLabel.frame.size.width, 0.5*(_controlerView.frame.size.height - 44), self.frame.size.width - (_currentPlayTimeLabel.frame.origin.x + _currentPlayTimeLabel.frame.size.width)-70, 42)];
        [_controlerView addSubview:_slider];
        _slider.delegate = self;
        
        CGPoint sliderCenter = _slider.center;
        sliderCenter.y = _currentPlayTimeLabel.center.y;
        _slider.center = sliderCenter;
        _slider.playProgressBackgoundColor = RGBCOLOR_HEX(0xff7b06);
        _slider.trackBackgoundColor = RGBCOLOR_HEX(0xe0d4a3);
        
        // 播放总时长
        _totalPlayTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_slider.frame.origin.x + _slider.frame.size.width, 0.5*(_controlerView.frame.size.height - 14), 60, 14)];
        _totalPlayTimeLabel.font = [UIFont systemFontOfSize:13];
        _totalPlayTimeLabel.textColor = [UIColor whiteColor];
        _totalPlayTimeLabel.text = @"00:00:00";
        [_controlerView addSubview:_totalPlayTimeLabel];
        
        CGPoint totalPlayTimeCenter = _totalPlayTimeLabel.center;
        totalPlayTimeCenter.y = _playOrPauseBtn.center.y;
        _totalPlayTimeLabel.center = totalPlayTimeCenter;
    }
    return self;
}
-(void)dealloc{
    [[MFPlayerPlayVideoManager sharedInstance] clear];
}

- (void)bindData:(NSURL *)url{
    // 1. 初始化播放设置
    [[MFPlayerPlayVideoManager sharedInstance] playVideoFromhUrl:url onView:_playerVideoView];
    [MFPlayerPlayVideoManager sharedInstance].delegate = self;
}

/* 点击播放按钮 */
- (void)playBtnClick:(UIButton *)btn{
    
    if ([MFPlayerPlayVideoManager sharedInstance].isPlaying) {
        [[MFPlayerPlayVideoManager sharedInstance] pause];
    }else{
        [[MFPlayerPlayVideoManager sharedInstance] play];
    }
    
}
- (void)pauseClick {
    [[MFPlayerPlayVideoManager sharedInstance] pause];
}
- (void)resumClick {
    [[MFPlayerPlayVideoManager sharedInstance] resum];
}
- (void)stopClick{
    [[MFPlayerPlayVideoManager sharedInstance] stop];
}

// 开始拖动
- (void)beiginSliderScrubbing{
    [[MFPlayerPlayVideoManager sharedInstance] beiginSliderScrubbing];
}
// 结束拖动
- (void)endSliderScrubbing{
    [[MFPlayerPlayVideoManager sharedInstance] endSliderScrubbing];
    
}
// 拖动值发生改变
- (void)sliderScrubbing{
    
    CMTime playerDuration = [[MFPlayerPlayVideoManager sharedInstance] playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        
        float minValue = [_slider minimumValue];
        float maxValue = [_slider maximumValue];
        float value = [_slider value];
        
        double time = duration * (value - minValue) / (maxValue - minValue);
        [[MFPlayerPlayVideoManager sharedInstance] sliderScrubbing:time];
    }
}

#pragma mark - delegate 视频拖放进度发生改变

// 视频缓存进度
- (void)videoBufferDataProgress:(double)bufferProgress{
    _slider.trackValue = bufferProgress;
}

- (void)playProgressChange{
    
    CMTime playerDuration = [[MFPlayerPlayVideoManager sharedInstance] playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        _slider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [_slider minimumValue];
        float maxValue = [_slider maximumValue];
        double time = CMTimeGetSeconds([[MFPlayerPlayVideoManager sharedInstance] playerCurrentDuration]);
        
        double hoursElapsed = floor(time / (60.0*60));
        double minutesElapsed = fmod(time / 60, 60);
        double secondsElapsed = fmod(time, 60.0);
        _currentPlayTimeLabel.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", hoursElapsed, minutesElapsed, secondsElapsed];
        
        [_slider setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (void)initPlayerPlayback{
//    double interval = .1f;
    
    CMTime playerDuration = [[MFPlayerPlayVideoManager sharedInstance] playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
//        CGFloat width = CGRectGetWidth([_slider bounds]);
//        interval = 0.5f * duration / width;
        
        double hoursElapsed = floor(duration / (60.0*60));
        double minutesElapsed = fmod(duration / 60, 60);
        double secondsElapsed = fmod(duration, 60.0);
        _totalPlayTimeLabel.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", hoursElapsed, minutesElapsed, secondsElapsed];
        
        [[MFPlayerPlayVideoManager sharedInstance] updateMovieScrubberControl];
    }
}
- (void)playStatusChange:(AVPlayerPlayState)state{
    switch (state) {
        case AVPlayerPlayStatePreparing:
        {
            [_loadingView show:YES];
            _playOrPauseBtn.selected = NO;
        }
            break;
        case AVPlayerPlayStateBeigin:
        {
            [_loadingView hide:YES];
            _playOrPauseBtn.selected = YES;
        }
            break;
        case AVPlayerPlayStatePlaying:
        {
            
        }
            break;
        case AVPlayerPlayStatePause:
        {
            _playOrPauseBtn.selected = NO;
            [_loadingView hide:YES];
        }
            break;
        case AVPlayerPlayStateEnd:
        {
            _playOrPauseBtn.selected = NO;
        }
            break;
        case AVPlayerPlayStateBufferEmpty:
        {
            [_loadingView show:YES];
            _playOrPauseBtn.selected = NO;
        }
            break;
        case AVPlayerPlayStateBufferToKeepUp:
        {
            _playOrPauseBtn.selected = YES;
            [_loadingView hide:YES];
        }
            break;
            
        case AVPlayerPlayStateNotPlay:
        {
            [_loadingView hide:YES];
        }
            break;
        case AVPlayerPlayStateNotKnow:
        {
            [_loadingView hide:YES];
        }
            break;
        default:
            break;
    }
}

@end
