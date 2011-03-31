#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"

@implementation MapDetailViewController

@synthesize placemark, pager;

#pragma mark TabbedViewDelegate

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    UIView *view = nil;
    NSString *title = [control titleForTabAtIndex:index];
    if ([title isEqualToString:@"Photo"]) {

    
    } else if ([title isEqualToString:@"Details"]) {
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(10, 10, self.tabViewContainer.frame.size.width - 20, self.tabViewContainer.frame.size.height - 20)] autorelease];
        [webView loadHTMLString:self.placemark.info baseURL:nil];
        webView.delegate = self;
        view = webView;
    }
    return view;
}

- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control {
    NSMutableArray *tabs = [NSMutableArray array];
    [tabs addObject:NSLocalizedString(@"Photo", nil)];
    if (self.placemark.info) {
        [tabs addObject:NSLocalizedString(@"Details", nil)];
    }
    return tabs;
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent {
    NSLog(@"%@", [self.placemark description]);

    self.tabViewHeader.detailItem = self.placemark;
    //[self.tabViewHeader inflateSubviews];
    [self reloadTabContent];
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.placemark = (KGOPlacemark *)content;
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

    self.tabViewHeader.showsBookmarkButton = YES;
    [self loadAnnotationContent];
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
