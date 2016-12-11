//
//  MainVC.m
//  YingyanOCDemo
//
//  Created by gary.liu on 16/11/16.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import "MainVC.h"
#import "TraceHistoryVC.h"

#import <CoreLocation/CoreLocation.h>
#import <BaiduTraceSDK/BaiduTraceSDK.h>

@interface MainVC () <ApplicationServiceDelegate>

@property (nonatomic, assign) BOOL isTracing;
@property (nonatomic, strong) BTRACE *traceInstance;

@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) long long endTime;

@end

@implementation MainVC

int const serviceID = 129082;
NSString *const AK = @"eP2nMHOIlPGM1HN24ep2SzdLrrwuG9CL";
NSString *const MCODE = @"com.winsafe.gary.YingyanOCDemo";
NSString *entityName = @"15721541602";
// 默认定位精度米级别
NSInteger accuracy = 1;
// 默认运动方式未知
NSInteger activity = 3;
// 默认采集周期为5秒
int32_t gatherInterval = 2;
// 默认上传周期为30秒
int32_t packInterval = 10;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"主页";
    
    _traceInstance = [[BTRACE alloc]initWithAk:AK mcode:MCODE serviceId:serviceID entityName:entityName operationMode:2];
    
    _isTracing = NO;
}

#pragma mark -- 开始追踪
- (IBAction)startTraceAction:(id)sender
{
    __weak typeof(self)weakself = self;
    
    if (_isTracing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertContro = [UIAlertController alertControllerWithTitle:@"开始轨迹服务的结果" message:@"当前正在开启追踪服务" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
            [alertContro addAction:sureAction];
            [weakself presentViewController:alertContro animated:YES completion:nil];
        });
        return;
    }
    
    NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
    long long dTime = [[NSNumber numberWithDouble:time]longLongValue];
    NSLog(@"start = %llu",dTime);
    _startTime = dTime;
    
    // 异步追踪，异步执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 在轨迹服务开始前设置轨迹的服务的采集周期和打包周期，这一步不是必须的，因默认定位周期为5s，打包周期是30s
        [_traceInstance setInterval:gatherInterval packInterval:packInterval];
        // 定位相关的属性只能在轨迹服务开始前进行设置
        [[BTRACEAction shared]setAttributeOfLocation:activity desiredAccuracy:accuracy distanceFilter:kCLDistanceFilterNone];
        // 开始轨迹服务
        [[BTRACEAction shared]startTrace:weakself trace:_traceInstance];
    });
}

#pragma mark -- 结束追踪
- (IBAction)stopTraceAction:(id)sender
{
    NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
    long long dTime = [[NSNumber numberWithDouble:time]longLongValue];
    NSLog(@"end = %llu",dTime);
    _endTime = dTime;

    __weak typeof(self)weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[BTRACEAction shared]stopTrace:weakself trace:_traceInstance];
    });
}

#pragma mark -- 查看追踪轨迹
- (IBAction)traceHistoryAction:(id)sender
{
    if (_startTime == 0 || _endTime == 0) {
        NSDate *start_Date = [NSDate dateWithTimeInterval:- 8 * 60 * 60 sinceDate:[NSDate date]];
        NSTimeInterval start_time = [start_Date timeIntervalSince1970];
        _startTime = [[NSNumber numberWithDouble:start_time]longLongValue];
        
        NSTimeInterval end_time = [[NSDate date] timeIntervalSince1970];
        _endTime = [[NSNumber numberWithDouble:end_time]longLongValue];
    }
    
    TraceHistoryVC *vcTraceHistory = [[TraceHistoryVC alloc]init];
    vcTraceHistory.startTime = _startTime;
    vcTraceHistory.endTime = _endTime;
    vcTraceHistory.entityName = entityName;
    vcTraceHistory.serviceID = serviceID;
    [self.navigationController pushViewController:vcTraceHistory animated:YES];
}

#pragma mark -- ApplicationServiceDelegate
- (void)onStartTrace:(NSInteger)errNo errMsg:(NSString *)errMsg
{
    NSLog(@"start = %ld, %@",errNo, errMsg);
    // 表示轨迹服务开始成功
    if (errNo == 0 || errNo == 10007) {
        _isTracing = YES;
    }
    
    __weak typeof(self)weakself = self;
    // 弹窗提示用户
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertContro = [UIAlertController alertControllerWithTitle:@"开始轨迹服务的结果" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alertContro addAction:sureAction];
        [weakself presentViewController:alertContro animated:YES completion:nil];
    });
}

- (void)onStopTrace:(NSInteger)errNo errMsg:(NSString *)errMsg
{
    NSLog(@"stop = %ld, %@",errNo, errMsg);
    // 表示轨迹服务结束成功
    if (errNo == 0) {
        _isTracing = NO;
    }
    __weak typeof(self)weakself = self;
    // 弹窗提示用户
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertContro = [UIAlertController alertControllerWithTitle:@"结束轨迹服务的结果" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alertContro addAction:sureAction];
        [weakself presentViewController:alertContro animated:YES completion:nil];
    });
    
}

#pragma mark -- 每个采集周期系统都会调用方法
//- (NSDictionary<NSString *,NSString *> *)trackAttr
//{
//    return @{@"测试" : @"测试"};
//}




@end
