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
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(10, 10, self.tabViewContainer.frame.size.width - 20, self.tabViewContainer.frame.size.height - 20)] autorelease];
        [webView loadHTMLString:self.placemark.info baseURL:nil];
        if ([webView respondsToSelector: @selector(scrollView)]) {
            // iOS 5
            webView.scrollView.bounces = NO;
            webView.scrollView.decelerationRate = 0;
        } else {
            // Icky hack for pre-iOS 5
            UIScrollView *subview = nil;
            for(UIView *view in webView.subviews) {
                if([view isKindOfClass:[UIScrollView class]]) {
                    subview = (UIScrollView *)view;
                    subview.bounces = NO;
                    subview.decelerationRate = 0;
                }
            }
        }
        webView.delegate = self;
        view = webView;
        
    } else if (index == _nearbyTabIndex) {
        if (!_tableView) {
            CGRect frame = CGRectMake(0, 0, self.tabViewContainer.frame.size.width, self.tabViewContainer.frame.size.height);
            _tableView = [[[KGOSearchResultListTableView alloc] initWithFrame:frame] autorelease];
            _tableView.resultsDelegate = self;
            
            self.dataManager.searchDelegate = _tableView;
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
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                aResult, @"place", 
                                resultsHolder, @"pagerController", 
                                [_tableView indexPathForSelectedRow], @"currentIndexPath",
                                nil];
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        [appDelegate showPage:LocalPathPageNameDetail forModuleTag:self.mapModule.tag params:params];
    }
}

#pragma mark -

- (void)dealloc
{
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
