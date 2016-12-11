//
//  TraceHistoryVC.m
//  YingyanOCDemo
//
//  Created by gary.liu on 16/11/16.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import "TraceHistoryVC.h"
#import "HistoryParam.h"
#import "HistoryPoint.h"

#import <BaiduMapAPI_Map/BMKMapView.h>
#import <CoreLocation/CoreLocation.h>
#import <BaiduTraceSDK/BaiduTraceSDK.h>
#import <BaiduMapAPI_Map/BMKPolyline.h>
#import <BaiduMapAPI_Map/BMKPolylineView.h>
#import <BaiduMapAPI_Map/BMKOverlayView.h>
#import <BaiduMapAPI_Base/BMKTypes.h>

@interface TraceHistoryVC () <ApplicationTrackDelegate, BMKMapViewDelegate>

@property (nonatomic, strong) BMKMapView *mapview;
@property (nonatomic, strong) NSMutableArray *historyPoints;
@property (nonatomic, strong) dispatch_queue_t concurrentPointsQueue;
@property (nonatomic, strong) HistoryParam *param;

@end

@implementation TraceHistoryVC

float EPSILON = 0.0001;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"历史轨迹";
    self.view.backgroundColor = [UIColor whiteColor];
    
    _mapview = [[BMKMapView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _mapview.zoomLevel = 19;
    [self.view addSubview:_mapview];
    _mapview.delegate = self;
    
    _param = [[HistoryParam alloc]init];
    // 默认的数据加工选项是去燥、抽吸、绑路
    _param.needDenoise = YES;
    _param.needVacuate = YES;
    _param.needMapMatch = YES;
    // 默认的交通方式选择设置为驾车
    _param.transportMode = driving;
    // 默认的里程补充方式设置为不补充
    _param.supplementMode = @"no_supplement";
    // 设置开始时间、结束时间
    _param.startTime = self.startTime;
    _param.endTime = self.endTime;
    
    // 用于存储查询时间范围内所有的轨迹点
    _historyPoints = [NSMutableArray array];
    
    // 查询历史轨迹
    [self queryHistory];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 不使用时，设置为nil，否则会内存泄露
    _mapview.delegate = nil;
}

#pragma mark -- 查询轨迹
- (void)queryHistory
{
    // 先清空上一次查询的历史轨迹点
    [_historyPoints removeAllObjects];
    // 目前只考虑起止时间在24小时内的情况
    long long timeInterval = self.endTime - self.startTime;
    if (timeInterval <= 0 || timeInterval >= 86400) {
        NSLog(@"开始时间和结束时间不符合要求");
        return;
    }
    
    int denoise = _param.needDenoise;
    int vacuate = _param.needVacuate;
    int mapMatch = _param.needMapMatch;
    int transport = _param.transportMode;
    NSString *processOption = [NSString stringWithFormat:@"need_denoise=%d,need_vacuate=%d,need_mapmatch=%d,transport_mode=%d", denoise, vacuate, mapMatch, transport];
    
    NSInteger isProcessed = 1;
    if (_param.needDenoise + _param.needVacuate + _param.needMapMatch == 0) {
        isProcessed = 0;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 查询某个实体对象在指定时间段内的历史轨迹数据
//        [[BTRACEAction shared]getTrackHistory:self serviceId:self.serviceID entityName:self.entityName startTime:self.startTime endTime:self.endTime simpleReturn:1 isProcessed:isProcessed pageSize:500 pageIndex:1];
        // 重载的历史轨迹查询方法，可以指定轨迹纠偏的选项、里程补偿方式、结果排序方式
        
        NSLog(@"%d, %@, %lld,, %lld, %ld, %@, %@",self.serviceID, self.entityName, self.startTime, self.endTime, isProcessed, processOption, _param.supplementMode);
        
        [[BTRACEAction shared]getTrackHistory:self serviceId:self.serviceID entityName:self.entityName startTime:self.startTime endTime:self.endTime simpleReturn:1 isProcessed:isProcessed processOption:processOption supplementMode:_param.supplementMode sortType:0 pageSize:5000 pageIndex:1];
    });
    
   
}

#pragma mark -- AppliationTraceDelegate
- (void)onGetHistoryTrack:(NSData *)data
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"%@",json);
    
    int status = [json[@"status"] intValue];
    if (status != 0) {
        NSLog(@"查询历史轨迹数据失败");
        return;
    }
    
    NSArray *points = [json[@"points"] copy];
    if (points.count == 0) {
        NSLog(@"points没数据");
        return;
    }

    for (NSArray *arr in points) {
        float latitude = [arr[1] floatValue];
        float longitude = [arr[0] floatValue];
        int loctime = [arr[2]intValue];
        if (fabs(latitude - 0) <= EPSILON && fabs(longitude - 0) <= EPSILON) {
            continue;
        }
        HistoryPoint *historyPoint = [[HistoryPoint alloc]init];
        historyPoint.latitude = latitude;
        historyPoint.longitude = longitude;
        historyPoint.loctime = loctime;
        [_historyPoints addObject:historyPoint];
    }
    
    [self drawHistoryPoints];
}

#pragma mark -- 在屏幕上绘制历史轨迹
- (void)drawHistoryPoints
{
    // 使用地图SDK绘制线段只需要经纬度坐标
    CLLocationCoordinate2D *points = malloc(sizeof(CLLocationCoordinate2D) * _historyPoints.count);
    
    int i = 0;
    for (HistoryPoint *point in _historyPoints) {
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        points[i++] = location;
    }
//    NSLog(@"CLLocationCoordinate2D = %@",points);
    // 执行画线方法
    BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:points count:_historyPoints.count];
    
    // 先清空之前地图的覆盖物
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapview removeOverlays:_mapview.overlays];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self mapiewFitPolyLine:points];
        [_mapview addOverlay:polyline];
    });
}

#pragma mark -- 设置地图的范围恰好包括整个轨迹的范围
- (void)mapiewFitPolyLine:(CLLocationCoordinate2D *)locations
{
    float minLat = 90.0;
    float maxLat = -90.0;
    float minLon = 180.0;
    float maxLon = -180.0;
    
    for (NSInteger i = 0; i < _historyPoints.count; i++) {
        CLLocationCoordinate2D location = locations[i];
        minLat = MIN(minLat, location.latitude);
        maxLat = MAX(maxLat, location.latitude);
        minLon = MIN(minLon, location.longitude);
        maxLon = MAX(maxLon, location.longitude);
    }
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLat + maxLat) * 0.5, (minLon + maxLon) * 0.5);
    BMKCoordinateSpan span = {(maxLat - minLat) * 0.01, (maxLon - minLon) * 0.01};
    BMKCoordinateRegion region = {center, span};
    [_mapview setRegion:region animated:YES];
}

#pragma mark -- BMKMapViewdelegate 地图SDK回调方法，由于生成线段的view
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{

    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *polylineView = [[BMKPolylineView alloc]initWithOverlay:overlay];
        polylineView.strokeColor = [[UIColor blueColor]colorWithAlphaComponent:0.5];
        polylineView.lineWidth = 2.0;
        return polylineView;
    }
    return nil;
}


@end
