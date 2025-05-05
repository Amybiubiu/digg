//
//  SLTrackingManager.m
//  digg
//
//  Created by Tim Bao on 2025/3/1.
//

#import "SLTrackingManager.h"
#import <objc/runtime.h>

// 关联对象的key
static char kPageViewStartTimeKey;
static char kViewExposureStartTimeKey;

@interface SLTrackingManager ()

@property (nonatomic, strong) NSMutableArray *eventQueue;
@property (nonatomic, strong) NSMutableDictionary *commonParameters;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSTimer *uploadTimer;
@property (nonatomic, strong) dispatch_queue_t trackingQueue;
@property (nonatomic, strong) NSMutableDictionary *pageViewStartTimes;
@property (nonatomic, strong) NSMutableDictionary *viewExposureStartTimes;

@end

@implementation SLTrackingManager

#pragma mark - 单例实现
+ (instancetype)sharedInstance {
    static SLTrackingManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventQueue = [NSMutableArray array];
        _commonParameters = [NSMutableDictionary dictionary];
        _pageViewStartTimes = [NSMutableDictionary dictionary];
        _viewExposureStartTimes = [NSMutableDictionary dictionary];
        
        // 创建串行队列处理埋点事件
        _trackingQueue = dispatch_queue_create("com.digg.tracking", DISPATCH_QUEUE_SERIAL);
        
        // 设置文件路径
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _filePath = [documentsPath stringByAppendingPathComponent:@"tracking_events.json"];
        
//        // 从文件加载历史事件
//        [self loadEventsFromFile];
//        
//        // 启动定时上传
//        [self startUploadTimer];
    }
    return self;
}

#pragma mark - 公共方法
- (void)trackEvent:(NSString *)eventName parameters:(NSDictionary *)parameters {
    if (!eventName) return;
    
    dispatch_async(self.trackingQueue, ^{
        NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
        [eventData setObject:eventName forKey:@"event"];
        [eventData setObject:@(SLTrackingEventTypeClick) forKey:@"type"];
        [eventData setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];
        
        NSMutableDictionary *eventParams = [NSMutableDictionary dictionary];
        [eventParams addEntriesFromDictionary:self.commonParameters];
        if (parameters) {
            [eventParams addEntriesFromDictionary:parameters];
        }
        [eventData setObject:eventParams forKey:@"parameters"];
        
        [self addEventToQueue:eventData];
    });
}

- (void)trackPageViewBegin:(UIViewController *)viewController uniqueIdentifier:(NSString *)uniqueIdentifier {
    if (!viewController) return;
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSString *pageKey = NSStringFromClass([viewController class]);
    
    // 如果提供了唯一标识符，则将其添加到页面键中
    if (uniqueIdentifier) {
        pageKey = [NSString stringWithFormat:@"%@_%@", pageKey, uniqueIdentifier];
    }
    
    dispatch_async(self.trackingQueue, ^{
        [self.pageViewStartTimes setObject:@(startTime) forKey:pageKey];
    });
}

- (void)trackPageViewEnd:(UIViewController *)viewController uniqueIdentifier:(NSString *)uniqueIdentifier parameters:(NSDictionary *)parameters {
    if (!viewController) return;
    
    NSString *pageKey = NSStringFromClass([viewController class]);
    
    // 如果提供了唯一标识符，则将其添加到页面键中
    if (uniqueIdentifier) {
        pageKey = [NSString stringWithFormat:@"%@_%@", pageKey, uniqueIdentifier];
    }
    
    dispatch_async(self.trackingQueue, ^{
        NSNumber *startTimeObj = [self.pageViewStartTimes objectForKey:pageKey];
        if (!startTimeObj) return;
        
        NSTimeInterval startTime = [startTimeObj doubleValue];
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval duration = endTime - startTime;
        
        // 移除开始时间记录
        [self.pageViewStartTimes removeObjectForKey:pageKey];
        
        // 创建埋点事件
        NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
        [eventData setObject:[NSString stringWithFormat:@"page_view_%@", pageKey] forKey:@"event"];
        [eventData setObject:@(SLTrackingEventTypePageView) forKey:@"type"];
        [eventData setObject:@(endTime) forKey:@"timestamp"];
        
        NSMutableDictionary *eventParams = [NSMutableDictionary dictionary];
        [eventParams addEntriesFromDictionary:self.commonParameters];
        [eventParams setObject:pageKey forKey:@"page_name"];
        [eventParams setObject:@(duration) forKey:@"duration"];
        
        // 如果有唯一标识符，也添加到参数中
        if (uniqueIdentifier) {
            [eventParams setObject:uniqueIdentifier forKey:@"unique_identifier"];
        }
        
        if (parameters) {
            [eventParams addEntriesFromDictionary:parameters];
        }
        [eventData setObject:eventParams forKey:@"parameters"];
        
        [self addEventToQueue:eventData];
    });
}

// 为了向后兼容，保留原有接口
- (void)trackPageViewBegin:(UIViewController *)viewController {
    [self trackPageViewBegin:viewController uniqueIdentifier:nil];
}

- (void)trackPageViewEnd:(UIViewController *)viewController parameters:(NSDictionary *)parameters {
    [self trackPageViewEnd:viewController uniqueIdentifier:nil parameters:parameters];
}

