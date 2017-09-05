//
//  ViewController.m
//  SNRunLoop
//
//  Created by laizw on 2017/9/5.
//  Copyright © 2017年 sina. All rights reserved.
//

#import "ViewController.h"
#import "SNRunLoop.h"

#define kSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define kSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>{
    NSTimeInterval lastTime;
    NSUInteger count;
}

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showFPS];
    [self createUI];
}
- (void)showFPS {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    if (lastTime == 0) {
        lastTime = self.displayLink.timestamp;
        return;
    }
    count++;
    NSTimeInterval timeout = self.displayLink.timestamp - lastTime;
    if (timeout < 1) return;
    lastTime = self.displayLink.timestamp;
    CGFloat fps = count / timeout;
    count = 0;
    self.title = [NSString stringWithFormat:@"%.f FPS",fps];
}

- (void)createUI{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:_tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 500;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 130;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    } else {
        for (NSInteger i = 1; i < 5; i++) {
            [[cell.contentView viewWithTag:i] removeFromSuperview];
        }
    }
    CGFloat imageWidth = kSCREEN_WIDTH / 11.f;
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth * 3, 100)];
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(imageWidth * 4, 0, imageWidth * 3, 100)];
    UIImageView *imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(imageWidth * 8, 0, imageWidth * 3, 100)];
    imageView1.tag = 1;
    imageView2.tag = 2;
    imageView3.tag = 3;
    imageView1.contentMode = imageView2.contentMode = imageView3.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    label.textColor = [UIColor blackColor];
    label.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    [cell.contentView addSubview:label];
    label.tag = 4;

    NSString *path = [[NSBundle mainBundle] pathForResource:@"pd_1024" ofType:@"png"];
    
    // 优化
    SNRunLoop.main.limit(50).drop.add(^{
        imageView1.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView1];
    }).add(^{
        imageView2.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView2];
    }).add(^{
        imageView3.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView3];
    });
    
    /*
    // 卡顿测试
    imageView1.image = [UIImage imageWithContentsOfFile:path];
    [cell.contentView addSubview:imageView1];
    imageView2.image = [UIImage imageWithContentsOfFile:path];
    [cell.contentView addSubview:imageView2];
    imageView3.image = [UIImage imageWithContentsOfFile:path];
    [cell.contentView addSubview:imageView3];
    */
    
    return cell;
}

@end
