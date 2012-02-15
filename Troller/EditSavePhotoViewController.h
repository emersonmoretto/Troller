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
#import "UIImage-Extensions.h"


@interface EditSavePhotoViewController : UIViewController<UIGestureRecognizerDelegate>{
    
    CGImageRef imageRef;
    UIImage *selectedFace;
    NSArray *features;
    CGRect frameRect;
    NSDictionary *imageOptions;
    CFDictionaryRef attachments;
    BOOL isMirrored;
    
    __weak IBOutlet UIImageView *backgroundView;
    __weak IBOutlet UIView *view;
    __weak IBOutlet UIImageView *imageView;
    IBOutlet MemeScrollView *memeScrollView;

     
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer;
- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer;

@property(nonatomic) BOOL isMirrored;
@property(nonatomic) CFDictionaryRef attachments;
@property(nonatomic) CGRect frameRect;
@property(nonatomic) CGImageRef imageRef;
@property(nonatomic,copy) NSDictionary *imageOptions;
@property(nonatomic,copy) UIImage * selectedFace;
@property(nonatomic,copy) NSArray *features;


@end