- (void)trackViewExposure:(NSString *)identifier duration:(NSUInteger)duration parameters:(NSDictionary *)parameters {
    if (!identifier) return;
    
    dispatch_async(self.trackingQueue, ^{
        // 创建埋点事件
        NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
        [eventData setObject:[NSString stringWithFormat:@"view_exposure_%@", identifier] forKey:@"event"];
        [eventData setObject:@(SLTrackingEventTypeExposure) forKey:@"type"];
        [eventData setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];
        
        NSMutableDictionary *eventParams = [NSMutableDictionary dictionary];
        [eventParams addEntriesFromDictionary:self.commonParameters];
        [eventParams setObject:identifier forKey:@"view_identifier"];
        [eventParams setObject:@(duration) forKey:@"duration"];
        
        if (parameters) {
            [eventParams addEntriesFromDictionary:parameters];
        }
        [eventData setObject:eventParams forKey:@"parameters"];
        
        [self addEventToQueue:eventData];
    });
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    if (userId) {
        [self.commonParameters setObject:userId forKey:@"user_id"];
    } else {
        [self.commonParameters removeObjectForKey:@"user_id"];
    }
}

- (void)setCommonParameters:(NSDictionary *)parameters {
    if (!parameters) return;
    
    dispatch_async(self.trackingQueue, ^{
        [self.commonParameters addEntriesFromDictionary:parameters];
    });
}

- (void)flush {
    dispatch_async(self.trackingQueue, ^{
        [self uploadEvents];
    });
}

#pragma mark - 私有方法
- (void)addEventToQueue:(NSDictionary *)eventData {
    [self.eventQueue addObject:eventData];
    [self saveEventsToFile];
    
    // 如果队列超过100条，立即上传
    if (self.eventQueue.count >= 100) {
        [self uploadEvents];
    }
}

- (void)startUploadTimer {
    // 停止现有的定时器
    if (self.uploadTimer) {
        [self.uploadTimer invalidate];
        self.uploadTimer = nil;
    }
    
    // 创建新的定时器，每30秒上传一次
    self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                        target:self
                                                      selector:@selector(timerUploadEvents)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)timerUploadEvents {
    dispatch_async(self.trackingQueue, ^{
        [self uploadEvents];
    });
}

- (void)uploadEvents {
    if (self.eventQueue.count == 0) return;
    
    // 复制当前队列中的事件
    NSArray *eventsToUpload = [self.eventQueue copy];
    
    // 清空队列
    [self.eventQueue removeAllObjects];
    [self saveEventsToFile];
    
    // 上传事件
    [self uploadEventsToServer:eventsToUpload completion:^(BOOL success) {
        if (!success) {
            // 上传失败，将事件重新加入队列
            dispatch_async(self.trackingQueue, ^{
                [self.eventQueue addObjectsFromArray:eventsToUpload];
                [self saveEventsToFile];
            });
        }
    }];
}

- (void)uploadEventsToServer:(NSArray *)events completion:(void(^)(BOOL success))completion {
    // 构建请求体
    NSMutableDictionary *requestBody = [NSMutableDictionary dictionary];
    [requestBody setObject:events forKey:@"events"];
    
    // 添加设备信息
    NSMutableDictionary *deviceInfo = [NSMutableDictionary dictionary];
    [deviceInfo setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
    [deviceInfo setObject:@"iOS" forKey:@"platform"];
    [deviceInfo setObject:[[UIDevice currentDevice] model] forKey:@"device_model"];
    
    [requestBody setObject:deviceInfo forKey:@"device_info"];
    
    // 转换为JSON数据
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&error];
    
    if (error) {
        NSLog(@"埋点数据序列化失败: %@", error);
        if (completion) completion(NO);
        return;
    }
    
    // 创建请求
    NSURL *url = [NSURL URLWithString:@"https://api.digg.com/tracking"]; //TODO: 替换为实际的API地址
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];
    
    // 发送请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        BOOL success = (error == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300);
        
        if (!success) {
            NSLog(@"埋点数据上传失败: %@, 状态码: %ld", error, (long)httpResponse.statusCode);
        }
        
        if (completion) completion(success);
    }];
    
    [task resume];
}

- (void)loadEventsFromFile {
    dispatch_async(self.trackingQueue, ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
            NSData *data = [NSData dataWithContentsOfFile:self.filePath];
            if (data) {
                NSError *error;
                NSArray *events = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                
                if (!error && [events isKindOfClass:[NSArray class]]) {
                    [self.eventQueue addObjectsFromArray:events];
                    NSLog(@"从文件加载了 %lu 条埋点事件", (unsigned long)events.count);
                } else {
                    NSLog(@"埋点事件数据解析失败: %@", error);
                }
            }
        }
    });
}

- (void)saveEventsToFile {
    dispatch_async(self.trackingQueue, ^{
        if (self.eventQueue.count > 0) {
            NSError *error;
            NSData *data = [NSJSONSerialization dataWithJSONObject:self.eventQueue options:0 error:&error];
            
            if (!error) {
                BOOL success = [data writeToFile:self.filePath atomically:YES];
                if (!success) {
                    NSLog(@"埋点事件保存到文件失败");
                }
            } else {
                NSLog(@"埋点事件序列化失败: %@", error);
            }
        } else {
            // 如果队列为空，删除文件
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
                NSError *error;
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:&error];
                if (!success) {
                    NSLog(@"删除埋点事件文件失败: %@", error);
                }
            }
        }
    });
}

@end
