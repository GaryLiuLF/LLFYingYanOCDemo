//
//  TraceHistoryVC.h
//  YingyanOCDemo
//
//  Created by gary.liu on 16/11/16.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TraceHistoryVC : UIViewController

@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) long long endTime;
@property (nonatomic, copy) NSString *entityName;
@property (nonatomic, assign) int serviceID;

@end
