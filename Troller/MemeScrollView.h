//
//  ThumbPageScrollView.h
//  Flipaper
//
//  Created by Thiago Moretto on 17/10/11.
//  Copyright 2011 MorettoSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#define MEME_SCROLLVIEW_STEP 192
#define MEME_SCROLLVIEW_XOFF 19
@class MemeScrollView;

@protocol MemeScrollViewDelegate <NSObject>
- (void)memeScrollViewDidTouchedAt:(int)index;
@end

@interface MemeScrollView : UIScrollView <UIScrollViewDelegate> {
	int xOffset;
  int numberOfMemes;
	__unsafe_unretained id<MemeScrollViewDelegate> memeDelegate;
}

@property (assign)  id<MemeScrollViewDelegate> memeDelegate;

- (void)addMeme:(UIImage *)memeImage withTag:(int)memeTag;
- (void)scrollToMemeAtIndex:(NSUInteger)index;
- (void)touchedAt:(NSNumber *)thumbTag;

@end
