#  SNRunLoop

利用 `runloop` 优化显示，解决卡顿

## 简介

卡顿产生的原因一般是：阻塞。

解决阻塞的方法有很多，在 iOS 开发中，我们会将一些 IO 操作或者一些容易阻塞线程的任务放到后台线程。

针对 UI 层来说，大量的 UI 操作也很容易阻塞主线程，例如：我们参见的列表滑动卡顿。

`SNRunLoop` 是为了解决这个问题而生，他可以让你将一个大任务拆分成很多个小任务，在 `Runloop` 当前循环空闲时(`kRunLoopBeforeWaiting`)，依次执行各个小任务。

## 使用

> 链式调用，爽！

### 1. 队列

- 默认

    主任务队列，`observer` 不会销毁
    
    ```objc
    SNRunLoop.main
    ```
    
- 自定义

    当任务总数为 0 时，会在 n 个循环后销毁 `observer` (n 为粗糙值 100)

    ```objc
    SNRunLoop.queue(@"com.sina.runloop.queue1")
    ```

### 2. 添加任务
    
```objc
SNRunLoop.main.add(dispatch_block_t).add(...);
```

### 3. 取消任务

```objc
SNRunLoop.main.cancel(dispatch_block_t)
```

### 3. 限制 Task 个数
    
Task 队列个数 默认不限制。
    
使用 `limit()` 限制 Task 个数，超出限制会丢弃最先入列的 Task。
    
```
SNRunLoop.main.limit(10).add(...);
```
    
`limit` 有缓存机制，默认关闭。开启缓存后，超过 limit 的任务会添加到缓存中，当 Task 队列不再超过限制时，会将缓存的 Task 添加到队列中。
    
```
SNRunLoop.main.limit(10).cache.add(...);
```
    
### 4. 延时调用

跳过指定 `RunLoop` 循环次数之后开始执行任务

```objc
SNRunLoop.main.skip(5).add(...)
```

