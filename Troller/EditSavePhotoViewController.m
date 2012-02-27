//
//  EditSavePhotoViewController.m
//  Troller
//
//  Created by Emerson Moretto on 10/02/12.
//  Copyright (c) 2012 LSITEC. All rights reserved.
//

#import "EditSavePhotoViewController.h"


@implementation EditSavePhotoViewController

@synthesize imageOptions,selectedFace,features,frameRect, imageRef, attachments,isMirrored;


-(void)takePicture{    
        
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];    
    // Release any cached data, images, etc that aren't in use.
}


// utility routine used after taking a still image to write the resulting image to the camera roll
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
	CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData, 
																		 CFSTR("public.jpeg"), 
																		 1, 
																		 NULL);
	BOOL success = (destination != NULL);
	//require(success, bail);
    
	const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
	CFMutableDictionaryRef optionsDict = NULL;
	CFNumberRef qualityNum = NULL;
	
	qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);    
	if ( qualityNum ) {
		optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ( optionsDict )
			CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
		CFRelease( qualityNum );
	}
	
	CGImageDestinationAddImage( destination, cgImage, optionsDict );
	success = CGImageDestinationFinalize( destination );
    
	if ( optionsDict )
		CFRelease(optionsDict);
	
	//require(success, bail);
	
	CFRetain(destinationData);
	ALAssetsLibrary *library = [ALAssetsLibrary new];
	[library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
		if (destinationData)
			CFRelease(destinationData);
	}];
	
    
    
    //bail:
	if (destinationData)
		CFRelease(destinationData);
	if (destination)
		CFRelease(destination);
    
	return success;
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

- (double)degreesToRadians:(int)degrees
{
    NSNumber * number = [NSNumber numberWithInt:degrees];
    double radians = ([number doubleValue] * M_PI) / 180.0;
    return radians;
}

- (void)drawMemes:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSInteger featuresCount = [features count];
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
  	
	if ( featuresCount == 0) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [backgroundView frame].size;
    
	CGRect previewBox = [EditSavePhotoViewController videoPreviewBoxForGravity:AVLayerVideoGravityResizeAspectFill 
                                                        frameSize:parentFrameSize 
                                                     apertureSize:clap.size];
	
        
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect currentFaceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = currentFaceRect.size.width;
		currentFaceRect.size.width = currentFaceRect.size.height;
		currentFaceRect.size.height = temp;
		temp = currentFaceRect.origin.x;
		currentFaceRect.origin.x = currentFaceRect.origin.y;
		currentFaceRect.origin.y = temp;
		
        // scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		
        currentFaceRect.size.width *= widthScaleBy;
		currentFaceRect.size.height *= heightScaleBy;
		currentFaceRect.origin.x *= widthScaleBy;
		currentFaceRect.origin.y *= heightScaleBy;
        
        //currentFaceRect.size.width *= 1.3;
		//currentFaceRect.size.height *= 1.3;
		//currentFaceRect.origin.x -= currentFaceRect.size.width/5;
		//currentFaceRect.origin.y -= currentFaceRect.size.height/6;
        
		//if ( isMirrored )
		//	currentFaceRect = CGRectOffset(currentFaceRect, previewBox.origin.x + previewBox.size.width - currentFaceRect.size.width - (currentFaceRect.origin.x * 2), previewBox.origin.y);
        //else
			currentFaceRect = CGRectOffset(currentFaceRect, previewBox.origin.x, previewBox.origin.y);
			
        [imageView setFrame:currentFaceRect];
        
        switch (orientation) {
			case UIDeviceOrientationPortrait:
				[imageView setTransform:CGAffineTransformMakeRotation([self degreesToRadians:0])];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[imageView setTransform:CGAffineTransformMakeRotation([self degreesToRadians:180])];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[imageView setTransform:CGAffineTransformMakeRotation([self degreesToRadians:90])];
				break;
			case UIDeviceOrientationLandscapeRight:
				[imageView setTransform:CGAffineTransformMakeRotation([self degreesToRadians:-90])];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}		
	}
	
	[CATransaction commit];
}



#pragma mark - View lifecycle

// Por default, o recognizer nao reconhece multiplos gestos simultaneamente, por isso precisamos 
// classificar nossa classe como delegate e retornar YES nesse metodo. Nao esquecer de apontar no storyboard o delegate novo
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// GESTURE HANDLES
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];    
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
}

- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];    
}

- (void)viewDidAppear:(BOOL)animated
{
    [imageView setImage:selectedFace];
        
    [self drawMemes:frameRect orientation:[[UIDevice currentDevice] orientation]];
    
    // Convert, rotate and apply image to do UIImageView
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:90]];   
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:90]];   
            break;
        case UIDeviceOrientationLandscapeLeft:
            [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:90]];   
            break;
        case UIDeviceOrientationLandscapeRight:
            [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:180]];   
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
            break; // leave the layer in its last known orientation
    }		

    
  //  [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:90]];        
}


- (void)viewDidUnload
{
    imageView = nil;
    view = nil;
    backgroundView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return NO;
}

@end
