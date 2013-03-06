#import "SimpleVideoFilterViewController.h"

@implementation SimpleVideoFilterViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    GPUImageDotGenerator *crosshairGenerator = [[GPUImageDotGenerator alloc] init];
    crosshairGenerator.crosshairWidth = 20.0;
    [crosshairGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
    self.crosshairGenerator = crosshairGenerator;
    filter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
    [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:0.2];
    
    [(GPUImageHarrisCornerDetectionFilter *)filter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
        [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
    }];
     
    GPUImageSourceOverBlendFilter *blendFilter = [[GPUImageSourceOverBlendFilter alloc] init];
    self.blendFilter = blendFilter;
    [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [videoCamera addTarget:filter];
    [videoCamera addTarget:gammaFilter];
    
    //[filter addTarget:gammaFilter];
    [gammaFilter addTarget:blendFilter];
    
    GPUImageView *filterView = (GPUImageView *)self.view;
    
    [crosshairGenerator addTarget:blendFilter];
    [blendFilter addTarget:filterView];
    [videoCamera startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;

        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;

        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;

        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    videoCamera.outputImageOrientation = orient;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

- (IBAction)updateSliderValue:(id)sender
{
    [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:[(UISlider *)sender value]];
}

- (IBAction)updateSwitchValue:(id)sender
{
    GPUImageView *filterView = (GPUImageView *)self.view;

    if ([(UISwitch*)sender isOn] == YES) {
        [self.crosshairGenerator removeTarget:filterView];
        [self.crosshairGenerator addTarget:self.blendFilter];
        [self.blendFilter addTarget:filterView];
        
    } else {
        
        [self.crosshairGenerator removeTarget:self.blendFilter];
        [self.blendFilter removeTarget:filterView];
        [self.crosshairGenerator addTarget:filterView];
    }
    
}


@end
