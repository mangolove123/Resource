# Resource

最近的公司有个需求，需要做客户端播放远程视频。本来需求很简单，只要能播放、暂停、拖动进度就行啦。
原定技术方案使用系统自带的播放`controller`，结果经过调研发现系统播放器`controller` 有很多问题，原因如下：

``` 
注意：apple 原来提供的播放类
 视频播放（播放基类）

 1> AVPlayer
 能播放本地、远程的音频、视频文件
 基于Layer显示，得自己去编写控制面板
 
 2> MPMoviePlayerController 
 能播放本地、远程的音频、视频文件
 自带播放控制面板（暂停、播放、播放进度、是否要全屏）
注意：关于MPMoviePlayerController 我们看一下官方文档是这样说的：The MPMoviePlayerController class is formally deprecated in iOS 9
 
 3> AVPlayerViewController 
 能播放本地、远程的音频、视频文件
 内部是封装了MPMoviePlayerController
 播放界面默认就是全屏的
 如果播放功能比较简单，仅仅是简单地播放远程、本地的视频文件，建议用这个
 
注意：关于AVPlayerViewController 我们看一下官方文档是这样说的：Available in iOS 8.0 and later

```

完蛋了，梦想破灭了，本来想一劳永逸，结果：
 `MPMoviePlayerController`  在iOS9以后被弃用，
 `AVPlayerViewController` 只能用于iOS8以后。我们的版本必须要支持iOS7以后。


好吧那就自己动手封装一个播放器吧！

先看看基本的模块架构设计吧：


![基本设计图](http://upload-images.jianshu.io/upload_images/652024-571a66aa77d5d350.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**OK！设计好了开始动手coder。**

先定义一个枚举：

```
typedef NS_ENUM(NSInteger,AVPlayerPlayState) {


    AVPlayerPlayStatePreparing = 0x0, // 准备播放
    AVPlayerPlayStateBeigin,       // 开始播放
    AVPlayerPlayStatePlaying,      // 正在播放
    AVPlayerPlayStatePause,        // 播放暂停
    AVPlayerPlayStateEnd,          // 播放结束
    AVPlayerPlayStateBufferEmpty,  // 没有缓存的数据供播放了
    AVPlayerPlayStateBufferToKeepUp,//有缓存的数据可以供播放
    
    AVPlayerPlayStateNotPlay,      // 不能播放
    AVPlayerPlayStateNotKnow       // 未知情况
};

```
改枚举指明了各种播放状态。


` Manager` 的实现是这样的，看一下.h文件：

```
@interface MFPlayerPlayVideoManager : NSObject

@property (nonatomic, weak) id<PlayVideoDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isPlaying;

+ (instancetype)sharedInstance;

- (void)playVideoFromhUrl:(NSURL *)url onView:(UIView *)playView;

- (CMTime)playerCurrentDuration;
- (CMTime)playerItemDuration;

- (void)updateMovieScrubberControl:(CGFloat)time;
- (void)setVideoFillMode:(NSString *)fillMode;

// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing:(CGFloat)tolerance;
// 拖动值发生改变
- (void)sliderScrubbing:(CGFloat)time;

// 播放控制
- (void)play;
- (void)pause;
- (void)resum;
- (void)stop;
- (void)clear;

@end

```

是的，这个` Manager` 是最核心的内，定义的方法也很简单，不用说相信你也看得懂。

当` Manager` 的业务发生变化需要对外通知 ` UIView` 的显示掉的时候，就调用这个代理：
` @property (nonatomic, weak) id<PlayVideoDelegate> delegate;` 

这样将业务逻辑和UI完全分开，` PlayVideoManager`  里面全是播放业务，` MFPlayerPlayVideoView`  里面全是UI显示相关联的。

当UI的改变需要控制业务的变化时，就调用` Manager`  对外暴露的方法：

```
// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing:(CGFloat)tolerance;
// 拖动值发生改变
- (void)sliderScrubbing:(CGFloat)time;

// 播放控制
- (void)play;
- (void)pause;
- (void)resum;
- (void)stop;
- (void)clear;
```



在` MFPlayerPlayVideoManager.h`   中有个比较蛋痛的东西，那就是是监听是否好友缓冲数据可以播放，理论上实现以下监听就可以啦：

```
    [self.mPlayerItem  addObserver:self
                        forKeyPath:@"playbackBufferEmpty"
                           options:NSKeyValueObservingOptionNew
                           context:kPlaybackBufferEmptyObservationContext];
    
    [self.mPlayerItem  addObserver:self
                        forKeyPath:@"playbackLikelyToKeepUp"
                           options:NSKeyValueObservingOptionNew
                           context:kPlaybackLikelyToKeepUpObservationContext];
```

这样当播放的缓冲数据没有的时候  `kPlaybackBufferEmptyObservationContext`  监听就会被回调，当网络OK又有缓冲数据的时候  `kPlaybackLikelyToKeepUpObservationContext`  监听就会被回调，能监听到这两个状态，我们就可以做一些自由发挥的操作了。比如没有冲昏的时候我们可以暂停，并给出用户友好提示，如果再次有缓存数据可以继续播放并界面做一些调整。

**很可惜，经过本人实验证明**:`kPlaybackBufferEmptyObservationContext`、`kPlaybackBufferEmptyObservationContext`监听的调用时机相当的混乱，没有缓存时`kPlaybackBufferEmptyObservationContext`会被回调，用户手动点击暂停方法也会被回调。`kPlaybackBufferEmptyObservationContext`再次获得缓冲数据会被回调，用户点击开始播放也会被回调。还有一些情况也会被回调。如果大家感兴趣可以自己打断点跟踪一些他们的回调

```
- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
```



所以，我在此将缓冲状态的监听放到了` rate` 里面：

``` 
       /* 监听 AVPlayer "rate" 属性 以便我们去更新播放进度控件. */
        [self.mPlayer addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kRateObservationContext];

```
在监听方法 ` observeValueForKeyPath:ofObject:change:context: `实现四这样的：

```
if (context == kRateObservationContext){

        /**
         *  暂停分两种：一个强制暂停（以就是点击了暂停按钮）
         *  另一种就是网络不好加载卡住了暂停。
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
         *  播放都一样
         */
        if (self.mPlayer.rate == 1) {
            _isForcusPause = NO;
            _isEmptyBufferPause = NO;
            NSLog(@"self.mPlayer.rate == 1----AVPlayerPlayStatePreparing");
            [self updateCurrentPlayStatus:AVPlayerPlayStateBeigin];
        }

    }
```

注意：`self.mPlayer.rate == 0` 标示目前是暂停状态，`self.mPlayer.rate == 1` 标示目前是播放状态。不管是什么原因导致的暂停和播放，`kRateObservationContext`监听都会被调用。`isForcusPause == YES` 标示的是强制暂停，是用户行为导致的。否则就是网络问题导致的暂停。


**Github源码**：
  https://github.com/wmf00032/Resource/tree/master/MFVideoBackPlayer
