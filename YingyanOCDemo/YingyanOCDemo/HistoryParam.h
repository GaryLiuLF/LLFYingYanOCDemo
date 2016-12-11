//
//  HistoryParam.h
//  YingyanOCDemo
//
//  Created by gary.liu on 16/11/16.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 交通方式，纠偏选项中的transport_mode选项的枚举
///
/// - driving: 驾车
/// - riding:  骑行
/// - walking: 步行
enum TransportMode: NSInteger {
    driving = 1,
    riding = 2,
    walking = 3,
};

/// 里程补偿方式，纠偏选项中的supplement_mode选项的枚举
///
/// - no_supplement: 不补充
/// - straight:      直线距离补充
/// - driving:       最短驾车路线距离补充
/// - riding:        最短骑行路线距离补充
/// - walking:       最短不行路线距离补充
//enum SupplementMode: NSString {
//case no_supplement,
//case straight,
//case driving,
//case riding,
//case walking,
//};

// 历史轨迹查询页面所设置的参数
@interface HistoryParam : NSObject

@property (nonatomic, assign) int64_t startTime;
@property (nonatomic, assign) int64_t endTime;
@property (nonatomic, assign) BOOL needDenoise; // 去燥
@property (nonatomic, assign) BOOL needVacuate; // 抽稀
@property (nonatomic, assign) BOOL needMapMatch;// 绑路
@property (nonatomic, assign) enum TransportMode transportMode; // 交通方式
@property (nonatomic, copy) NSString *supplementMode;  // 里程补偿方式



@end
