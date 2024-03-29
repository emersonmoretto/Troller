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
- (BOOL)writeCGImageToCameraRoll
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
	
    // TODO atachar os UIViews no background view    
    // talvez adicionando todos eles como layers?
    
    UIGraphicsBeginImageContext(backgroundView.bounds.size);
    [backgroundView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    
	CGImageDestinationAddImage( destination, image.CGImage, optionsDict );
	success = CGImageDestinationFinalize( destination );
    
	if ( optionsDict )
		CFRelease(optionsDict);
	
	//require(success, bail);
	
	CFRetain(destinationData);
	ALAssetsLibrary *library = [ALAssetsLibrary new];
	[library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
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



- (IBAction)save:(id)sender {
    
    [self writeCGImageToCameraRoll];
    /*
     UIGraphicsBeginImageContext(backgroundView.bounds.size);
     [backgroundView.layer renderInContext:UIGraphicsGetCurrentContext()];
     UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     
     
     NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
     [imageData writeToFile:@"public.jpeg" atomically:YES];
     */
    
    
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
        
        CGFloat faceWidth = ff.bounds.size.width;

//        CGPoint faceCenter = CGPointMake(((ff.rightEyePosition.y+ff.mouthPosition.y)/2)*0.95,((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);
        
        
        // y = media entre a (media da distancia entre olho e boca) , com o (y do olho)
        CGPoint faceCenter = CGPointMake( ((ff.rightEyePosition.y + (ff.rightEyePosition.y + ff.mouthPosition.y)/2)/2) *0.95,
                                          ((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);
                
        CGRect faceBounds = CGRectMake(ff.bounds.origin.y*0.95, (ff.bounds.origin.x*0.9), faceWidth*0.95, ff.bounds.size.height*0.9);
        
        // Calculando o centtro da face
        switch (orientation) {
			case UIDeviceOrientationPortrait:
		        faceCenter = CGPointMake(((ff.rightEyePosition.y + ff.leftEyePosition.y)/2)*0.95 , ff.rightEyePosition.x*0.9);                
				break;
			case UIDeviceOrientationPortraitUpsideDown:
		        faceCenter = CGPointMake(((ff.rightEyePosition.y + ff.leftEyePosition.y)/2)*0.95 , ff.rightEyePosition.x*0.9);                                
				break;
			case UIDeviceOrientationLandscapeLeft:
		        faceCenter = CGPointMake(ff.rightEyePosition.y*0.95 , ((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);                
				break;
			case UIDeviceOrientationLandscapeRight:
		        faceCenter = CGPointMake(ff.rightEyePosition.y*0.95 , ((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9);
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}	
        
        // TODO para a camera frontar, tem que fazer todo o calculo do centro novamente
        // TODO flipar o meme (antes do calculo)
        
        
        ///////////// DEBUG 
        
        if(false){
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
            [leftEye setCenter:faceCenter];
            //ff.rightEyePosition.y*0.95 , ((ff.rightEyePosition.x+ff.leftEyePosition.x)/2) *0.9)
            // round the corners
            leftEye.layer.cornerRadius = faceWidth*0.15;
            // add the new view to the window
            [backgroundView addSubview:leftEye];   
            
            // create a UIView with a size based on the width of the face
            UIView* face = [[UIView alloc] initWithFrame:faceBounds];
            // change the background color of the eye view
            [face setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.3]];
            // set the position of the rightEyeView based on the face
        //  [face setCenter:faceCenter];
            // round the corners
            face.layer.cornerRadius = faceWidth*0.2;
            // add the new view to the window
            [backgroundView addSubview:face];
        
        }
        
        ///////////// END OF DEBUG

        
        [imageView setFrame:faceBounds];
        [imageView setCenter:faceCenter];
        
        // rotate and scale
        switch (orientation) {
			case UIDeviceOrientationPortrait:
				[imageView setTransform:CGAffineTransformConcat(CGAffineTransformMakeScale(1.5, 1.5),CGAffineTransformMakeRotation([self degreesToRadians:0]))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[imageView setTransform:CGAffineTransformConcat(CGAffineTransformMakeScale(1.5, 1.5),CGAffineTransformMakeRotation([self degreesToRadians:180]))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[imageView setTransform:CGAffineTransformConcat(CGAffineTransformMakeScale(1.5, 1.5),CGAffineTransformMakeRotation([self degreesToRadians:90]))];                
				break;
			case UIDeviceOrientationLandscapeRight:
				[imageView setTransform:CGAffineTransformConcat(CGAffineTransformMakeScale(1.5, 1.5),CGAffineTransformMakeRotation([self degreesToRadians:-90]))];                
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
