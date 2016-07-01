//
//  NativieVideoManager.m
//  VideoPayerTest
//
//  Created by Mango on 16/6/16.
//  Copyright © 2016年 Mango. All rights reserved.
//  博客地址：http://www.jianshu.com/users/f44f1b2d37a3
//

#import "MFPlayerPlayVideoManager.h"

static void *kRateObservationContext = &kRateObservationContext;
static void *kStatusObservationContext = &kStatusObservationContext;
static void *kCurrentItemObservationContext = &kCurrentItemObservationContext;
static void *kTimeRangesObservationContext = &kTimeRangesObservationContext;

/* 本地是否还有可用缓存视频流监听 */
static void *kPlaybackBufferEmptyObservationContext = &kPlaybackBufferEmptyObservationContext;
static void *kPlaybackLikelyToKeepUpObservationContext = &kPlaybackLikelyToKeepUpObservationContext;

static NSString *kRequestKeyPlayState = @"playable";

@interface MFPlayerPlayVideoManager ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AVPlayer *mPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, strong) AVPlayerItem *mPlayerItem;

@end

@implementation MFPlayerPlayVideoManager{
    
    AVPlayerItem *_currentPlayItem;
    float mRestoreAfterScrubbingRate;
    BOOL seekToZeroBeforePlay;
    id mTimeObserver;
    BOOL _isEnterBackgound;

    BOOL _isForcusPause;
    BOOL _isEmptyBufferPause;
    UIView *_currentPlayView;
    
}
+ (instancetype)sharedInstance{
    static MFPlayerPlayVideoManager *nativeNamager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nativeNamager = [[MFPlayerPlayVideoManager alloc] init];
    });
    return nativeNamager;
}
- (void)playVideoFromhUrl:(NSURL *)url onView:(UIView *)playView{
    
    if (_url != url) {
        
        _url = [url copy];
        _currentPlayView = playView;

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        NSArray *requestedKeys = @[kRequestKeyPlayState];
        
        /* 准备播放 */
        [_delegate playStatusChange:AVPlayerPlayStatePreparing];
        
        // 使用断言去加载指定额键值
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{
             dispatch_async( dispatch_get_main_queue(),
                ^{
                    [self prepareToPlayAsset:asset withKeys:requestedKeys];
                });
         }];
    }
}

#pragma mark - 私有方法

// 播放前准备
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys{
    /* 确保能够加载成功. */
    for (NSString *thisKey in requestedKeys){
        
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed){
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
    }
    
    /* 使用asset的playable属性去侦测是否能够加载成功. */
    if (!asset.playable){
        
        /* 生成一个错误的描述. */
        NSString *localizedDescription = NSLocalizedString(@"不能播放", @"未知错误不能播放");
        NSString *localizedFailureReason = NSLocalizedString(@"未知错误不能播放", @"不能播放原因");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* 展示一个错误信息给用户. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }

    /* 如果我们之前已经有了一个 AVPlayerItem notifications 就移除之前的. */
    if (self.mPlayerItem){

        [self.mPlayerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
    
    /* 从successfully loaded AVAsset中创建一个新的AVPlayerItem instance. */
    _mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self.mPlayerItem  addObserver:self
                        forKeyPath:@"playbackBufferEmpty"
                           options:NSKeyValueObservingOptionNew
                           context:kPlaybackBufferEmptyObservationContext];
    
    [self.mPlayerItem  addObserver:self
                        forKeyPath:@"playbackLikelyToKeepUp"
                           options:NSKeyValueObservingOptionNew
                           context:kPlaybackLikelyToKeepUpObservationContext];
    
    /* Observe the player 的 "status" key 去决定什么什么去播放. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:kStatusObservationContext];
    
    /* 已经缓冲的值 */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"loadedTimeRanges"
                          options:NSKeyValueObservingOptionNew
                          context:kTimeRangesObservationContext];
    
    /* 去监听当payer已经播放结束，可能要去做一些更新UI的操作*/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
    
    /**
     *  监听应用前后台切换
     *
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    seekToZeroBeforePlay = NO;
    
    /* 如果没有player就去创建一个新的. */
    if (!self.mPlayer){

        _mPlayer = [AVPlayer playerWithPlayerItem:self.mPlayerItem];
        
        /* 监听 AVPlayer "currentItem" 属性*/
        [self.mPlayer addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kCurrentItemObservationContext];

        /* 监听 AVPlayer "rate" 属性 以便我们去更新播放进度控件. */
        [self.mPlayer addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kRateObservationContext];
        
    }
    
    /* 确保最新的PlayerItem就是 self.mPlayer.currentItem. */
    if (self.mPlayer.currentItem != self.mPlayerItem){
        [self.mPlayer replaceCurrentItemWithPlayerItem:self.mPlayerItem];
        
    }

    // 1.创建一个 AVPlayerLayer
    self.avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:_mPlayer];
    [self.avPlayerLayer setFrame:_currentPlayView.bounds];
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_currentPlayView.layer addSublayer:self.avPlayerLayer];
    
    /* 开始播放 */
    [_delegate playStatusChange:AVPlayerPlayStateBeigin];
    [self.mPlayer play];
}

