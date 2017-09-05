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

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) BOOL optimize;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

- (void)initView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"优化: 关" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
    self.navigationItem.rightBarButtonItem = item;
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Action
- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    if (self.lastTime == 0) {
        self.lastTime = self.displayLink.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval timeout = self.displayLink.timestamp - self.lastTime;
    if (timeout < 1) return;
    self.lastTime = self.displayLink.timestamp;
    CGFloat fps = self.count / timeout;
    self.count = 0;
    self.title = [NSString stringWithFormat:@"%.f FPS",fps];
}

- (void)rightBarButtonAction {
    self.optimize = !self.optimize;
    NSString *title = [NSString stringWithFormat:@"优化: %@", self.optimize ? @"开" : @"关"];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1000;
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
    
    if (self.optimize) {
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
    } else {
        // 卡顿测试
        imageView1.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView1];
        imageView2.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView2];
        imageView3.image = [UIImage imageWithContentsOfFile:path];
        [cell.contentView addSubview:imageView3];
    }
    return cell;
}

@end
