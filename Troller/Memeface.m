//
//  Thumbnail.m
//  Flipaper
//
//  Created by Thiago Moretto on 17/10/11.
//  Copyright 2011 MorettoSoft. All rights reserved.
//

#import "Memeface.h"

@implementation Memeface

@synthesize delegate;


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[delegate performSelector:@selector(touchedAt:) 
								 withObject:[NSNumber numberWithInt:self.tag]];
}

@end
