//
//  ViewController.h
//  Troller
//
//  Created by Oper on 07/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MemeScrollView.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, MemeScrollViewDelegate>{
    
    IBOutlet UIView *previewView;
    CIDetector *faceDetector;
    UIImageView *memeView;
    AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    dispatch_queue_t videoDataOutputQueue;
    BOOL isUsingFrontFacingCamera;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    //IBOutlet UIView *glassView;
    IBOutlet UIButton *botao;    
    
    NSMutableArray *faces;
    UIImage *selectedFace;
	IBOutlet MemeScrollView *memeScrollView;
    UIDeviceOrientation oldOrientation;
}

- (IBAction)takePicture:(id)sender;
- (IBAction)switchCameras:(id)sender;

@end
