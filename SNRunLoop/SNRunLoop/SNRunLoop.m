//
//  SNRunLoop.m
//  SNRunLoop
//
//  Created by laizw on 2017/9/5.
//  Copyright © 2017年 sina. All rights reserved.
//

#import "SNRunLoop.h"

#define kSNRunLoopImplement(params, ...) \
__weak typeof(&*self) weak_self = self; \
return ^id(params) { \
__strong typeof(&*weak_self) self = weak_self; \
dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__ \
dispatch_semaphore_signal(self.lock); \
return self; \
};

static int const kRunLoopTasksLimit = INT_MAX;

@interface SNRunLoop ()
@property (nonatomic, strong) SNRunLoop *main;
@property (nonatomic, strong) NSMutableArray *runloops;

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSMutableArray *cache;
@property (nonatomic, assign) NSInteger limitCount;
@property (nonatomic, assign) BOOL isDrop;
@property (nonatomic, copy) NSString *name;
@property dispatch_semaphore_t lock;
@end

@implementation SNRunLoop

#pragma mark - Lifecircle
+ (instancetype)queue {
    static SNRunLoop *queue;
    static dispatch_once_t one;
    dispatch_once(&one, ^{
        queue = [[SNRunLoop alloc] init];
    });
    return queue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lock = dispatch_semaphore_create(1);
        self.name = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
        self.limitCount = kRunLoopTasksLimit;
    }
    return self;
}

+ (instancetype)main {
    SNRunLoop *queue = [SNRunLoop queue].main;
    if (!queue) {
        queue = [[SNRunLoop alloc] init];
        [queue addObserverForRunloop:CFRunLoopGetMain()];
        SNRunLoop.queue.main = queue;
    }
    return queue;
}

+ (instancetype)current {
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        return SNRunLoop.main;
    } else {
        __block SNRunLoop *queue;
        NSString *name = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
        if (SNRunLoop.queue.runloops.count) {
            [SNRunLoop.queue.runloops enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([name isEqualToString:[obj name]]) {
                    queue = obj;
                    *stop = YES;
                }
            }];
        } else {
            queue = [[SNRunLoop alloc] init];
            [queue addObserverForRunloop:CFRunLoopGetCurrent()];
            [SNRunLoop.queue.runloops addObject:queue];
        }
        return queue;
    }
}

#pragma mark - Public
- (SNRunLoop *(^)(NSUInteger))limit {
    kSNRunLoopImplement(NSUInteger limit, {
        self.limitCount = limit;
    });
}

- (SNRunLoop *)drop {
    self.isDrop = YES;
    return self;
}

- (SNRunLoop *(^)(dispatch_block_t))add {
    kSNRunLoopImplement(dispatch_block_t task, {
        if (task) {
            while (self.tasks.count > self.limitCount - 1) {
                if (!self.isDrop) {
                    [self.cache addObject:self.tasks.firstObject];
                }
                [self.tasks removeObjectAtIndex:0];
            }
            [self.tasks addObject:task];
        }
    });
}

- (SNRunLoop *(^)(NSUInteger))after {
    kSNRunLoopImplement(NSUInteger after, {
        for (int i = 0; i < after; i++) {
            [self.tasks addObject:[NSNull null]];
        }
    });
}

- (SNRunLoop *(^)(dispatch_block_t))cancel {
    kSNRunLoopImplement(dispatch_block_t task, {
        if ([self.tasks containsObject:task]) {
            [self.tasks removeObject:task];
        } else if ([self.cache containsObject:task]) {
            [self.cache removeObject:task];
        }
    });
}

#pragma mark - Private
- (void)addObserverForRunloop:(CFRunLoopRef)runloop {
    __weak typeof(&*self) weak_self = self;
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        __strong typeof(&*weak_self) self = weak_self;
        if (self.tasks.count) {
            id task = self.tasks.firstObject;
            if (![task isKindOfClass:[NSNull class]]) {
                ((dispatch_block_t)task)();
            }
            [self.tasks removeObjectAtIndex:0];
            
            if (!self.isDrop && self.cache.count) {
                id task = self.cache.firstObject;
                [self.cache removeObjectAtIndex:0];
                [self.tasks addObject:task];
            }
            if (self.tasks.count == 0) {
                [SNRunLoop.queue.runloops removeObject:self];
            }
        }
    });
    CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[SNRunLoop class]]) return NO;
    if ([self.name isEqualToString:[object name]]) return YES;
    return NO;
}

#pragma mark - Getter
- (NSMutableArray *)tasks {
    if (!_tasks) {
        _tasks = @[].mutableCopy;
    }
    return _tasks;
}

- (NSMutableArray *)cache {
    if (!_cache) {
        _cache = @[].mutableCopy;
    }
    return _cache;
}

- (NSMutableArray *)runloops {
    if (!_runloops) {
        _runloops = @[].mutableCopy;
    }
    return _runloops;
}

@end
