//
//  EditSavePhotoViewController.h
//  Troller
//
//  Created by Emerson Moretto on 10/02/12.
//  Copyright (c) 2012 LSITEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MemeScrollView.h"


@interface EditSavePhotoViewController : UIViewController<UIGestureRecognizerDelegate>{
    
    CIImage *image;
    UIImage *selectedFace;
    NSArray *features;
    CGRect faceRect;
    
    __weak IBOutlet UIView *view;
    __weak IBOutlet UIImageView *imageView;
    IBOutlet MemeScrollView *memeScrollView;

     
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer;
- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer;

@property(nonatomic) CGRect faceRect;
@property(nonatomic,copy) CIImage * image;
@property(nonatomic,copy) UIImage * selectedFace;
@property(nonatomic,copy) NSArray *features;


@end
