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
#import "EditSavePhotoViewController.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, MemeScrollViewDelegate>{
    
    IBOutlet UIView *previewView;
    CIDetector *faceDetector;
    UIImageView *memeView;
    AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    dispatch_queue_t videoDataOutputQueue;
    BOOL isUsingFrontFacingCamera;
    __weak IBOutlet UIImageView *t;
    __weak IBOutlet UIImageView *r;
    __weak IBOutlet UIImageView *o;
    __weak IBOutlet UIImageView *l;
    __weak IBOutlet UIImageView *ll;
    __weak IBOutlet UIImageView *e;
    __weak IBOutlet UIImageView *rr;
    
	
  
    __weak IBOutlet UIButton *btPhoto;
    __weak IBOutlet UIButton *btSwitch;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    //IBOutlet UIView *glassView;
    IBOutlet UIButton *botao;    
    CGFloat effectiveScale;
    NSMutableArray *faces;
    UIImage *selectedFace;
    CGRect lastFaceRect;
	IBOutlet MemeScrollView *memeScrollView;
    UIDeviceOrientation oldOrientation;
    CGRect clap;
    
    IBOutlet EditSavePhotoViewController * editSavePhotoViewController;
    
}


- (IBAction)switchCameras:(id)sender;

@end