- (void)appEnteredForeground{
    NSLog(@"---EnteredForeground");
    //    _isEnterBackgound = NO;
    /**
     *  注意：appEnteredForeground 会在 AVPlayerItemStatusReadyToPlay（从后台回到前台会出发ReadyToPlay） 
     *  之后被调用，顾设置 _isEnterBackgound = NO 的操作放在了 AVPlayerItemStatusReadyToPlay 之中
     */
}
- (void)appEnteredBackground{
    NSLog(@"---EnteredBackground");
    _isEnterBackgound = YES;
    [self pause];
}
-(void)assetFailedToPrepareForPlayback:(NSError *)error{
    
    [self removePlayerTimeObserver];
    [self syncScrubber];

    [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"我知道了"
                                              otherButtonTitles:nil];
    [alertView show];
}
/* 当前是否正在播放视频 */
- (BOOL)isPlaying{
    return mRestoreAfterScrubbingRate != 0.f || [self.mPlayer rate] != 0.f;
}
/* 播放结束的时候回调这个方法. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* 视频播放结束，再次播放需要从0位置开始播放 */
    seekToZeroBeforePlay = YES;
    [self updateCurrentPlayStatus:AVPlayerPlayStateEnd];
}

/* 取消先前注册的观察者 */
-(void)removePlayerTimeObserver{
    if (mTimeObserver){
        [self.mPlayer removeTimeObserver:mTimeObserver];
        mTimeObserver = nil;
    }
}

- (void)updateCurrentPlayStatus:(AVPlayerPlayState)playState{
    [_delegate playStatusChange:playState];
}

/* 初始化播放状态. */
-(void)initScrubberTimer{
    [_delegate initPlayerPlayback];
}


- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" 属性值观察. */
    if (context == kStatusObservationContext){

        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* 未知播放状态，尝试着去加载一个错误的资源 */
            case AVPlayerItemStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* 一旦 AVPlayerItem 准备好了去播放, i.e.
                 duration 值就可以去捕获到 （从后台回到前台也会触发 ReadyToPlay）*/
                if (!_isEnterBackgound) {
                    [self initScrubberTimer];
                    [self updateCurrentPlayStatus:AVPlayerPlayStateBeigin];
                }else{
                    /**
                     *  如果是从后台回到前台，需要将 _isEnterBackgound = NO
                     */
                    _isEnterBackgound = NO;
                }
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }else if (context == kPlaybackBufferEmptyObservationContext){
        NSLog(@"----EmptyBuffer");
        
    }else if (context == kPlaybackLikelyToKeepUpObservationContext){
        NSLog(@"----Have Buffer");
    }
    /* AVPlayer "rate" 属性值观察. */
    else if (context == kRateObservationContext){

        /**
         *  暂停分两种：一个强制暂停（以就是点击了暂停按钮）
         *  另一种就是网络不好加载卡住了暂停。
         */
        if (self.mPlayer.rate == 0) {
            
            /* 缓存不够导致的暂停 */
            if (!_isForcusPause) {
                NSLog(@"self.mPlayer.rate == 0 && _isEmptyBuffer---AVPlayerPlayStatePreparing");
                [self updateCurrentPlayStatus:AVPlayerPlayStatePreparing];
                _isEmptyBufferPause = YES;
            }
            /* 正常情况下导致的暂停 */
            else{
                [self updateCurrentPlayStatus:AVPlayerPlayStatePause];
            }

        }
        /**
         *  播放都一样
         */
        if (self.mPlayer.rate == 1) {
            _isForcusPause = NO;
            _isEmptyBufferPause = NO;
            NSLog(@"self.mPlayer.rate == 1----AVPlayerPlayStatePreparing");
            [self updateCurrentPlayStatus:AVPlayerPlayStateBeigin];
        }

    }
    /* AVPlayer "currentItem" 属性值观察.
     当replaceCurrentItemWithPlayerItem方法回调发生的时候. */
    else if (context == kCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* 判断是否为空 */
        if (newPlayerItem == (id)[NSNull null]){
            [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];

        }else 
        {
            self.avPlayerLayer.player = self.mPlayer;
            [self setVideoFillMode:AVLayerVideoGravityResizeAspect];
        }
    }
    /* 已经缓冲的视频 */
    else if (context == kTimeRangesObservationContext){
        
        NSArray* times = self.mPlayerItem.loadedTimeRanges;
        
        // 取出数组中的第一个值
        NSValue* value = [times objectAtIndex:0];
        
        CMTimeRange range;
        [value getValue:&range];
        float start = CMTimeGetSeconds(range.start);
        float duration = CMTimeGetSeconds(range.duration);
        
        /* 得出缓存进度 */
        float videoAvailable = start + duration;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateVideoAvailable:videoAvailable];
        });
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

