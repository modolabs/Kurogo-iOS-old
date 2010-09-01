/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/


#import "DiningTabViewControl.h"

#define kTabFontSize 14 // was 15
#define kTabCurveRadius 12 
#define kTabTextPadding 10 // px between tab and start of text //was 22
#define kTabSapcing 2      // px between tabs //was 4

#define kUnselectedFillColorR 153.0
#define kUnselectedFillColorG 172.0
#define kUnselectedFillColorB 191.0

#define kSelectedFillColorR 255.0 
#define kSelectedFillColorG 255.0
#define kSelectedFillColorB 255.0

#define kTabFontColorR 50.0
#define kTabFontColorG 58.0
#define kTabFontColorB 77.0

#define MakeUIColor(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]

@interface DiningTabViewControl(Private) 

-(int) tabIndexAtLocation:(CGPoint)point;

@end


@implementation DiningTabViewControl
@synthesize tabs = _tabs;
@synthesize selectedTab = _selectedTab;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.opaque = NO;
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
		_pressedTab = -1;
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	if(self = [super initWithCoder:aDecoder])
	{
		self.opaque = NO;
		
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
		_pressedTab = -1;
	}
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	if (nil == _tabFont) {
		_tabFont = [[UIFont boldSystemFontOfSize:kTabFontSize] retain];
	}
	
	UIImage *tabBackground = nil;
    
	CGContextRef dc =  UIGraphicsGetCurrentContext();
	
	int tabOffset = 10;
	
	for (int tabIdx = 0; tabIdx < self.tabs.count; tabIdx++) {
		
		NSString* tabText = [self.tabs objectAtIndex:tabIdx];
		
		if (self.selectedTab == tabIdx) {
            tabBackground = [[UIImage imageNamed:@"global/tab-active.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
		}
		else if (_pressedTab == tabIdx) {
            tabBackground = [[UIImage imageNamed:@"global/tab-inactive-pressed.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
		}
		else {
            tabBackground = [[UIImage imageNamed:@"global/tab-inactive.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
		}
        
		CGSize textSize = [tabText sizeWithFont:_tabFont];
        CGRect currentRect = CGRectMake(tabOffset, 0, textSize.width + kTabTextPadding * 2, self.frame.size.height);
        
        [tabBackground drawInRect:currentRect];
		
		// draw the text
		UIColor* textColor  = (self.selectedTab == tabIdx) ? [UIColor blackColor] : [UIColor whiteColor];
		
		CGContextSetFillColorWithColor(dc, textColor.CGColor);
		CGRect textRect = CGRectMake(tabOffset + kTabTextPadding, (self.frame.size.height - textSize.height) / 2, textSize.width, textSize.height);
		[tabText drawInRect:textRect withFont:_tabFont];
		
		// set the offset for the next tab
		tabOffset = currentRect.origin.x + currentRect.size.width + kTabSapcing;
		
	}	
	
}

-(int) tabIndexAtLocation:(CGPoint)point
{
	
	int tabIndex = -1;
	
	int tabOffset = 20;
	
	for (int tabIdx = 0; tabIdx < self.tabs.count; tabIdx++) {
		NSString* tabText = [self.tabs objectAtIndex:tabIdx];
		
		// construct the rect for this tab
		// measure the string
		CGSize textSize = [tabText sizeWithFont:_tabFont];
		CGRect currentRect = CGRectMake(tabOffset, 0, textSize.width + kTabTextPadding * 2, self.frame.size.height);
		
		if (CGRectContainsPoint(currentRect, point)) {
			tabIndex = tabIdx;
			break;
		}
		
		tabOffset = currentRect.origin.x + currentRect.size.width + kTabSapcing;
	}
	
	return tabIndex;
	
}

-(void) touchUpOutside:(id)sender forEvent:(UIEvent *)event
{
	_pressedTab = -1;
	[self setNeedsDisplay];
}

-(void) touchDown:(id)sender forEvent:(UIEvent *)event
{
	NSSet* touches = [event touchesForView:self];
	
	UITouch* touch = [touches anyObject];
	
	// hit test that touch
	CGPoint touchLocation = [touch locationInView:self];
	
	_pressedTab = [self tabIndexAtLocation:touchLocation];
	[self setNeedsDisplay];
}


-(void) touchUpInside:(id)sender forEvent:(UIEvent *)event
{
	if(sender != self)
		return;
	
	_pressedTab = -1;
	
	NSSet* touches = [event touchesForView:self];
	
	UITouch* touch = [touches anyObject];
	
	// hit test that touch
	CGPoint touchLocation = [touch locationInView:self];
	
	int tabIndex = [self tabIndexAtLocation:touchLocation];
	
	if (tabIndex >= 0) {
		self.selectedTab = tabIndex;
	}
	
	[self setNeedsDisplay];
	
}

-(int) addTab:(NSString*) tabName
{
	if(nil == self.tabs)
	{
		self.tabs = [NSArray arrayWithObject:tabName];
	}
	else {
		NSMutableArray* tabs = [NSMutableArray arrayWithArray:self.tabs];
		[tabs addObject:tabName];
		self.tabs = [NSArray arrayWithArray:tabs];
	}
	
	return self.tabs.count - 1;
	
}

-(void) setSelectedTab:(int) selectedTab
{
	int oldSelectedTab = _selectedTab;
	
	_selectedTab = selectedTab;
	
	if (oldSelectedTab != _selectedTab) {
		[self.delegate tabControl:self changedToIndex:_selectedTab tabText:[self.tabs objectAtIndex:_selectedTab]];
	}
	
	[self setNeedsDisplay];
}

- (void)dealloc {
	
	self.tabs = nil;
	[_tabFont release];
	
    [super dealloc];
}


@end
