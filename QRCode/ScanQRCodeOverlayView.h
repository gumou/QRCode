//
//  ZbarOverlayView.h
//
//  Created by wuweirong on 10/8/16.
//  Copyright (c) 2016年 forms. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QRCodeScannerDelegate <NSObject>
@optional
- (void)showPersonQRCode;

@end

@interface FSScanQRCodeOverlayView : UIView{

}
/**
 *  transparent area
 */
@property (nonatomic, assign) CGRect transparentArea;
@property (nonatomic, weak) id<QRCodeScannerDelegate> myDelegate;

-(void)startAnimation;
-(void)stopAnimation;

@end
