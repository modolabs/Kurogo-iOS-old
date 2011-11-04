#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"
#import "KGOSearchResultListTableView.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "MapModule.h"

@implementation MapDetailViewController

@synthesize placemark, pager, dataManager, mapModule;

#pragma mark TabbedViewDelegate

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    UIView *view = nil;
    if (index == _photoTabIndex) {
        // TODO
        
    } else if (index == _detailsTabIndex) {
        if (!_webView) {
            CGRect frame = CGRectMake(10, 10,
                                      CGRectGetWidth(self.tabViewContainer.frame) - 20,
                                      CGRectGetHeight(self.tabViewContainer.frame) - 20);
            _webView = [[UIWebView alloc] initWithFrame:frame];
            _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            if ([_webView respondsToSelector: @selector(scrollView)]) {
                // iOS 5
                [[_webView scrollView] setBounces:NO];
                [[_webView scrollView] setDecelerationRate:0];
            } else {
                // Icky hack for pre-iOS 5
                UIScrollView *subview = nil;
                for(UIView *view in _webView.subviews) {
                    if([view isKindOfClass:[UIScrollView class]]) {
                        subview = (UIScrollView *)view;
                        subview.bounces = NO;
                        subview.decelerationRate = 0;
                    }
                }
            }
        }
        
        NSString *body = self.placemark.info ? self.placemark.info : @"";
        [_webView loadTemplate:[KGOHTMLTemplate templateWithPathName:@"modules/map/map_detail_template.html"] 
                        values:[NSDictionary dictionaryWithObjectsAndKeys: body, @"BODY", nil]];
        
        _webView.delegate = self;
        view = _webView;
        
    } else if (index == _nearbyTabIndex) {
        if (!_tableView) {
            CGRect frame = CGRectMake(0, 0, self.tabViewContainer.frame.size.width, self.tabViewContainer.frame.size.height);
            _tableView = [[KGOSearchResultListTableView alloc] initWithFrame:frame];
            _tableView.resultsDelegate = self;
            
            self.dataManager.searchDelegate = self;
            [self.dataManager searchNearby:self.placemark.coordinate];
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
    
    // TODO: add detail tab for placemarks with itemized fields
    [tabs addObject:NSLocalizedString(@"Details", nil)];
    _detailsTabIndex = currentTabIndex;
    currentTabIndex++;
    
    [tabs addObject:NSLocalizedString(@"Nearby", nil)];
    _nearbyTabIndex = currentTabIndex;
    
    return tabs;
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent {
    DLog(@"%@", [self.placemark description]);
    if (!self.placemark.info) {
        self.dataManager.delegate = self;
        [self.dataManager requestDetailsForPlacemark:self.placemark];
    }

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

#pragma mark MapDataManager

- (void)mapDataManager:(MapDataManager *)dataManager didUpdatePlacemark:(KGOPlacemark *)placemark
{
    [self reloadTabs];
    if ([self.tabs selectedTabIndex] == _detailsTabIndex) {
        [self reloadTabContent];
    }
}

#pragma mark KGOSearchResultsDelegate

- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder didSelectResult:(id<KGOSearchResult>)aResult
{
    if ([resultsHolder isKindOfClass:[KGOSearchResultListTableView class]]) {
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();

        // TODO: decide if we prefer to open nearby locations in the map (active)
        // or in another detail page (commented)

        /*
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                aResult, @"place", 
                                resultsHolder, @"pagerController", 
                                [_tableView indexPathForSelectedRow], @"currentIndexPath",
                                nil];
        [appDelegate showPage:LocalPathPageNameDetail forModuleTag:self.mapModule.tag params:params];
        */
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:aResult]
                                                           forKey:@"annotations"];
        [appDelegate showPage:LocalPathPageNameHome forModuleTag:self.mapModule.tag params:params];
    }
}

- (NSArray *)results
{
    return  _tableView.items;
}

-(void)receivedSearchResults:(NSArray *)searchResults forSource:(NSString *)source {
    _tableView.items = searchResults;
    NSArray *filteredArray = [searchResults filteredArrayUsingPredicate:
                              [NSPredicate predicateWithFormat:@"identifier != %@", self.placemark.identifier]];
    _tableView.items = filteredArray;
    [_tableView reloadData];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL result = YES;
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
        
        if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        }
    }
    return result;
}

#pragma mark -

- (void)dealloc
{
    self.dataManager.searchDelegate = nil;
    self.dataManager = nil;
    self.placemark = nil;
    self.pager = nil;
    self.mapModule = nil;
    _tableView.resultsDelegate = nil;
    [_tableView release];
    _webView.delegate = nil;
    [_webView release];
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
    
    // TODO: this is redundant - which string do we want?
    self.title = NSLocalizedString(@"Info", @"map detail page title");
    self.navigationItem.title = NSLocalizedString(@"Location Info", nil);
    
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
