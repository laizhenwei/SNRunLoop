//
//  SNRunLoop.m
//  SNRunLoop
//
//  Created by laizw on 2017/9/5.
//  Copyright © 2017年 sina. All rights reserved.
//

#import "SNRunLoop.h"

#define kSNRunLoopChainImplement(params, ...) \
__weak typeof(&*self) weak_self = self; \
return ^id(params) { \
__strong typeof(&*weak_self) self = weak_self; \
dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__ \
dispatch_semaphore_signal(_lock); \
return self; \
};

static int const kRunLoopTasksLimit = INT_MAX;
static int const kRunLoopTaskSkip = 100;

@interface SNRunLoop () {
    dispatch_semaphore_t _lock;
    NSInteger _limitCount;
    NSUInteger _skip;
    BOOL _isCache;
}
@property (nonatomic, strong) NSMutableDictionary *runloops;
@property (nonatomic, strong) SNRunLoop *main;

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSMutableArray *caches;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) dispatch_block_t destroyTask;
@end

@implementation SNRunLoop

#pragma mark - Lifecircle
+ (instancetype)manager {
    static SNRunLoop *manager;
    static dispatch_once_t one;
    dispatch_once(&one, ^{
        manager = [[SNRunLoop alloc] init];
    });
    return manager;
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.name = name;
        _lock = dispatch_semaphore_create(1);
        _limitCount = kRunLoopTasksLimit;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SNRunLoop %p> - %@", self, self.name];
}

#pragma mark - Public
+ (SNRunLoop *)main {
    SNRunLoop *runloop = SNRunLoop.manager.main;
    if (!runloop) {
        runloop = [[SNRunLoop alloc] initWithName:@"com.sina.runloop.main"];
        [runloop addObserverForRunloop:CFRunLoopGetMain()];
        SNRunLoop.manager.main = runloop;
    }
    return runloop;
}

+ (SNRunLoop *(^)(NSString *))queue {
    return ^id(NSString *name) {
        NSAssert(name != nil, @"runloop observe name should not be nil");
        SNRunLoop *runloop = [SNRunLoop.manager.runloops objectForKey:name];
        if (!runloop) {
            runloop = [[SNRunLoop alloc] initWithName:name];
            [runloop addObserverForRunloop:CFRunLoopGetCurrent()];
            [SNRunLoop.manager.runloops setObject:runloop forKey:name];
        }
        return runloop;
    };
}

- (SNRunLoop *)cache {
    _isCache = YES;
    return self;
}

- (SNRunLoop *(^)(NSUInteger))limit {
    kSNRunLoopChainImplement(NSUInteger limit, {
        _limitCount = limit;
    });
}

- (SNRunLoop *(^)(NSUInteger))skip {
    kSNRunLoopChainImplement(NSUInteger skip, {
        self->_skip = skip;
    });
}

- (SNRunLoop *(^)(dispatch_block_t))add {
    kSNRunLoopChainImplement(dispatch_block_t task, {
        if (task) {
            [self.tasks addObject:task];
            while (self.tasks.count > _limitCount) {
                if (_isCache) {
                    [self.caches addObject:task];
                }
                [self.tasks removeObjectAtIndex:0];
            }
        }
    });
}

- (SNRunLoop *(^)(dispatch_block_t))cancel {
    kSNRunLoopChainImplement(dispatch_block_t task, {
        if ([self.tasks containsObject:task]) {
            [self.tasks removeObject:task];
        } else if ([self.caches containsObject:task]) {
            [self.caches removeObject:task];
        }
    });
}

#pragma mark - Private
- (void)addObserverForRunloop:(CFRunLoopRef)runloop {
    __weak typeof(&*self) weak_self = self;
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        __strong typeof(&*weak_self) self = weak_self;
        
        // 空队列
        if (self.tasks.count == 0) return;
        
        // 跳过
        if (self->_skip > 0) {
            self->_skip--;
            return;
        }
        
        // 执行任务
        dispatch_block_t task = self.tasks.firstObject;
        task();
        [self.tasks removeObjectAtIndex:0];
        // 缓存
        if (_isCache && self.caches.count) {
            id task = self.caches.firstObject;
            [self.caches removeObjectAtIndex:0];
            [self.tasks addObject:task];
        }
        
        // 销毁观察者
        [self destroyObserver:observer];
    });
    CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

- (void)destroyObserver:(CFRunLoopObserverRef)observer {
    if (self.tasks.count == 0) {
        if ([SNRunLoop.manager.runloops objectForKey:self.name]) {
            __weak typeof(&*self) weak_self = self;
            self.destroyTask = ^{
                __strong typeof(&*weak_self) self = weak_self;
                CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
                [SNRunLoop.manager.runloops removeObjectForKey:self.name];
            };
            // 延迟销毁，在 n 次循环后
            SNRunLoop.main.skip(kRunLoopTaskSkip).limit(1).add(self.destroyTask);
        }
    } else {
        if (self.destroyTask) {
            SNRunLoop.main.cancel(self.destroyTask);
            self.destroyTask = nil;
        }
    }
}

#pragma mark - Getter
- (NSMutableArray *)tasks {
    if (!_tasks) {
        _tasks = @[].mutableCopy;
    }
    return _tasks;
}

- (NSMutableArray *)caches {
    if (!_caches) {
        _caches = @[].mutableCopy;
    }
    return _caches;
}

- (NSMutableDictionary *)runloops {
    if (!_runloops) {
        _runloops = @{}.mutableCopy;
    }
    return _runloops;
}
@end
