//
//  ViewController.m
//  Troller
//
//  Created by Oper on 07/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssertMacros.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage-Extensions.h"

@implementation ViewController


// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";



// clean up capture setup
- (void)teardownAVCapture
{
    //	[videoDataOutput release];
	if (videoDataOutputQueue)
		dispatch_release(videoDataOutputQueue);
	[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	//[stillImageOutput release];
	[previewLayer removeFromSuperlayer];
	//[previewLayer release];
}



- (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


- (void)memeScrollViewDidTouchedAt:(int)tagidx
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
//	[selectedFace setAlpha:0.0];
	[UIView commitAnimations];

    CABasicAnimation *theAnimation;
    
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=0.8;
    theAnimation.repeatCount=1;
    theAnimation.autoreverses=NO;
    theAnimation.fromValue=[NSNumber numberWithFloat:0.0];
    theAnimation.toValue=[NSNumber numberWithFloat:1.0];

    
	selectedFace = [faces objectAtIndex:tagidx];//[UIImage imageNamed:@"notbad.png"];//

    //selectedFace = [self imageWithImage:selectedFace scaledToSize:CGSizeMake(800, 800)];
    
	// procurando a layer do meme e trocando o conteudo dela
    NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
    for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] ){
            //[layer setAffineTransform:CGAffineTransformMakeScale(2.5, 2.5)];
            [layer setContents:(id)[selectedFace CGImage]];    
            [layer addAnimation:theAnimation forKey:@"animateOpacity"];
            
        }
    }
       
        
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.6];
	//[selectedFace setAlpha:1.0];
	[UIView commitAnimations];	
}


- (void)setupMemeScrollView {
    
    UIImage *pattern = [UIImage imageNamed:@"real_cf.png"];
	UIColor *background = [UIColor colorWithPatternImage:pattern];
	[memeScrollView setBackgroundColor:background];
	memeScrollView.memeDelegate = self;
	
	faces = [[NSMutableArray alloc] init];
	[faces addObject:[UIImage imageNamed:@"megusta.png"]];
	[faces addObject:[UIImage imageNamed:@"impossibru.png"]];
	[faces addObject:[UIImage imageNamed:@"notbad.png"]];
	[faces addObject:[UIImage imageNamed:@"lol.png"]];
   	[faces addObject:[UIImage imageNamed:@"forever.png"]];
  	[faces addObject:[UIImage imageNamed:@"yuno.png"]];
  	[faces addObject:[UIImage imageNamed:@"pedobear.png"]];
   	[faces addObject:[UIImage imageNamed:@"fuckthat.png"]];
   	[faces addObject:[UIImage imageNamed:@"fuckyeah.png"]];
  	[faces addObject:[UIImage imageNamed:@"neildegrasse.png"]];
  	[faces addObject:[UIImage imageNamed:@"okay.png"]];    
  	[faces addObject:[UIImage imageNamed:@"nerd.png"]];
  	[faces addObject:[UIImage imageNamed:@"seriously.png"]];        
   	[faces addObject:[UIImage imageNamed:@"motherofgod.png"]];
    
      
    selectedFace = [faces objectAtIndex:(arc4random() % [faces count])];
    
	int tagidx = 0;
	for (UIImage *face in faces) {       
        
		[memeScrollView addMeme:face withTag:tagidx];
		tagidx++;
	}
    
}

