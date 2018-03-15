//
//  PersonalQRVC.m
//  Created by wuweirong on 16/7/21.
//  Copyright © 2016 bochk. All rights reserved.

#import "PersonalQRVC.h"
#import <AssetsLibrary/AssetsLibrary.h>

static const CGFloat kImageViewRatio = 0.6;        //the QRImageView size by the whole view size

@interface PersonalQRVC ()

@property (nonatomic, strong) UIImageView *topBorder;
@property (nonatomic, strong) UIButton *saveQRCodeButton;
@property (nonatomic, strong) UIImageView *QRImageView;
@property (nonatomic, strong) UILabel *promptLabel;

@property (nonatomic, strong) UIImageView *logoImageView;           //custom QRCode logo
@property (nonatomic, strong) UIImage *qrImage;

@property (nonatomic, assign) CGFloat saveQRCodeButtonHeight;

@end

@implementation PersonalQRVC

#pragma mark - Lazy initialization

- (CGFloat)saveQRCodeButtonHeight {
    if (!_saveQRCodeButtonHeight) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
            _saveQRCodeButtonHeight = 60;
        } else {
            _saveQRCodeButtonHeight = 40;
        }
    }
    return _saveQRCodeButtonHeight;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //    self.textForQRCodeGeneration = [NSString stringWithFormat:@"%@%@",self.textForQRCodeGeneration,QRCodeIdentifier];
    self.textForQRCodeGeneration = [NSString stringWithFormat:@"%@",self.textForQRCodeGeneration];
    
    self.qrImage = [self createQRForString:self.textForQRCodeGeneration];
    [self initViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 80, self.view.frame.size.width * 0.8, self.view.frame.size.width * 0.8)];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.image = self.qrImage;
    [self.view addSubview:imageView];
}

- (void)initViews {
    self.view.backgroundColor = [UIColor whiteColor];
    
//    self.QRImageView.image = self.qrImage;
}

#pragma mark - create QR image

- (UIImage *)createQRForString:(NSString *)qrString {
    // 1.create CIFilter
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.reset CIFilter property
    [filter setDefaults];
    
    // 3.CIFilter add data
    NSString *dataString = qrString;
    
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    [filter setValue:data forKey:@"inputMessage"];
    
    // 4.get QR code CIImage
    CIImage *outputImage = [filter outputImage];
    
    // get the High clear QR Image
    
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:300];
}

/**
 *  CIImage to UIImage
 *
 *  @param image CIImage
 *  @param size  image size
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.create bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.save bitmap
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - check Permisson
- (BOOL)canAccessAlbum {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted) {
        
        NSLog(@"alert info");
        return NO;
    } else if (status == ALAuthorizationStatusNotDetermined) {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (*stop) {
                //the handler of clicking YES
                [self saveQRCodeImage:nil];
                return;
            }
            *stop = TRUE;
        } failureBlock:^(NSError *error) {
            //the handler of Not Permitting
            return ;
        }];
    } else {
        return YES;
    }
    return NO;
}

#pragma mark - Button Action

/**
 *  save generated QRCode to local album
 *
 */
- (void)saveQRCodeImage:(UIButton *)sender {
    if ([self canAccessAlbum]) {
        if (self.QRImageView.image) {
            CGFloat width = self.logoImageView.frame.size.width;
            CGFloat height = self.logoImageView.frame.size.height;
            
            CGSize newSize = CGSizeMake(self.QRImageView.frame.size.width, self.QRImageView.frame.size.height);
            UIGraphicsBeginImageContext( newSize );
            
            // Use existing opacity as is
            [self.QRImageView.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            
            // Apply supplied opacity if applicable
            [self.logoImageView.image drawInRect:CGRectMake((newSize.width - width)/2,(newSize.height - height)/2,width,height) blendMode:kCGBlendModeNormal alpha:1];
            
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
            
            NSLog(@"save success");
        } else {
            NSLog(@"save fail");
        }
    }
}

@end
