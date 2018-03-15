//
//  ZbarOverlayView.h
//
//  Created by wuweirong on 10/8/16.
//  Copyright (c) 2016年 forms. All rights reserved.
//

#import "ScanQRCodeOverlayView.h"

static const NSTimeInterval kLineAnimateDuration = 0.02;
static NSString *const kColor16StringChangeRed = @"8d0000";

@interface FSScanQRCodeOverlayView()

@property (nonatomic, strong) UIButton *albumButton;              //for choosing image from local photo album
@property (nonatomic, strong) UIButton *personQRCodeButton;       //for generating person QRCode

@end

@implementation FSScanQRCodeOverlayView{
    UIImageView *_imgLine;//Flashing of the line
    UILabel *_LabDesc;
    CGFloat _lineH;//line's height
    CGFloat _rectY;//Scanning box starting point
    
    NSTimer *_timer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)layoutSubviews {//call when frame change and addSubview 
    
    [self addDescView];
    [self addLine];
    [super layoutSubviews];
}

- (void)setTransparentArea:(CGRect)transparentArea {
    _transparentArea = transparentArea;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)addLine
{
    if (!_imgLine) {
        _imgLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.transparentArea.size.width, 6)];
        _imgLine.image = [UIImage imageNamed:@"scan_line"];
        _imgLine.center = CGPointMake(self.frame.size.width/2, _rectY + 2);
        _lineH = _imgLine.frame.origin.y;
        [self addSubview:_imgLine];
    }
    [_imgLine setFrame:CGRectMake(0, 0, self.transparentArea.size.width, 6)];
    _imgLine.center = CGPointMake(self.frame.size.width/2, _rectY + 2);
    _lineH = _imgLine.frame.origin.y;
}

- (void)addDescView
{
    CGFloat y = self.transparentArea.origin.y + self.transparentArea.size.height + 24;
    
    if (!_LabDesc) {
        _LabDesc = [[UILabel alloc] initWithFrame:CGRectMake(10, y, self.frame.size.width-20, 16)];
        [_LabDesc setTextColor:[UIColor whiteColor]];
        [_LabDesc setFont:[UIFont systemFontOfSize:13]];
        [_LabDesc setText:@"QR scanning prompt"];
        [_LabDesc setBackgroundColor:[UIColor clearColor]];
        [_LabDesc setNumberOfLines:0];
        [_LabDesc setTextAlignment:NSTextAlignmentCenter];
        [_LabDesc sizeToFit];
        [self addSubview:_LabDesc];
    }
    _LabDesc.center = CGPointMake(self.frame.size.width/2, self.transparentArea.origin.y + self.transparentArea.size.height + 24);
    
}

- (void)drawRect:(CGRect)rect {//viewDidLoad after call
    
    //the full QRCode view's color
    CGRect screenDrawRect = self.frame;
    
    //the middle rectangular
    CGRect clearDrawRect = self.transparentArea;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self addScreenFillRect:ctx rect:screenDrawRect];
    
    [self addCenterClearRect:ctx rect:clearDrawRect];
    
    [self addWhiteRect:ctx rect:clearDrawRect];
    
    [self addCornerLineWithContext:ctx rect:clearDrawRect];
}

- (void)addScreenFillRect:(CGContextRef)ctx rect:(CGRect)rect {
    
    CGContextSetRGBFillColor(ctx, 127/255.0,127/255.0,127/255.0,1);       //gray color
}

- (void)addCenterClearRect :(CGContextRef)ctx rect:(CGRect)rect {
    
    CGContextClearRect(ctx, rect);  //clear the center rect  of the layer
}

- (void)addWhiteRect:(CGContextRef)ctx rect:(CGRect)rect {
    
    CGContextStrokeRect(ctx, rect);
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);//white color
    CGContextSetLineWidth(ctx, 0.8);//line's width
    CGContextAddRect(ctx, rect);//Create a rectangular path
    CGContextStrokePath(ctx);//Article filled rectangular
}

- (void)addCornerLineWithContext:(CGContextRef)ctx rect:(CGRect)rect{
    
    //Draw four corners
    CGContextSetLineWidth(ctx, 3);
    CGContextSetRGBStrokeColor(ctx, 164/255.0, 4/255.0, 28/255.0, 1);//red color
    
    //The upper left corner
    CGPoint poinsTopLeftA[] = {
        CGPointMake(rect.origin.x+0.7, rect.origin.y),
        CGPointMake(rect.origin.x+0.7 , rect.origin.y + 15)
    };
    
    CGPoint poinsTopLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y +0.7),CGPointMake(rect.origin.x + 15, rect.origin.y+0.7)};
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:ctx];
    
    //The lower left corner
    CGPoint poinsBottomLeftA[] = {CGPointMake(rect.origin.x+ 0.7, rect.origin.y + rect.size.height - 15),CGPointMake(rect.origin.x +0.7,rect.origin.y + rect.size.height)};
    CGPoint poinsBottomLeftB[] = {CGPointMake(rect.origin.x , rect.origin.y + rect.size.height - 0.7) ,CGPointMake(rect.origin.x+0.7 +15, rect.origin.y + rect.size.height - 0.7)};
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:ctx];
    
    //The top right corner
    CGPoint poinsTopRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - 15, rect.origin.y+0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y +0.7 )};
    CGPoint poinsTopRightB[] = {CGPointMake(rect.origin.x+ rect.size.width-0.7, rect.origin.y),CGPointMake(rect.origin.x + rect.size.width-0.7,rect.origin.y + 15 +0.7 )};
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:ctx];
    
    CGPoint poinsBottomRightA[] = {CGPointMake(rect.origin.x+ rect.size.width -0.7 , rect.origin.y+rect.size.height+ -15),CGPointMake(rect.origin.x-0.7 + rect.size.width,rect.origin.y +rect.size.height )};
    CGPoint poinsBottomRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - 15 , rect.origin.y + rect.size.height-0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height - 0.7 )};
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:ctx];
    CGContextStrokePath(ctx);
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx {
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}

- (void)lineDrop
{
    [UIView animateWithDuration:kLineAnimateDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        CGRect rect = _imgLine.frame;
        rect.origin.y = _lineH;
        _imgLine.frame = rect;
    }completion:^(BOOL complite){
        CGFloat maxBorder = _rectY + self.transparentArea.size.height - 4;
        if (_lineH > maxBorder) {
            
            _lineH = _rectY + 4;
        }
        _lineH ++;
    }];
}


-(void)startAnimation {
    if (!_imgLine) {
        _rectY = self.transparentArea.origin.y;
        [self addLine];//can't add in init
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
        animation.repeatCount = HUGE;
        animation.duration = 4;
        animation.removedOnCompletion = NO;
        animation.beginTime = CACurrentMediaTime();
        animation.fromValue = @(self.transparentArea.origin.y);
        animation.toValue = @(self.transparentArea.origin.y+self.transparentArea.size.height);
        [_imgLine.layer addAnimation:animation forKey:nil];
    }
    
}
-(void)stopAnimation{
    if (_imgLine) {
        [_imgLine.layer removeAllAnimations];
    }
    
}
@end
