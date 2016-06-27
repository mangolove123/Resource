//
//  ViewController.m
//  DrawTest
//
//  Created by Mango on 16/6/26.
//  Copyright © 2016年 Mango. All rights reserved.
//

#import "ViewController.h"
#import "MyPlayProgressView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    MyPlayProgressView *myTestView = [[MyPlayProgressView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 50)];
    [self.view addSubview:myTestView];

    [UIView animateWithDuration:5 animations:^{
       
        myTestView.value = 1;
    }];
    [UIView animateWithDuration:3 animations:^{
        myTestView.trackValue = 1;
    }];
    
}


@end
