#import "KGODetailPager.h"

static NSString * UpArrowImage = @"common/arrow-white-up.png";
static NSString * DownArrowImage = @"common/arrow-white-down.png";

#define PAGE_UP_SEGMENT 0
#define PAGE_DOWN_SEGMENT 1

@interface KGODetailPager (Private)

- (void)didSelectSegment:(id)sender;
- (void)updateSegmentStates;

@end


@implementation KGODetailPager

@synthesize controller, delegate;

- (id)init {
    if (self = [super initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:UpArrowImage], [UIImage imageNamed:DownArrowImage], nil]]) {
        [self updateSegmentStates];
        [self setMomentary:YES];
        [self addTarget:self action:@selector(didSelectSegment:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)updateSegmentStates {
    [self setEnabled:[self.controller pagerCanShowPreviousPage:self] forSegmentAtIndex:PAGE_UP_SEGMENT];
    [self setEnabled:[self.controller pagerCanShowNextPage:self] forSegmentAtIndex:PAGE_DOWN_SEGMENT];
}

- (void)didSelectSegment:(id)sender {
    if (sender == self) {
        if (self.selectedSegmentIndex == PAGE_UP_SEGMENT) {
            id content = [self.controller contentForPreviousPage:self];
			[self.delegate pager:self showContentForPage:content];
        } else {
            id content = [self.controller contentForNextPage:self];
			[self.delegate pager:self showContentForPage:content];
        }
        [self updateSegmentStates];
    }
}

- (void)dealloc {
    self.delegate = nil;
	self.controller = nil;
    [super dealloc];
}


@end
