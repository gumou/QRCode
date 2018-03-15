//
//  QRCodeViewController.h
//  Created by zhuliuquan on 16/7/21.
//  Copyright © 2017年 Forms Syntron Infomation. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^QrCodeResultBlock)(NSString *result);

@interface QRCodeViewController : UIViewController

@property (nonatomic, copy) NSString *myQRCodeString;
@property (nonatomic, copy) QrCodeResultBlock resultBlock;

- (void)getQrResult:(QrCodeResultBlock)qrResult;

@end