- (void)setupAVCapture
{
	NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [session setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [session setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device, make an input
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	
    //require( error == nil, bail );
	
    isUsingFrontFacingCamera = NO;
	if ( [session canAddInput:deviceInput] )
		[session addInput:deviceInput];
	
    // Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	//[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:AVCaptureStillImageIsCapturingStillImageContext];
    
	if ( [session canAddOutput:stillImageOutput] )
		[session addOutput:stillImageOutput];
	
    // Make a video data output
	videoDataOutput = [AVCaptureVideoDataOutput new];
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	
    if ( [session canAddOutput:videoDataOutput] )
		[session addOutput:videoDataOutput];
    
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:TRUE];
	
	effectiveScale = 1.0;
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	
    CALayer *rootLayer = [previewView layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
    
    //CGAffineTransform tr = CGAffineTransformMakeRotation(90);
    //[glassView setTransform:tr];
    
	[rootLayer addSublayer:previewLayer];
    [session startRunning];
    
bail:
	//[session release];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
		[alertView show];
		//[alertView release];
		[self teardownAVCapture];
	}
}


// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}
/*

- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features 
                                       inCGImage:(CGImageRef)backgroundImage 
                                 withOrientation:(UIDeviceOrientation)orientation 
                                     frontFacing:(BOOL)isFrontFacing
{
    
    

    
	CGImageRef returnImage = NULL;
	CGRect backgroundImageRect = CGRectMake(0., 0., CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage));
//	CGContextRef bitmapContext = CGBitmapContextCreate(
	
                                                       
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddres(backgroundImage); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer); 
    size_t width = CVPixelBufferGetWidth(pixelBuffer); 
    size_t height = CVPixelBufferGetHeight(pixelBuffer);  
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    

    
    CGContextClearRect(bitmapContext, backgroundImageRect);
	CGContextDrawImage(bitmapContext, backgroundImageRect, backgroundImage);
	CGFloat rotationDegrees = 0.;
	
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = 90.;
			break;
		case UIDeviceOrientationLandscapeLeft:
			if (isFrontFacing) rotationDegrees = 180.;
			else rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			if (isFrontFacing) rotationDegrees = 0.;
			else rotationDegrees = 180.;
			break;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			break; // leave the layer in its last known orientation
	}
    
	 // features found by the face detector
	for ( CIFaceFeature *ff in features ) {
		CGRect faceRect = [ff bounds];
		CGContextDrawImage(bitmapContext, faceRect, [selectedFace CGImage]);
	}
	returnImage = CGBitmapContextCreateImage(bitmapContext);
	CGContextRelease (bitmapContext);
	
	return returnImage;
}
*/
 
/*

static inline double radians (double degrees) {return degrees * M_PI/180;}
- (UIImage* rotate(UIImage* src, UIImageOrientation orientation)
{
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (orientation == UIImageOrientationDown) {
        // NOTHING
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}
*/

- (void)takePicture:(EditSavePhotoViewController *)editor
{
            
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
	
    
    // set the appropriate pixel format / image type output setting depending on if we'll need an uncompressed image for
    // the possiblity of drawing the red square over top or if we're just writing a jpeg to the camera roll which is the trival case
		[stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                           completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) 
    {
        
      CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(imageDataSampleBuffer);
        
      CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);

      editor.frameRect = clap;
      editor.isMirrored = isUsingFrontFacingCamera;
                                                      
      // Got an image.
      CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
      CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
      
      CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];      
               
      if (attachments)
          CFRelease(attachments);
      
      NSDictionary *imageOptions = nil;
      
      CFNumberRef orientationRef = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyOrientation, NULL);
      NSNumber *orientation = (__bridge NSNumber *) orientationRef;                                                    
      
      if (orientation) {
          imageOptions = [NSDictionary dictionaryWithObject:orientation forKey:CIDetectorImageOrientation];
      }
      
      // when processing an existing frame we want any new frames to be automatically dropped
      // queueing this block to execute on the videoDataOutputQueue serial queue ensures this
      // see the header doc for setSampleBufferDelegate:queue: for more information
      dispatch_sync(videoDataOutputQueue, ^(void) {
          
          NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
          
          CGImageRef srcImage = NULL;
          
          /*
          CGImageRef cgImageResult = [self newSquareOverlayedImageForFeatures:features 
                                                                    inCGImage:srcImage 
                                                              withOrientation:curDeviceOrientation 
                                                                  frontFacing:isUsingFrontFacingCamera];
          */
          
          /*OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
           
           //check(!err);          
           Create a CGImageRef from the CVImageBufferRef
           */
          //CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
          /*Lock the image buffer*/
          CVPixelBufferLockBaseAddress(pixelBuffer,0); 
          
          uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer); 
          size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer); 
          size_t width = CVPixelBufferGetWidth(pixelBuffer); 
          size_t height = CVPixelBufferGetHeight(pixelBuffer);  
          
          CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
          CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
          
          
          //flipp
          //CGAffineTransform flipVertical = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
          //CGContextConcatCTM(newContext,flipVertical);
          
          CGImageRef newImage;// = CGBitmapContextCreateImage(newContext);
          
          newImage = CGBitmapContextCreateImage(newContext);
          editor.imageRef = newImage;          
          CGContextRelease (newContext);
          
          editor.isMirrored = isUsingFrontFacingCamera;
          editor.features = features;
          editor.selectedFace = selectedFace;
          editor.imageOptions = imageOptions;
          //editor.frameRect = clap;
          
          // aplicando a face de acordo com as features
          for ( CIFaceFeature *ff in features ) {
              CGRect faceRect = [ff bounds];
              
              //faceRect.size.width *= 1.092188;
              //faceRect.size.height *= 1.092188;
              //faceRect.origin.x *= 1.092188;
              //faceRect.origin.y *= 1.092188;
              
              faceRect.size.width *= 1.4;
              faceRect.size.height *= 1.4;
              faceRect.origin.x -= faceRect.size.width/4;
              faceRect.origin.y -= faceRect.size.height/5;
              /*
              
              UIImage * newFace;
              switch (curDeviceOrientation) {
                  case UIDeviceOrientationPortrait:
                      newFace = [selectedFace imageRotatedByDegrees:-90];
                      NSLog(@"UIDeviceOrientationPortrait");
                      //rotationDegrees = -90.;
                      break;
                  case UIDeviceOrientationPortraitUpsideDown:
                      if (isUsingFrontFacingCamera)
                          newFace = [selectedFace imageRotatedByDegrees:90];
                      else
                          newFace = [selectedFace imageRotatedByDegrees:90];
                      
                      NSLog(@"UIDeviceOrientationPortraitUpsideDown");
                      //rotationDegrees = 90.;
                      break;
                  case UIDeviceOrientationLandscapeLeft:
                      if (isUsingFrontFacingCamera) 
                          newFace = [selectedFace imageRotatedByDegrees:90];                              
                      
                      NSLog(@"UIDeviceOrientationLandscapeLeft");
                      break;
                  case UIDeviceOrientationLandscapeRight:
                      if (!isUsingFrontFacingCamera)
                          newFace = [selectedFace imageRotatedByDegrees:180];
                      NSLog(@"UIDeviceOrientationLandscapeRight");
                      
                      break;
                  case UIDeviceOrientationFaceUp:
                      NSLog(@"UIDeviceOrientationFaceUp");                              
                      break;
                  case UIDeviceOrientationFaceDown:
                      NSLog(@"UIDeviceOrientationFaceDown");
                      break;
                  default:
                      break; // leave the layer in its last known orientation
              }
              */
              
              // Aplicando o meme sobre a foto
              //CGContextDrawImage(newContext, faceRect, [newFace CGImage]);
          }        
          
          CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, 
                                                                      imageDataSampleBuffer, 
                                                                      kCMAttachmentMode_ShouldPropagate);
          
          editor.attachments = attachments;
          //[self writeCGImageToCameraRoll:newImage withMetadata:(__bridge id)attachments];
          
          if (srcImage)
              CFRelease(srcImage);
          
          if (attachments)
              CFRelease(attachments);
          
      });
    }
	];
}

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
	AVCaptureDevicePosition desiredPosition;
    
	if (isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			
            for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

- (double)degreesToRadians:(int)degrees
{
    NSNumber * number = [NSNumber numberWithInt:degrees];
    double radians = ([number doubleValue] * M_PI) / 180.0;
    return radians;
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

- (void)drawMemes:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}	
    
  	
	if ( featuresCount == 0) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	BOOL isMirrored = [previewLayer isMirrored];
	CGRect previewBox = [ViewController videoPreviewBoxForGravity:gravity 
                                                                 frameSize:parentFrameSize 
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		
        // scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		
       // NSLog(@"aquu %f e %f", widthScaleBy, widthScaleBy);
        faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
      
        faceRect.size.width *= 1.6;
		faceRect.size.height *= 1.6;
		faceRect.origin.x -= faceRect.size.width/5;
		faceRect.origin.y -= faceRect.size.height/6;
             
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
        
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];

			[featureLayer setContents:(id)[selectedFace CGImage]];           
			[featureLayer setName:@"FaceLayer"];
            [previewLayer addSublayer:featureLayer];
           
            NSLog(@"layer criada");
			
		}
        lastFaceRect = faceRect;
		[featureLayer setFrame:faceRect];
        
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation([self degreesToRadians:0])];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation([self degreesToRadians:180])];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation([self degreesToRadians:90])];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation([self degreesToRadians:-90])];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{	
    
        
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	
    if (attachments)
		CFRelease(attachments);
	
    NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants. 
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
	//[ciImage release];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);

    dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawMemes:features forVideoBox:clap orientation:curDeviceOrientation];
	});       
}


