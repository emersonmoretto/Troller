//
//  ThumbPageScrollView.m
//  Flipaper
//
//  Created by Thiago Moretto on 17/10/11.
//  Copyright 2011 MorettoSoft. All rights reserved.
//

#import "MemeScrollView.h"
#import "Memeface.h"

#define PAGES_PER_SCREEN 4

@implementation MemeScrollView

@synthesize memeDelegate;

- (void)addMeme:(UIImage *)memeImage withTag:(int)memeTag
{
	Memeface *imageView = [[Memeface alloc] initWithFrame:CGRectMake(5, xOffset, 154, 140)];
	imageView.userInteractionEnabled = YES;
	imageView.image			= memeImage;
	imageView.tag				= memeTag;
	imageView.delegate	= self;
  
    [self addSubview:imageView];

	xOffset += MEME_SCROLLVIEW_STEP;
	[self setContentSize:CGSizeMake(145, xOffset - MEME_SCROLLVIEW_XOFF)];
    numberOfMemes ++;
	
}

- (void)touchedAt:(NSNumber *)thumbTag;
{
	[memeDelegate memeScrollViewDidTouchedAt:[thumbTag integerValue]];
}

- (void)scrollToMemeAtIndex:(NSUInteger)index
{
  if(index == 0) {
    [self setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
  }
  else if(numberOfMemes - index < PAGES_PER_SCREEN) {
    int offset = ((numberOfMemes - PAGES_PER_SCREEN) * 768) / PAGES_PER_SCREEN;
    [self setContentOffset:CGPointMake(offset, 0.0) animated:YES];
  }
  else if(index >= 1) {
    int offset = (index * 768) / PAGES_PER_SCREEN;
    [self setContentOffset:CGPointMake(offset, 0.0) animated:YES];
  }
}

@end
