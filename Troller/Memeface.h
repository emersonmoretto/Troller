//
//  Thumbnail.h
//  Flipaper
//
//  Created by Thiago Moretto on 17/10/11.
//  Copyright 2011 MorettoSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Memeface : UIImageView {
	__unsafe_unretained id delegate;
}

@property (assign) id delegate;
@end
