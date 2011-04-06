#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"
#import "KGOSearchResultListTableView.h"
#import "KGORequestManager.h"

@implementation MapDetailViewController

@synthesize placemark, pager;

#pragma mark TabbedViewDelegate

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    UIView *view = nil;
    if (index == _photoTabIndex) {

    
    } else if (index == _detailsTabIndex) {
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(10, 10, self.tabViewContainer.frame.size.width - 20, self.tabViewContainer.frame.size.height - 20)] autorelease];
        [webView loadHTMLString:self.placemark.info baseURL:nil];
        webView.delegate = self;
        view = webView;
        
    } else if (index == _nearbyTabIndex) {
        if (!_tableView) {
            CGRect frame = CGRectMake(0, 0, self.tabViewContainer.frame.size.width, self.tabViewContainer.frame.size.height);
            _tableView = [[[KGOSearchResultListTableView alloc] initWithFrame:frame] autorelease];
            
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"nearby", @"type",
                                    [NSString stringWithFormat:@"%.5f", self.placemark.coordinate.latitude], @"lat",
                                    [NSString stringWithFormat:@"%.5f", self.placemark.coordinate.longitude], @"lon",
                                    nil];
            _request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:MapTag
                                                                         path:@"search"
                                                                       params:params];
            _request.expectedResponseType = [NSDictionary class];
            if (_request)
                [_request connect];
        }
        
        view = _tableView;
    }
    return view;
}

- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control {
    NSMutableArray *tabs = [NSMutableArray array];
    _photoTabIndex = NSNotFound;
    _nearbyTabIndex = NSNotFound;
    _detailsTabIndex = NSNotFound;
    
    NSInteger currentTabIndex = 0;
    if (self.placemark.photoURL) {
        [tabs addObject:NSLocalizedString(@"Photo", nil)];
        _photoTabIndex = currentTabIndex;
        currentTabIndex++;
    }
    if (self.placemark.info) {
        [tabs addObject:NSLocalizedString(@"Details", nil)];
        _detailsTabIndex = currentTabIndex;
        currentTabIndex++;
    }
    [tabs addObject:NSLocalizedString(@"Nearby", nil)];
    _nearbyTabIndex = currentTabIndex;
    return tabs;
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent {
    NSLog(@"%@", [self.placemark description]);

    self.tabViewHeader.detailItem = self.placemark;
    
    [_tableView release];
    _tableView = nil;

    [self reloadTabContent];
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.placemark = (KGOPlacemark *)content;
        [self loadAnnotationContent];
    }
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    _request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    _request = nil;
    
    NSArray *resultArray = [result arrayForKey:@"results"];
    NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
    for (id aResult in resultArray) {
        KGOPlacemark *aPlacemark = [KGOPlacemark placemarkWithDictionary:aResult];
        if (aPlacemark)
            [searchResults addObject:aPlacemark];
    }
    NSLog(@"%@", searchResults);
    [_tableView searcher:self didReceiveResults:searchResults];
}

#pragma mark -

- (void)dealloc
{
    [_request cancel];
    [_tableView release];
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
