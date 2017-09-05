//
//  SNRunLoop.h
//  SNRunLoop
//
//  Created by laizw on 2017/9/5.
//  Copyright © 2017年 sina. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SNRunLoop : NSObject

+ (SNRunLoop *)main;
+ (SNRunLoop *(^)(NSString *))queue;

- (SNRunLoop *(^)(dispatch_block_t))add;
- (SNRunLoop *(^)(dispatch_block_t))cancel;
- (SNRunLoop *(^)(NSUInteger))skip;
- (SNRunLoop *(^)(NSUInteger))limit;
- (SNRunLoop *)cache;

@end