- (void)viewDidUnload
{
    activityIndicator = nil;
    //glassView = nil;
    botao = nil;
    btSwitch = nil;
    btPhoto = nil;
    t = nil;
    o = nil;
    r = nil;
    r = nil;
    l = nil;
    ll = nil;
    e = nil;
    rr = nil;
    r = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"takePictureSegue"]){
        
        editSavePhotoViewController = (EditSavePhotoViewController *)[segue destinationViewController];
        
        [self takePicture:editSavePhotoViewController];

            
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setupMemeScrollView];
  	[self setupAVCapture];
    
    
    
    [[UIDevice  currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    oldOrientation = [[UIDevice currentDevice] orientation];
	NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    
     //editSavePhotoViewController = [storyboard instantiateViewControllerWithIdentifier:@"EditSavePhotoViewController"];
    
    //[editSavePhotoViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    
   // [self presentModalViewController:editSavePhotoViewController animated:YES];

    
    //editSavePhotoViewController = [[EditSavePhotoViewController alloc] init];
    
	//[detectorOptions release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

-(void)detectOrientation: (NSNotification *)notification{

    CGFloat transform = 0.0;
    if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        transform = 0.0;
    }
    if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortraitUpsideDown) {
        transform = -M_PI;
    }
    if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        transform = -M_PI/2;
    }
    if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        transform = M_PI/2;
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    for ( UIView *view in [memeScrollView subviews]) {
        [view setTransform:CGAffineTransformMakeRotation(transform)];
    }
    [btSwitch setTransform:CGAffineTransformMakeRotation(transform)];
    [btPhoto setTransform:CGAffineTransformMakeRotation(transform)];
    [t setTransform:CGAffineTransformMakeRotation(transform)];
    [r setTransform:CGAffineTransformMakeRotation(transform)];
    [o setTransform:CGAffineTransformMakeRotation(transform)];
    [l setTransform:CGAffineTransformMakeRotation(transform)];    
    [ll setTransform:CGAffineTransformMakeRotation(transform)];
    [e setTransform:CGAffineTransformMakeRotation(transform)];
    [rr setTransform:CGAffineTransformMakeRotation(transform)];    
    
    [UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{        
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
