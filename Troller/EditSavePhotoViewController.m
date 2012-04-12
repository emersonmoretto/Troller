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
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
	CIDetector * faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];

    
    CIImage * cima = [CIImage imageWithCGImage:imageRef];

    NSArray * nfeatures = [faceDetector featuresInImage:cima options:imageOptions];

	for ( CIFaceFeature *ff in nfeatures ) {
        
        NSLog(@"X eye %f",[ff rightEyePosition].x);
        NSLog(@"Y eye %f",[ff rightEyePosition].y);
        
        CGFloat faceWidth = ff.bounds.size.width;

//        CGPoint faceCenter = CGPointMake(((ff.rightEyePosition.y+ff.mouthPosition.y)/2)*0.95,((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);
        
        
        // y = media entre a (media da distancia entre olho e boca) , com o (y do olho)
        CGPoint faceCenter = CGPointMake( ((ff.rightEyePosition.y + (ff.rightEyePosition.y + ff.mouthPosition.y)/2)/2) *0.95,
                                          ((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);
                
        
        // Rotacionando o meme de acordo com a posicao da tela
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
        
        // TODO calcular a proporcao olhos x boca pra escalonar o frame da imageView  ok!! falta aplicar no frame so
        // TODO para a camera frontar, tem que fazer todo o calculo do centro novamente
        // TODO flipar o meme (antes do calculo)
        
        // [imageView setFrame:currentFaceRect];
        [imageView setCenter:faceCenter];
        
        
        
        
        ///////////// DEBUG 
        
        UIView* leftEyeView = [[UIView alloc] 
                               initWithFrame:CGRectMake(ff.leftEyePosition.x-faceWidth*0.15, ff.leftEyePosition.y-faceWidth*0.15,faceWidth*0.3, faceWidth*0.3)];
        // change the background color of the eye view
        [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
        // set the position of the leftEyeView based on the face

        [leftEyeView setCenter:CGPointMake(ff.leftEyePosition.y*0.95,ff.leftEyePosition.x*0.9)];
        // round the corners
        leftEyeView.layer.cornerRadius = faceWidth*0.15;
        
        // add the view to the window        
        [backgroundView addSubview:leftEyeView];       
        
        // create a UIView with a size based on the width of the face
        UIView* leftEye = [[UIView alloc] initWithFrame:CGRectMake(ff.rightEyePosition.x-faceWidth*0.15, ff.rightEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
        // change the background color of the eye view
        [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
        // set the position of the rightEyeView based on the face
        [leftEye setCenter:CGPointMake(ff.rightEyePosition.y*0.95,ff.rightEyePosition.x*0.9)];
        // round the corners
        leftEye.layer.cornerRadius = faceWidth*0.15;
        // add the new view to the window
        [backgroundView addSubview:leftEye];   
        
        // create a UIView with a size based on the width of the face
        UIView* face = [[UIView alloc] initWithFrame:CGRectMake(ff.rightEyePosition.x-faceWidth*0.15, ff.rightEyePosition.y-faceWidth*0.15, faceWidth,faceWidth)];
        // change the background color of the eye view
        [face setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.3]];
        // set the position of the rightEyeView based on the face
        [face setCenter:faceCenter];
        // round the corners
        face.layer.cornerRadius = faceWidth*0.2;
        // add the new view to the window
        [backgroundView addSubview:face];
        
        
        ///////////// END OF DEBUG
        
        
        

   
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
- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

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

}

- (void)viewDidAppear:(BOOL)animated
{
    [imageView setImage:selectedFace];

    UIImage * photo = [[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:90];                
    
    if(isMirrored)
        [backgroundView setImage:[UIImage imageWithCGImage:photo.CGImage scale:1.0 orientation:UIImageOrientationUpMirrored]];
    else
        [backgroundView setImage:[UIImage imageWithCGImage:photo.CGImage]];   

    
    [self drawMemes:frameRect  orientation:[[UIDevice currentDevice] orientation]];    
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
