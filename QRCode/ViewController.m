//
//  ViewController.m
//  QRCode
//
//  Created by forms_gumou on 2018/3/13.
//  Copyright © 2018年 gumou. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeViewController.h"
#import "PersonalQRVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *scanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [scanBtn setFrame:CGRectMake(100, 100, 120, 60)];
    scanBtn.tag = 1001;
    [scanBtn setTitle:@"scan qrcode" forState:UIControlStateNormal];
    [scanBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [scanBtn setBackgroundColor:[UIColor blueColor]];
    [scanBtn addTarget:self action:@selector(buttonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanBtn];
    
    UIButton *showQRCode = [UIButton buttonWithType:UIButtonTypeCustom];
    [showQRCode setFrame:CGRectMake(100, 200, 120, 60)];
    showQRCode.tag = 1002;
    [showQRCode setTitle:@"show qrcode" forState:UIControlStateNormal];
    [showQRCode setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [showQRCode setBackgroundColor:[UIColor blueColor]];
    [showQRCode addTarget:self action:@selector(buttonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:showQRCode];
}

- (void)buttonClickAction:(UIButton *)button {
    NSInteger tag = button.tag;
    if (tag == 1001) {
        QRCodeViewController *vc = [[QRCodeViewController alloc] init];
        [vc getQrResult:^(NSString *result) {
            NSLog(@"scan result: %@",result);
        }];
        [self.navigationController pushViewController:vc animated:NO];
    }else {
        PersonalQRVC *vc = [[PersonalQRVC alloc] init];
        vc.textForQRCodeGeneration = @"xx2812jkaxxcmio";
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
