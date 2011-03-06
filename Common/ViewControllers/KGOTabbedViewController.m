#import "KGOTabbedViewController.h"

@implementation KGOTabbedViewController

//@synthesize tabs = _tabs;
@synthesize delegate;

- (void)setTabViewHeader:(UIView *)tabViewHeader {
    if (_tabViewHeader) {
        [_tabViewHeader removeFromSuperview];
        [_tabViewHeader release];
    }
    _tabViewHeader = [tabViewHeader retain];
    [self.view addSubview:_tabViewHeader];
}

- (UIView *)tabViewHeader {
    return _tabViewHeader;
}

- (void)tabbedControl:(KGOTabbedControl *)control didSwitchToTabAtIndex:(NSInteger)index {
    UIView *newView = [self.delegate tabbedControl:control containerViewAtIndex:index];
    if (newView) {
        for (UIView *oldView in _tabViewContainer.subviews) {
            [oldView removeFromSuperview];
        }
        [_tabViewContainer addSubview:newView];
    }
}

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    return nil;
}

- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control {
    return nil;
}

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    //self.tabs = nil;
    self.tabViewHeader = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%@", [_tabs description]);
    
    for (id item in [self.delegate itemsForTabbedControl:_tabs]) {
        if ([item isKindOfClass:[NSString class]]) {
            [_tabs insertTabWithTitle:item atIndex:_tabs.numberOfTabs animated:NO];
        } else {
            [_tabs insertTabWithImage:item atIndex:_tabs.numberOfTabs animated:NO];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
