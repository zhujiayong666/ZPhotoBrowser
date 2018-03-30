//
//  ZViewController.m
//  ZPhotoBrowser
//
//  Created by git on 03/30/2018.
//  Copyright (c) 2018 git. All rights reserved.
//

#import "ZViewController.h"
#import <ZPhotoBrowser/ZPhotoBrowser.h>

@interface ZViewController ()

@end

@implementation ZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    btn.center = self.view.center;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"浏览图片" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor greenColor]];
    [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClicked:(UIButton *)sender {
    NSMutableArray *photos = [NSMutableArray new];
    NSArray *urlArr = @[@"http://img3.duitang.com/uploads/item/201512/24/20151224004400_kJVZF.jpeg", @"http://img5.duitang.com/uploads/item/201203/15/20120315084838_SKBUM.thumb.700_0.jpeg", @"http://img5q.duitang.com/uploads/item/201411/03/20141103131753_ThzwF.jpeg", @"http://img4q.duitang.com/uploads/item/201405/23/20140523193955_PeNHE.jpeg", @"http://img5.duitang.com/uploads/item/201606/11/20160611020001_iCWn2.jpeg"];
    for (NSString *str in urlArr) {
        ZImageModel *model = [[ZImageModel alloc] init];
        model.pic = str;
        [photos addObject:model];
    }
    
    ZPhotoBrowser *view = [[ZPhotoBrowser alloc] init];
    view.photos = photos;
    __weak __typeof(&*self) weakSelf = self;
    [view setLongPress:^(UIImage *image) {
        if (image) {
            [weakSelf shareImage:image];
        }
    }];
    [view showInRect:CGRectMake(self.view.center.x, self.view.center.y, 80, 80) WithView:self.view];
}

- (void)shareImage:(UIImage *)image {
    
    if (!image) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake((CGRectGetWidth(self.view.bounds) - 20) / 2, 0, 20, 0);
    }
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"发送给朋友" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
    }];
    
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:action1];
    [alert addAction:saveAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 指定回调方法
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    NSString *msg = nil ;
    
    if(error != NULL){
        msg = @"保存图片失败" ;
    }
    else{
        msg = @"保存图片成功" ;
    }
    NSLog(@"%@", msg);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
