#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "MapModule.h"
#import "MapSettingsViewController.h"
#import "KGOBookmarksViewController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOMapCategory.h"
#import "CoreDataManager.h"
#import "MapKit+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOToolbar.h"
#import "KGOPlacemark.h"
#import <QuartzCore/QuartzCore.h>

@implementation MapHomeViewController

@synthesize searchTerms, searchOnLoad, searchParams;

- (void)mapTypeDidChange:(NSNotification *)aNotification {
    _mapView.mapType = [[aNotification object] integerValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_mapBorder) {
        _mapBorder.layer.cornerRadius = 4;
    }
    
    KGOModule *mapModule = [KGO_SHARED_APP_DELEGATE() moduleForTag:MapTag];
    self.title = mapModule.shortName;

    _mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePreference];
    [_mapView centerAndZoomToDefaultRegion];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapTypeDidChange:) name:MapTypePreferenceChanged object:nil];

	// set up toolbar buttons
	indoorMode = NO;
	NSArray *items = nil;
	UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	if (indoorMode) {
		items = [NSArray arrayWithObjects:_infoButton, spacer, _browseButton, spacer, _bookmarksButton, spacer, _settingsButton, nil];
		_infoButton.image = nil;
	} else {
		items = [NSArray arrayWithObjects:_locateUserButton, spacer, _browseButton, spacer, _bookmarksButton, spacer, _settingsButton, nil];
		_locateUserButton.image = [UIImage imageWithPathName:@"modules/map/map_button_location"];
	}

	_bottomBar.items = items;
	
	_browseButton.image = [UIImage imageWithPathName:@"modules/map/map_button_browse"];
	_bookmarksButton.image = [UIImage imageWithPathName:@"modules/map/map_button_bookmark"];
	_settingsButton.image = [UIImage imageWithPathName:@"modules/map/map_button_settings"];

    // set up search bar
    _searchBar.placeholder = NSLocalizedString(@"Map Search Placeholder", nil);
	_searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
    if (self.searchTerms) {
        _searchBar.text = self.searchTerms;
    }
    if (self.searchOnLoad) {
        [_searchController executeSearch:self.searchTerms params:self.searchParams];
    }
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[_searchController release];
    [super dealloc];
}

- (NSArray *)annotations {
    return _mapView.annotations;
}

- (void)setAnnotations:(NSArray *)annotations {
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView addAnnotations:annotations];
}

#pragma mark -

- (IBAction)infoButtonPressed {
	
}

- (IBAction)locateUserButtonPressed {
	
}

- (IBAction)browseButtonPressed {
	KGOCategoryListViewController *categoryVC = [[[KGOCategoryListViewController alloc] init] autorelease];
    categoryVC.categoryEntityName = MapCategoryEntityName;
    categoryVC.categoriesRequest = [[KGORequestManager sharedManager] requestWithDelegate:categoryVC module:MapTag path:@"categories" params:nil];
    categoryVC.categoriesRequest.expectedResponseType = [NSArray class];
    
    __block JSONObjectHandler createMapCategories;
    __block NSUInteger sortOrder = 0;
    createMapCategories = [[^(id jsonObj) {
        NSInteger categoriesCreated = 0;
        NSArray *jsonArray = (NSArray *)jsonObj;
        for (id categoryObj in jsonArray) {
            if ([categoryObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *categoryDict = (NSDictionary *)categoryObj;
                NSArray *categoryPath = nil;
                id identifier = [categoryDict objectForKey:@"id"];
                if ([identifier isKindOfClass:[NSArray class]]) {
                    categoryPath = identifier;
                } else if ([identifier isKindOfClass:[NSNumber class]] || [identifier isKindOfClass:[NSString class]]) {
                    categoryPath = [NSArray arrayWithObject:identifier];
                }
                if (categoryPath) {
                    KGOMapCategory *category = [KGOMapCategory categoryWithPath:categoryPath];
                    NSString *title = [categoryDict stringForKey:@"title" nilIfEmpty:YES];
                    if (title && ![category.title isEqualToString:title]) {
                        category.title = title;
                        category.sortOrder = [NSNumber numberWithInt:sortOrder];
                        sortOrder++; // this can be anything so long as it's ascending within the parent category
                    }
                    categoriesCreated++;
                }

                NSArray *subcategories = [categoryDict arrayForKey:@"subcategories"];
                if (subcategories.count) {
                    categoriesCreated += createMapCategories(subcategories);
                }
            }
        }
        
        return categoriesCreated;
    } copy] autorelease];
    
    categoryVC.categoriesRequest.handler = createMapCategories;
	[KGO_SHARED_APP_DELEGATE() presentAppModalNavigationController:categoryVC animated:YES];
}

- (IBAction)bookmarksButtonPressed {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"bookmarked = YES"];
    NSArray *array = [[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName matchingPredicate:pred];
    KGOBookmarksViewController *vc = [[[KGOBookmarksViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    vc.bookmarkedItems = array;
    vc.searchDisplayDelegate = self;
    [KGO_SHARED_APP_DELEGATE() presentAppModalNavigationController:vc animated:YES];
}

- (IBAction)settingsButtonPressed {
	MapSettingsViewController *vc = [[[MapSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    vc.title = @"Settings";
    vc.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
	[KGO_SHARED_APP_DELEGATE() presentAppModalNavigationController:vc animated:YES];
}

#pragma mark Map/List

- (void)showMapListToggle {
	if (!_mapListToggle) {
		_mapListToggle = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Map", @"List", nil]];
		_mapListToggle.tintColor = _searchBar.tintColor;
		_mapListToggle.segmentedControlStyle = UISegmentedControlStyleBar;
		[_mapListToggle setEnabled:NO forSegmentAtIndex:0];
		[_mapListToggle addTarget:self action:@selector(mapListSelectionChanged:) forControlEvents:UIControlEventValueChanged];
	}
	
	if (!_searchBar.toolbarItems.count) {
		UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithCustomView:_mapListToggle] autorelease];
		UIFont *smallFont = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
		item.width = [@"Map" sizeWithFont:smallFont].width + [@"List" sizeWithFont:smallFont].width + 4 * 4.0; // 4.0 is spacing defined in KGOSearchBar.m
		[_searchBar addToolbarButton:item animated:NO];
	}
}

- (void)hideMapListToggle {
	if (_searchBar.toolbarItems.count) {
		[_searchBar setToolbarItems:nil];
	}
	
	[_mapListToggle release];
	_mapListToggle = nil;
}

- (void)mapListSelectionChanged:(id)sender {
	if (sender == _mapListToggle) {
		switch (_mapListToggle.selectedSegmentIndex) {
			case 0:
				[self switchToMapView];
				break;
			case 1:
				[self switchToListView];
				break;
			default:
				break;
		}
	}
}

- (void)switchToMapView {
	[self.view bringSubviewToFront:_mapView];
	[self.view bringSubviewToFront:_bottomBar];
	
    // TODO: fine-tune when to enable this, e.g under proximity and gps enabled conditions
    [_locateUserButton setEnabled:YES];

	[_mapListToggle setEnabled:NO forSegmentAtIndex:0];
	[_mapListToggle setEnabled:YES forSegmentAtIndex:1];
}

- (void)switchToListView {
	if (_searchResultsTableView) {
		[self.view bringSubviewToFront:_searchResultsTableView];
	}
    
    [_locateUserButton setEnabled:NO];
	
	[_mapListToggle setEnabled:YES forSegmentAtIndex:0];
	[_mapListToggle setEnabled:NO forSegmentAtIndex:1];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *view = nil;
    if (![annotation isKindOfClass:[MKUserLocation class]]) {
        static NSString *AnnotationIdentifier = @"adfgweg";
        view = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
        if (!view) {
            view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier] autorelease];
            view.canShowCallout = YES;
            view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
    }
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKAnnotation> annotation = view.annotation;
    if ([annotation conformsToProtocol:@protocol(KGOSearchResult)]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotation, @"place", self, @"pagerController", nil];
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        [appDelegate showPage:LocalPathPageNameDetail forModuleTag:MapTag params:params];
    }
}

#pragma mark KGODetailPagerController

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.annotations objectAtIndex:indexPath.row];
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section
{
    return self.annotations.count;
}

#pragma mark SearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
	return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
	return [NSArray arrayWithObject:MapTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
	return MapTag;
}

- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {
    // TODO: this is depending on the incorrect use of KGOSearchDisplayDelegate
    // in KGOBookmarksViewController and needs to be fixed when that is fixed.
    if (controller) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"place", controller, @"pagerController", nil];
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        [appDelegate showPage:LocalPathPageNameDetail forModuleTag:MapTag params:params];

    } else if ([aResult conformsToProtocol:@protocol(MKAnnotation)]) {
        id<MKAnnotation> annotation = (id<MKAnnotation>)aResult;
        [_mapView addAnnotation:annotation];
    }
}

