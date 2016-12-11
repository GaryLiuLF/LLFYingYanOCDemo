//
//  HistoryPoint.h
//  YingyanOCDemo
//
//  Created by gary.liu on 16/11/17.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
// 历史轨迹点
@interface HistoryPoint : NSObject

@property (nonatomic, assign) float latitude;
@property (nonatomic, assign) float longitude;
@property (nonatomic, assign) int loctime;

@end
