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

@synthesize delegate = _pagerDelegate;

- (id)initWithDelegate:(id<KGODetailPagerDelegate>)delegate {
    if (self = [super initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:UpArrowImage], [UIImage imageNamed:DownArrowImage], nil]]) {
        self.delegate = delegate;
        [self updateSegmentStates];
        [self setMomentary:YES];
        [self addTarget:self action:@selector(didSelectSegment:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)updateSegmentStates {
    [self setEnabled:[self.delegate pagerCanPageUp:self] forSegmentAtIndex:PAGE_UP_SEGMENT];
    [self setEnabled:[self.delegate pagerCanPageDown:self] forSegmentAtIndex:PAGE_DOWN_SEGMENT];
}

- (void)didSelectSegment:(id)sender {
    if (sender == self) {
        NSInteger i = self.selectedSegmentIndex;
        if (i == PAGE_UP_SEGMENT) {
            [self.delegate pageUp:self];
        } else {
            [self.delegate pageDown:self];
        }
        [self updateSegmentStates];
    }
}

- (void)dealloc {
    self.delegate = nil;
    [super dealloc];
}


@end