- (BOOL)searchControllerShouldLinkToMap:(KGOSearchDisplayController *)controller {
	[self showMapListToggle]; // override default behavior
	return NO; // notify the controller that it's been overridden
}

- (void)searchController:(KGOSearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {

	// show our map view above the list view
	if (controller.showingOnlySearchResults) {
		[self switchToMapView];
	}
	
	for (id<KGOSearchResult> aResult in controller.searchResults) {
		if ([aResult conformsToProtocol:@protocol(MKAnnotation)]) {
			id<MKAnnotation> annotation = (id<MKAnnotation>)aResult;
			[_mapView addAnnotation:annotation];
		}
	}
    
    _mapView.region = [MapHomeViewController regionForAnnotations:_mapView.annotations restrictedToClass:[KGOPlacemark class]];
	
	_searchResultsTableView = tableView;
}


- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
	for (id<KGOSearchResult> aResult in controller.searchResults) {
		if ([aResult conformsToProtocol:@protocol(MKAnnotation)]) {
			id<MKAnnotation> annotation = (id<MKAnnotation>)aResult;
			[_mapView removeAnnotation:annotation];
		}
	}
	
	if (!_mapView.annotations.count) {
		[self hideMapListToggle];
	}

	_searchResultsTableView = nil;
}

// this is about 1km at the equator
#define MINIMUM_COORDINATE_DELTA 0.01

+ (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations restrictedToClass:(Class)restriction
{
    double minLat = 90;
    double maxLat = -90;
    double minLon = 180;
    double maxLon = -180;

    for (id<MKAnnotation> annotation in annotations) {
        if (!restriction || [annotation isKindOfClass:restriction]) {
            CLLocationCoordinate2D coord = annotation.coordinate;
            if (coord.latitude > maxLat)  maxLat = coord.latitude;
            if (coord.longitude > maxLon) maxLon = coord.longitude;
            if (coord.latitude < minLat)  minLat = coord.latitude;
            if (coord.longitude < minLon) minLon = coord.longitude;
        }
    }
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(0, 0);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 0);
    
    if (maxLat >= minLat && maxLon >= minLon) {
        center.latitude = (minLat + maxLat) / 2;
        center.longitude = (minLon + maxLon) / 2;
        
        span.latitudeDelta = fmax((maxLat - minLat) * 1.4, MINIMUM_COORDINATE_DELTA);
        span.longitudeDelta = fmax((maxLon - minLon) * 1.4, MINIMUM_COORDINATE_DELTA);
    }
    
    return MKCoordinateRegionMake(center, span);
}

@end
