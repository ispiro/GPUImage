#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

@property (nonatomic, strong) GPUImageDotGenerator* crosshairGenerator;
@property (nonatomic, strong) GPUImageSourceOverBlendFilter* blendFilter;

- (IBAction)updateSliderValue:(id)sender;
- (IBAction)updateSwitchValue:(id)sender;

@end
