#import "KGODetailPager.h"

static NSString * UpArrowImage = @"common/arrow-white-up.png";
static NSString * DownArrowImage = @"common/arrow-white-down.png";

#define PAGE_UP_SEGMENT 0
#define PAGE_DOWN_SEGMENT 1

@interface KGODetailPager (Private)

- (void)didSelectSegment:(id)sender;
- (void)updateSegmentStates;
- (void)selectPageAtSection:(NSInteger)section row:(NSInteger)row;
- (void)pageUp;
- (void)pageDown;

@end


@implementation KGODetailPager

@synthesize currentIndexPath = _currentIndexPath, delegate = _pagerDelegate, controller = _pagerController;


- (id)initWithPagerController:(id<KGODetailPagerController>)controller delegate:(id<KGODetailPagerDelegate>)delegate {
    self = [super initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:UpArrowImage], [UIImage imageNamed:DownArrowImage], nil]];
    if (self) {
		_pagerController = controller;
		_pagerDelegate = delegate;
		
		NSIndexPath *indexPathBuilder = nil;
		NSUInteger numberOfSections = [controller numberOfSections:self];
		
		if (numberOfSections) {
			_sections = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, numberOfSections)];
			
			NSUInteger numberOfPages = [controller pager:self numberOfPagesInSection:0];
			indexPathBuilder = [NSIndexPath indexPathWithIndex:numberOfPages];
			
			for (NSUInteger i = 1; i < numberOfSections; i++) {
				numberOfPages = [controller pager:self numberOfPagesInSection:0];
				indexPathBuilder = [indexPathBuilder indexPathByAddingIndex:numberOfPages];
			}
		}
		
		if (numberOfSections) {
			_pagesBySection = [indexPathBuilder retain];
		}
		
        [self setMomentary:YES];
        [self addTarget:self action:@selector(didSelectSegment:) forControlEvents:UIControlEventValueChanged];
        [self updateSegmentStates];
    }
    return self;
}

- (void)updateSegmentStates {
	BOOL canPageUp = YES;
	BOOL canPageDown = YES;

	NSUInteger section = _currentIndexPath.section;
	
	if (section == [_sections firstIndex]) {
		if (self.currentIndexPath.row <= 0) {
			canPageUp = NO;
		}
	}
	
	if (section == [_sections lastIndex]) {
		NSUInteger maxPages = [_pagesBySection indexAtPosition:section];
		if (self.currentIndexPath.row >= maxPages - 1) {
			canPageDown = NO;
		}
	}
	
    [self setEnabled:canPageUp forSegmentAtIndex:PAGE_UP_SEGMENT];
    [self setEnabled:canPageDown forSegmentAtIndex:PAGE_DOWN_SEGMENT];
}

- (void)pageUp {
	NSInteger section = _currentIndexPath.section;
	NSInteger row = _currentIndexPath.row - 1;

	while (section >= 0 && row < 0) { // in case there are empty sections
		section--;
		row = [_pagesBySection indexAtPosition:section] - 1;
	}
	
	[self selectPageAtSection:section row:row];
}

- (void)pageDown {
	NSInteger section = _currentIndexPath.section;
	NSInteger row = _currentIndexPath.row + 1;
	NSUInteger maxSection = [_sections lastIndex];
	
	while (section <= maxSection && row > [_pagesBySection indexAtPosition:section] - 1) { // in case there are empty sections
		section++;
		row = 0;
	}
	
	[self selectPageAtSection:section row:row];
}

- (void)selectPageAtSection:(NSInteger)section row:(NSInteger)row {
	if (section >= 0 && row >= 0) {
		self.currentIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		id<KGOSearchResult> content = [self.controller pager:self contentForPageAtIndexPath:self.currentIndexPath];
		[self.delegate pager:self showContentForPage:content];
        [self updateSegmentStates];
	}
}

- (void)didSelectSegment:(id)sender {
    if (sender == self) {
        if (self.selectedSegmentIndex == PAGE_UP_SEGMENT) {
			[self pageUp];
        } else {
			[self pageDown];
        }
    }
}

- (void)dealloc {
	_pagerDelegate = nil;
	_pagerController = nil;
	self.currentIndexPath = nil;
	[_sections release];
	[_pagesBySection release];
	[super dealloc];
}


@end
