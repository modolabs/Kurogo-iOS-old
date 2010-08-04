#import <Foundation/Foundation.h>


@interface ModoThreeStateSwitchControl : UISegmentedControl {
	NSArray *activeSegmentImages;
	NSArray *inactiveSegmentImages;
}

- (id)initWithActiveSegmentImages:(NSArray *)activeImages andInactiveSegmentImages:(NSArray *)inactiveImages;

// Call this after a segment is selected so that the correct segment images can be loaded.
- (void)updateSegmentImages;

// These should be arrays of UIImages, one for each segment.
@property (nonatomic, retain) NSArray *activeSegmentImages;
@property (nonatomic, retain) NSArray *inactiveSegmentImages;

@end
