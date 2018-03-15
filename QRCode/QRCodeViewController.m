//
//  QRCodeViewController.m
//
//  Created by wuweirong on 16/7/8.
//  Copyright © 2017年 Forms Syntron Infomation. All rights reserved.
//

#import "QRCodeViewController.h"
#import "ScanQRCodeOverlayView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#define isiPad [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad

static CGFloat const kPreviewY = 160;

@interface QRCodeViewController ()<QRCodeScannerDelegate,AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) CGFloat previewSize;              //the camera view's width and height

@property (nonatomic, strong) FSScanQRCodeOverlayView *overlayView;

@property (nonatomic, assign) BOOL isFirstTimeToAppear;
@property (nonatomic, assign) BOOL isFirstTimeToDidAppear;

@property (nonatomic, assign) UIDeviceOrientation lastDeviceOrientation;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation QRCodeViewController

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (CGFloat)previewSize {
    if (!_previewSize) {
        CGFloat width = self.view.frame.size.width * 6/8;
        CGFloat height = self.view.frame.size.height * 6/8;
        if (isiPad) {
            width = self.view.frame.size.width * 5/8;
            height = self.view.frame.size.height * 5/8;
        }
        _previewSize = MIN(width, height);
    }
    return _previewSize;
}

#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initView];
    self.isFirstTimeToAppear = YES;
    self.isFirstTimeToDidAppear = YES;
    
    if (isiPad) {
        self.lastDeviceOrientation = [UIDevice currentDevice].orientation;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.isFirstTimeToAppear) {
        if ([self isCameraAvailable] && [self canUseCamera]) {
            [self setupScanner];
            [self.session startRunning];
            [_overlayView startAnimation];
        }
        self.isFirstTimeToAppear = NO;
    }
}

- (void)initView {
//    self.view.backgroundColor = [UIColor colorWithRed:0.498 green:0.498 blue:0.498 alpha:1.00];
    
    _overlayView = ({
        FSScanQRCodeOverlayView *tempView = [[FSScanQRCodeOverlayView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//        tempView.backgroundColor = [UIColor colorWithRed:40 / 255.0 green:40 / 255.0 blue:40 / 255.0 alpha:0.9];
        tempView.backgroundColor = [self colorWithHex:0x222222 alpha:0.5];
        
        CGRect rect = CGRectMake((self.view.frame.size.width-self.previewSize) * 0.5, kPreviewY, self.previewSize, self.previewSize);
        tempView.transparentArea = rect;
        tempView.myDelegate = self;
        
        tempView;
    });
    [self.view addSubview:_overlayView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:CGRectMake(20, 20, 120, 120)];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn setTitle:@"back" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
}

- (void)backClick {
    __weak typeof(self) weakSelf = self;
    [_overlayView stopAnimation];
    [weakSelf.navigationController popViewControllerAnimated:NO];
    if (weakSelf.resultBlock) {
        weakSelf.resultBlock(@"");
    }
}

- (void)photoClick {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        
        
    } else if (status == PHAuthorizationStatusNotDetermined) {
        
    } else {
        [self openImagePickerController];
    }
}

- (void)openImagePickerController {
    self.imagePickerController = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        
    }
    self.imagePickerController.delegate = self;
    [self.parentViewController presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
    [self dealImageQRCode:originalImage];
}

- (void)dealImageQRCode:(UIImage *)image {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [detector featuresInImage:ciImage];
    CIQRCodeFeature *feature = [features firstObject];
    NSString *result = feature.messageString;
    if ([result isEqualToString:@""] || result.length == 0) {
        
    }else {
        if (self.resultBlock) {
            self.resultBlock(result);
        }
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)notifyClickAction {
    
}

- (void)setupScanner {
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    } else if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.output];
    [self.session addInput:self.input];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    CGFloat originX = (CGFloat)((self.view.frame.size.width-self.previewSize) * 0.5) / width;
    CGFloat originY = (CGFloat)kPreviewY/height;
    //the x and y reverts...
    self.output.rectOfInterest = CGRectMake(originY,originX,(CGFloat)self.previewSize/height,(CGFloat)self.previewSize/width);
    
    NSLog(@"%@",NSStringFromCGRect(self.output.rectOfInterest));
    
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    if (isiPad) {
        [self setCameraOrientation];
    } else {
        self.preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
//    self.preview.frame = CGRectMake((width-self.previewSize)/2, kPreviewY, self.previewSize, self.previewSize);
    self.preview.frame = self.view.layer.bounds;
//    [self.view.layer addSublayer:self.preview];
    [self.view.layer insertSublayer:self.preview atIndex:0];
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for(AVMetadataObject *current in metadataObjects) {
        if([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            NSString *scannedValue = [((AVMetadataMachineReadableCodeObject *) current) stringValue];
            NSLog(@"__func:%@",scannedValue);
                [self.session stopRunning];
                [_overlayView stopAnimation];
                scannedValue = scannedValue?:@"";
                if (self.resultBlock) {
                    self.resultBlock(scannedValue);
                }
            [self.navigationController popViewControllerAnimated:NO];
//            }
            
        }
    }
}

#pragma mark - check authorization

/**
 *  check the permissiong of accssing user's photo album
 *
 */
- (BOOL) isCameraAvailable {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [videoDevices count] > 0;
}

-(BOOL)canUseCamera {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        NSLog(@"alert info");
        
        return NO;
    } else {
        return YES;
    }
}

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
                return;
            }
            *stop = TRUE;
        } failureBlock:^(NSError *error) {
            //the handler of Not Permitting
            return ;
        }];

    } else if (status == ALAuthorizationStatusAuthorized) {
        return YES;
    }
    return NO;
}

