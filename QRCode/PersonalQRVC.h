//
//  PersonalQRVC.h
//  Created by wuweirong on 16/7/21.
//  Copyright © 2016 bochk. All rights reserved.
//  Function : display personal QR Code

#import <UIKit/UIKit.h>

@interface PersonalQRVC : UIViewController

typedef void(^PersonalQRBackBlock)(void);

/**
 *  the text is useed to generate QR Code.Required!
 */
@property (nonatomic, strong) NSString *textForQRCodeGeneration;

@property (nonatomic, copy) PersonalQRBackBlock backBlock;

@end