-(void)updateVideoAvailable:(float)videoAvailable {
    
    CMTime playerDuration = [self playerItemDuration];
    double progress = 0;
    /* 有可能播放器还没有准备好，playerDuration值为kCMTimeInvalid */
    if (playerDuration.value != 0) {
        double duration = CMTimeGetSeconds(playerDuration);
        progress = videoAvailable/duration;
        [_delegate videoBufferDataProgress:progress];
        /**
         *  如果因为缓冲被暂停的，如果缓冲值已经够了，需要重新播放
         */
        float minValue = 0;
        float maxValue = 1;
        double time = CMTimeGetSeconds([self playerCurrentDuration]);
        double sliderProgress = (maxValue - minValue) * time / duration + minValue;
        
        /**
         *  当前处于缓冲不够暂停状态时
         */
        if ((progress - sliderProgress) > 0.01 &&
            self.mPlayer.rate == 0 &&
            _isEmptyBufferPause) {
            
            [self play];
        }
    }
}


#pragma mark - 公共方法

- (CMTime)playerCurrentDuration{
    return [self.mPlayer currentTime];
}

- (CMTime)playerItemDuration{
    
    AVPlayerItem *playerItem = [_mPlayer currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}

- (void)updateMovieScrubberControl{
    
    __weak MFPlayerPlayVideoManager *weakSelf = self;
    mTimeObserver = [_mPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                           queue:NULL usingBlock:
                     ^(CMTime time)
                     {
                         [weakSelf syncScrubber];
                     }];
    
}

- (void)setVideoFillMode:(NSString *)fillMode{
    AVPlayerLayer *playerLayer = self.avPlayerLayer;
    playerLayer.videoGravity = fillMode;
}

#pragma mark - 播放状态控制
- (void)play{
    /* 如果视频正处于播发的结束位置，我们需要调回到初始位置
     进行播放. */
    if (YES == seekToZeroBeforePlay){
        seekToZeroBeforePlay = NO;
        [self.mPlayer seekToTime:kCMTimeZero];
    }
    [_mPlayer play];
}
- (void)pause{
    _isForcusPause = YES;
    [_mPlayer pause];
}
- (void)resum{
    [_mPlayer play];
}
- (void)stop{
    [self pause];
}

- (void)clear{
    
    [self removePlayerTimeObserver];
    [self.mPlayer removeObserver:self forKeyPath:@"rate"];
    [self.mPlayer removeObserver:self forKeyPath:@"currentItem"];
    
    [self.mPlayerItem  removeObserver:self forKeyPath:@"status"];
    [self.mPlayerItem  removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.mPlayerItem  removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.mPlayerItem  removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [self.mPlayer pause];
    
    self.mPlayer = nil;
    self.mPlayerItem = nil;
    self.avPlayerLayer = nil;
    
}
#pragma mark - 播放进度控制

// 开始拖动
- (void)beiginSliderScrubbing{
    
    /* 记录开始拖动前的状态，拖动的时候必须要暂停 */
    mRestoreAfterScrubbingRate = [_mPlayer rate];

    if (_isEmptyBufferPause) {
        /* 如果是当前网络问题，缓存不够导致的暂停 */
        [_mPlayer setRate:0.f];
    }else{
        /* 正常播放的情况下 */
        [self pause];
    }
}

// 拖动值发生改变
- (void)sliderScrubbing:(CGFloat)time{
    [_mPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {}];
}
// 结束拖动
- (void)endSliderScrubbing{
    
    if (!mTimeObserver){
        [self updateMovieScrubberControl];
    }
    
    /* 拖动结束了,得恢复拖动前的状态, (如果是非强制暂停的，以就是缓存不够导致的可以恢复播放 ) */
    if (mRestoreAfterScrubbingRate || !_isForcusPause){
        /* 拖动前是播放状态，这时候需要恢复播放 */
        [_mPlayer setRate:1.f];
        mRestoreAfterScrubbingRate = 0.f;
    }
}
- (void)syncScrubber{
    [_delegate playProgressChange];
}


@end
