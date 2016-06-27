//
//  MyTestView.h
//  DrawTest
//
//  Created by Mango on 16/6/26.
//  Copyright © 2016年 Mango. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyPlayProgressViewDelegate <NSObject>
// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing;
// 拖动值发生改变
- (void)sliderScrubbing;
@end

@interface MyPlayProgressView : UIView

@property (nonatomic, weak) id<MyPlayProgressViewDelegate> delegate;

/* 最大最小值 */
@property (nonatomic, assign, readonly) CGFloat minimumValue;
@property (nonatomic, assign, readonly) CGFloat maximumValue;

/* 正常的进度值 */
@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) CGFloat trackValue;

// 背景色
@property (nonatomic, strong) UIColor *playProgressBackgoundColor;
@property (nonatomic, strong) UIColor *trackBackgoundColor;
@property (nonatomic, strong) UIColor *progressBackgoundColor;

@end
