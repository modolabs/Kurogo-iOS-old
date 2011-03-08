#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"

@implementation MapDetailViewController

@synthesize placemark, pager;

#pragma mark TabbedViewDelegate

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    UIView *view = nil;
    switch (index) {
        case 0: {
            break;
        }
        case 1: {
            break;
        }
        default:
            break;
    }
    return view;
}

- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control {
    return [NSArray arrayWithObjects:@"Photo", @"Details", nil];
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent {
    NSLog(@"%@", [self.placemark description]);
    
    _titleLabel.text = self.placemark.title;
    [self reloadTabContent];
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.placemark = content;
        [self loadAnnotationContent];
    }
}

#pragma mark -

- (void)dealloc
{
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
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForContentTitle];
    CGFloat width = self.view.frame.size.width - 80;
    _titleLabel = [UILabel multilineLabelWithText:self.placemark.title font:titleFont width:width];
    
    [self.tabViewHeader addSubview:_titleLabel];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
