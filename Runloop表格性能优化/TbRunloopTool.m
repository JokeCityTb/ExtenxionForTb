//
//  TbRunloopTool.m
//  RunLoopTable
//
//  Created by Tb on 2018/3/21.
//  Copyright © 2018年 Tb. All rights reserved.
//

#import "TbRunloopTool.h"
#import <objc/runtime.h>

#define DWURunLoopWorkDistribution_DEBUG 1

@interface TbRunloopTool ()

@property (nonatomic, strong) NSMutableArray *tasks;

@property (nonatomic, strong) NSMutableArray *tasksKeys;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TbRunloopTool

- (void)removeAllTasks {
    [self.tasks removeAllObjects];
    [self.tasksKeys removeAllObjects];
}

- (void)addTask:(TbRunLoopUnit)unit withKey:(id)key{
    [self.tasks addObject:unit];
    [self.tasksKeys addObject:key];
    if (self.tasks.count > self.maximumQueueLength) {
        [self.tasks removeObjectAtIndex:0];
        [self.tasksKeys removeObjectAtIndex:0];
    }
}

- (void)_timerFiredMethod:(NSTimer *)timer {
    //We do nothing here
}

- (instancetype)init
{
    if ((self = [super init])) {
        _maximumQueueLength = 30;
        _tasks = [NSMutableArray array];
        _tasksKeys = [NSMutableArray array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerFiredMethod:) userInfo:nil repeats:YES];
    }
    return self;
}

+ (instancetype)sharedRunLoopWorkDistribution {
    static TbRunloopTool *singleton;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[TbRunloopTool alloc] init];
        [self _registerRunLoopWorkDistributionAsMainRunloopObserver:singleton];
    });
    return singleton;
}

+ (void)_registerRunLoopWorkDistributionAsMainRunloopObserver:(TbRunloopTool *)runLoopWorkDistribution {
    static CFRunLoopObserverRef defaultModeObserver;
    _registerObserver(kCFRunLoopBeforeWaiting, defaultModeObserver, NSIntegerMax - 999, kCFRunLoopDefaultMode, (__bridge void *)runLoopWorkDistribution, &_defaultModeRunLoopWorkDistributionCallback);
}

static void _registerObserver(CFOptionFlags activities, CFRunLoopObserverRef observer, CFIndex order, CFStringRef mode, void *info, CFRunLoopObserverCallBack callback) {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopObserverContext context = {
        0,
        info,
        &CFRetain,
        &CFRelease,
        NULL
    };
    observer = CFRunLoopObserverCreate(     NULL,
                                       activities,
                                       YES,
                                       order,
                                       callback,
                                       &context);
    CFRunLoopAddObserver(runLoop, observer, mode);
    CFRelease(observer);
}

static void _runLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    TbRunloopTool *runLoopWorkDistribution = (__bridge TbRunloopTool *)info;
    if (runLoopWorkDistribution.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    while (result == NO && runLoopWorkDistribution.tasks.count) {
        TbRunLoopUnit unit  = runLoopWorkDistribution.tasks.firstObject;
        result = unit();
        [runLoopWorkDistribution.tasks removeObjectAtIndex:0];
        [runLoopWorkDistribution.tasksKeys removeObjectAtIndex:0];
    }
}

static void _defaultModeRunLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    _runLoopWorkDistributionCallback(observer, activity, info);
}

@end

@implementation UITableViewCell (TbRunloopTool)

@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
