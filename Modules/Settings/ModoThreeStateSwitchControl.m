/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "ModoThreeStateSwitchControl.h"


@implementation ModoThreeStateSwitchControl

@synthesize activeSegmentImages, inactiveSegmentImages;

- (id)initWithActiveSegmentImages:(NSArray *)activeImages andInactiveSegmentImages:(NSArray *)inactiveImages 
{
    self = [super initWithItems:inactiveImages];
	if (self) 
	{
		self.activeSegmentImages = activeImages;
		self.inactiveSegmentImages = inactiveImages;
	}
	return self;
}

- (void)dealloc {
	self.activeSegmentImages = nil;
	self.inactiveSegmentImages = nil;
	[super dealloc];
}

- (void)updateSegmentImages {
	
	for (NSInteger i = 0; (i < self.numberOfSegments) && (i < activeSegmentImages.count) && (i < inactiveSegmentImages.count) ; ++i) {
		UIImage *updatedImage = nil;
		if (self.selectedSegmentIndex == i) {
			updatedImage = [activeSegmentImages objectAtIndex:i];
		} else {
			updatedImage = [inactiveSegmentImages objectAtIndex:i];
		}
		UIImage *currentImage = [self imageForSegmentAtIndex:i];
		if (updatedImage && (currentImage != updatedImage)) {
			[self setImage:updatedImage forSegmentAtIndex:i];
		}
	}
}

@end
