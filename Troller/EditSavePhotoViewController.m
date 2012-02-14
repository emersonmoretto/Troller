//
//  EditSavePhotoViewController.m
//  Troller
//
//  Created by Emerson Moretto on 10/02/12.
//  Copyright (c) 2012 LSITEC. All rights reserved.
//

#import "EditSavePhotoViewController.h"


@implementation EditSavePhotoViewController

@synthesize imageOptions,selectedFace,features,faceRect, imageRef, attachments;


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
    // [imageView setImage:selectedFace];
    [imageView setImage:selectedFace];
    
    for ( CIFaceFeature *ff in features ) {
        CGRect face = [ff bounds];
        
        //faceRect.size.width *= 1.092188;
        //faceRect.size.height *= 1.092188;
        //faceRect.origin.x *= 1.092188;
        //faceRect.origin.y *= 1.092188;
        
       // face.size.width *= 1.5;
       // face.size.height *= 1.5;
       // face.origin.x -= face.size.width/5;
      //  face.origin.y -= face.size.height/6;
      
        [imageView setTransform:CGAffineTransformMakeTranslation(face.origin.y,face.origin.x)];
        break;
    }

    
    /*
     NSNumber *orientation = [imageOptions objectForKey:CIDetectorImageOrientation];
     1      Top, left
     2      Top, right
     3      Bottom, right
     4      Bottom, left
     5      Left, top
     6      Right, top
     7      Right, bottom
     8      Left, bottom*/
    
    
    CGFloat rotationDegrees = 0.;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:            
            NSLog(@"UIDeviceOrientationPortrait");
            rotationDegrees = 90.;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"UIDeviceOrientationLandscapeLeft");
            rotationDegrees = 0.;
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"UIDeviceOrientationLandscapeRight");
            rotationDegrees = 180.;
            break;
        case UIDeviceOrientationFaceUp:
            NSLog(@"UIDeviceOrientationFaceUp");    //dafuq?                           
            break;
        case UIDeviceOrientationFaceDown:
            NSLog(@"UIDeviceOrientationFaceDown"); //dafuq?
            break;
        default:
            break; // leave the layer in its last known orientation
    }
    
    // Convert, rotate and apply image to do UIImageView
    [backgroundView setImage:[[UIImage imageWithCGImage:imageRef] imageRotatedByDegrees:rotationDegrees]];
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
	return YES;
}

@end