#pragma mark - QRCodeScannerDelegate

#pragma mark - block

- (void)getQrResult:(QrCodeResultBlock)qrResult {
    if (qrResult) {
        self.resultBlock = qrResult;
    }
}

#pragma mark - Device Rotates

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    UIDeviceOrientation currentDeviceOrientation = [UIDevice currentDevice].orientation;
    BOOL invalidOrientation = NO;
    
    switch (currentDeviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            break;
        default:
            invalidOrientation = YES;
            break;
    }
    
    if ((currentDeviceOrientation == _lastDeviceOrientation) || invalidOrientation) {
        return;
    }
    _lastDeviceOrientation = currentDeviceOrientation;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         NSLog(@"%ld__%@",(long)currentDeviceOrientation,NSStringFromCGSize(size));
                         CGRect overlayRect = CGRectMake(0, 0, size.width, size.height);
                         self.overlayView.frame = overlayRect;
                         
                         CGRect transparentArea = CGRectMake((size.width-self.previewSize) * 0.5, kPreviewY, self.previewSize, self.previewSize);
                         self.overlayView.transparentArea = transparentArea;
                         
                         self.preview.frame = CGRectMake(0, 0, size.width, size.height);
                         
                         [self setCameraOrientation];
                         
                         CGRect layerRect = [self.preview metadataOutputRectOfInterestForRect:CGRectMake((size.width-self.previewSize) * 0.5, kPreviewY, self.previewSize, self.previewSize)];
                         self.output.rectOfInterest = layerRect;
                     }];

}

- (void)setCameraOrientation {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            [self.preview.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self.preview.connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self.preview.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
        case UIDeviceOrientationLandscapeRight:
            [self.preview.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
        default:
            break;
    }
}

- (void)dealloc {
    if (_overlayView) {
        [_overlayView stopAnimation];
        [_overlayView removeFromSuperview];
        _overlayView = nil;
    }

}

- (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity
{
    float red = ((float)((hexColor & 0xFF0000) >> 16))/255.0;
    float green = ((float)((hexColor & 0xFF00) >> 8))/255.0;
    float blue = ((float)(hexColor & 0xFF))/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:opacity];
}

@end
