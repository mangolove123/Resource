//
//  MyTestView.m
//  DrawTest
//
//  Created by Mango on 16/6/26.
//  Copyright © 2016年 Mango. All rights reserved.
//

#import "MyPlayProgressView.h"

/* 拖动按钮的宽度 */
#define kBtnWith 17

/* 整个bar的宽度 */
#define kMyPlayProgressViewWidth (self.frame.size.width - (kBtnWith*0.5)*2)
/* slider 的高度 */
#define  kPlayProgressBarHeight 3


@implementation MyPlayProgressView{
    
    UIView *_bgProgressView;         // 背景颜色
    UIView *_ableBufferProgressView; // 缓冲进度颜色
    UIView *_finishPlayProgressView; // 已经播放的进度颜色
    
    CGPoint _lastPoint;
    UIButton *_sliderBtn;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _minimumValue = 0.f;
        _maximumValue = 1.f;
        
        self.backgroundColor = [UIColor clearColor];

        CGFloat showY = (self.frame.size.height - kPlayProgressBarHeight)*0.5;
        
        /* 背景 */
        _bgProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, kMyPlayProgressViewWidth, kPlayProgressBarHeight)];
        _bgProgressView.backgroundColor = [UIColor blackColor];
        [self addSubview:_bgProgressView];
        
        /* 缓存进度 */
        _ableBufferProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
        _ableBufferProgressView.backgroundColor = [UIColor yellowColor];
        [self addSubview:_ableBufferProgressView];
        
        /* 播放进度 */
        _finishPlayProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
        _finishPlayProgressView.backgroundColor = [UIColor redColor];
        [self addSubview:_finishPlayProgressView];
        
        /* 滑动按钮 */
        _sliderBtn = [[MyProgressSliderBtn alloc] initWithFrame:CGRectMake(0, showY, 44, 44)];
        CGPoint center = _sliderBtn.center;
        center.x = _bgProgressView.frame.origin.x;
        center.y = _finishPlayProgressView.center.y;
        _sliderBtn.center = center;
        
        [_sliderBtn addTarget:self action:@selector(beiginSliderScrubbing) forControlEvents:UIControlEventTouchDown];
        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchCancel];
        [_sliderBtn addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpInside];
        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpOutside];
        _lastPoint = _sliderBtn.center;
        [self addSubview:_sliderBtn];
    }
    return self;
}

- (void)setPlayProgressBackgoundColor:(UIColor *)playProgressBackgoundColor{
    if (_playProgressBackgoundColor != playProgressBackgoundColor) {
         _finishPlayProgressView.backgroundColor = playProgressBackgoundColor;
    }
    
}

- (void)setTrackBackgoundColor:(UIColor *)trackBackgoundColor{
    if (_trackBackgoundColor != trackBackgoundColor) {
        _ableBufferProgressView.backgroundColor = trackBackgoundColor;
    }
}

- (void)setProgressBackgoundColor:(UIColor *)progressBackgoundColor{
    if (_progressBackgoundColor != progressBackgoundColor) {
        _bgProgressView.backgroundColor = progressBackgoundColor;
    }
}

/**
   进度值
 */
- (void)setValue:(CGFloat)progressValue{
    
    _value = progressValue;
    
    CGFloat finishValue = _bgProgressView.frame.size.width * progressValue;
    CGPoint tempPoint = _sliderBtn.center;
    tempPoint.x =  _bgProgressView.frame.origin.x + finishValue;
    
    if (tempPoint.x >= _bgProgressView.frame.origin.x &&
        tempPoint.x <= (self.frame.size.width - (kBtnWith*0.5))){
 
        _sliderBtn.center = tempPoint;
        _lastPoint = _sliderBtn.center;
        
        CGRect tempFrame = _finishPlayProgressView.frame;
        tempFrame.size.width = tempPoint.x;
        _finishPlayProgressView.frame = tempFrame;
    }

}

/**
   设置缓冲进度值
 */
-(void)setTrackValue:(CGFloat)trackValue{
    CGFloat finishValue = _bgProgressView.frame.size.width * trackValue;
    
    CGRect tempFrame = _ableBufferProgressView.frame;
    tempFrame.size.width = finishValue;
    _ableBufferProgressView.frame = tempFrame;
}

/**
   拖动值发生改变
 */
- (void) dragMoving: (UIButton *)btn withEvent:(UIEvent *)event{

    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    CGFloat offsetX = point.x - _lastPoint.x;
    CGPoint tempPoint = CGPointMake(btn.center.x + offsetX, btn.center.y);

    // 得到进度值
    CGFloat progressValue = (tempPoint.x - _bgProgressView.frame.origin.x)*1.0f/_bgProgressView.frame.size.width;
    [self setValue:progressValue];
    [_delegate sliderScrubbing];
}
// 开始拖动
- (void)beiginSliderScrubbing{
    [_delegate beiginSliderScrubbing];
}
// 结束拖动
- (void)endSliderScrubbing{
    [_delegate endSliderScrubbing];
}
@end


/**
 *  为了让拖动按钮变得更大
 */
@implementation MyProgressSliderBtn{
    UIImageView *_iconImageView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - 17)*0.5,
                                                                       0.5*(self.frame.size.height - 17),
                                                                       17, 17)];
        _iconImageView.backgroundColor = [UIColor whiteColor];
        _iconImageView.layer.cornerRadius = _iconImageView.frame.size.height*0.5;
        _iconImageView.layer.masksToBounds = YES;
        [self addSubview:_iconImageView];
    }
    return self;
}

@end


