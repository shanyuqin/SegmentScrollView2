//
//  FirstViewController.m
//  SegmentScrollView
//
//  Created by shanyuqin on 2019/8/19.
//  Copyright © 2019 ShanYuQin. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tbMain;

@property (nonatomic, assign) BOOL isRefresh;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(updateData)];
    self.tbMain.mj_header = header;
}
- (void)updateData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isRefresh = !self.isRefresh;
        [self.tbMain.mj_header endRefreshing];
    });
}

- (UIScrollView *)childScrollView {
    return self.tbMain;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identifier = @"UITableViewCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    if (self.isRefresh) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@--%ld",NSStringFromClass([self class]),indexPath.row];
    }else {
        cell.textLabel.text = [NSString stringWithFormat:@"refresh--%ld",indexPath.row];;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
