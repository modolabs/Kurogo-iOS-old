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
#import "KGOSidebarFrameViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation MapHomeViewController

@synthesize searchTerms, searchOnLoad, searchParams, mapModule;

- (void)mapTypeDidChange:(NSNotification *)aNotification {
    _mapView.mapType = [[aNotification object] integerValue];
}

- (void)setupToolbarButtons {
    _infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_infoButton setImage:[UIImage imageWithPathName:@"modules/map/map-button-info"] forState:UIControlStateNormal];
    
    _locateUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_locateUserButton setImage:[UIImage imageWithPathName:@"modules/map/map-button-location"] forState:UIControlStateNormal];

    _browseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_browseButton setImage:[UIImage imageWithPathName:@"modules/map/map-button-browse"] forState:UIControlStateNormal];
    
    _bookmarksButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_bookmarksButton setImage:[UIImage imageWithPathName:@"modules/map/map-button-favorites"] forState:UIControlStateNormal];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_settingsButton setImage:[UIImage imageWithPathName:@"modules/map/map-button-settings"] forState:UIControlStateNormal];
        
    UIImage *normalImage = [UIImage imageWithPathName:@"common/secondary-toolbar-button"];
    UIImage *pressedImage = [UIImage imageWithPathName:@"common/secondary-toolbar-button-pressed"];
    CGRect frame = CGRectZero;
    if (normalImage) {
        frame.size = normalImage.size;
    } else {
        frame.size = CGSizeMake(42, 31);
    }

    NSArray *buttons = [NSArray arrayWithObjects:_infoButton, _locateUserButton, _browseButton, _bookmarksButton, _settingsButton, nil];
    for (UIButton *aButton in buttons) {
        aButton.frame = frame;
        [aButton setBackgroundImage:normalImage forState:UIControlStateNormal];
        [aButton setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
        [aButton addTarget:self action:@selector(toolbarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
	indoorMode = NO;
	NSArray *items = nil;
	UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	if (indoorMode) {
		items = [NSArray arrayWithObjects:
                 [[[UIBarButtonItem alloc] initWithCustomView:_infoButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_browseButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_bookmarksButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_settingsButton] autorelease],
                 nil];
	} else {
		items = [NSArray arrayWithObjects:
                 [[[UIBarButtonItem alloc] initWithCustomView:_locateUserButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_browseButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_bookmarksButton] autorelease], spacer,
                 [[[UIBarButtonItem alloc] initWithCustomView:_settingsButton] autorelease],
                 nil];
	}
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        _locateUserButton.enabled = NO;
    }
    
	_bottomBar.items = items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_mapBorder) {
        _mapBorder.layer.cornerRadius = 4;
    }
    
    self.title = self.mapModule.shortName;

    _mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePreference];
    [_mapView centerAndZoomToDefaultRegion];
    if (self.annotations.count) { // these would have been set before _mapView was set up
        [_mapView addAnnotations:self.annotations];
        _mapView.region = [MapHomeViewController regionForAnnotations:self.annotations restrictedToClass:NULL];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapTypeDidChange:) name:MapTypePreferenceChanged object:nil];

    [self setupToolbarButtons];
    if (_toolbarDropShadow) {
        UIImage *image = [[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow];
        if (image) {
            _toolbarDropShadow.image = image;
        }
    }

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
    [_toolbarDropShadow release];
    _toolbarDropShadow = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    _mapView.delegate = nil;
    [_annotations release];
	[_searchController release];
    [_toolbarDropShadow release];
    [super dealloc];
}

- (NSArray *)annotations {
    return _annotations;
}

- (void)setAnnotations:(NSArray *)annotations {
    [_annotations release];
    _annotations = [annotations retain];

    if (_mapView) {
        [_mapView removeAnnotations:_mapView.annotations];
        if (_annotations) {
            [_mapView addAnnotations:_annotations];
        }
    }
}

#pragma mark -

- (void)toolbarButtonPressed:(id)sender
{
    if (sender == _infoButton) {
        [self infoButtonPressed];
    } else if (sender == _locateUserButton) {
        [self locateUserButtonPressed];
    } else if (sender == _browseButton) {
        [self browseButtonPressed];
    } else if (sender == _bookmarksButton) {
        [self bookmarksButtonPressed];
    } else if (sender == _settingsButton) {
        [self settingsButtonPressed];
    }
}

- (IBAction)infoButtonPressed {
	
}

- (IBAction)browseButtonPressed {
	KGOCategoryListViewController *categoryVC = [[[KGOCategoryListViewController alloc] init] autorelease];
    categoryVC.categoryEntityName = MapCategoryEntityName;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"parentCategory = nil"];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]];
    categoryVC.categories = [[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName matchingPredicate:pred sortDescriptors:sortDescriptors];
    categoryVC.categoriesRequest = [self.mapModule subcategoriesRequestForCategory:nil delegate:categoryVC];
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:categoryVC] autorelease];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    categoryVC.navigationItem.rightBarButtonItem = item;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    navC.navigationBar.barStyle = [[KGOTheme sharedTheme] defaultNavBarStyle];
    [self presentModalViewController:navC animated:YES];
}

- (IBAction)bookmarksButtonPressed {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"bookmarked = YES"];
    NSArray *array = [[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName matchingPredicate:pred];
    KGOBookmarksViewController *vc = [[[KGOBookmarksViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    vc.bookmarkedItems = array;
    vc.searchResultsDelegate = self;

    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    vc.navigationItem.rightBarButtonItem = item;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    navC.navigationBar.barStyle = [[KGOTheme sharedTheme] defaultNavBarStyle];
    [self presentModalViewController:navC animated:YES];
}

- (IBAction)settingsButtonPressed {
	MapSettingsViewController *vc = [[[MapSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    vc.title = @"Settings";
    vc.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];

    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    vc.navigationItem.rightBarButtonItem = item;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    navC.navigationBar.barStyle = [[KGOTheme sharedTheme] defaultNavBarStyle];
    [self presentModalViewController:navC animated:YES];
}

- (IBAction)locateUserButtonPressed
{
    _didCenter = NO;
    
    if (!_userLocation) {
        if (!_locationManager) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.distanceFilter = kCLDistanceFilterNone;
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            _locationManager.delegate = self;
        }
        _userLocation = [_locationManager location];
    }
    
    if (_userLocation) {
        [self showUserLocationIfInRange];
        
    } else {
        [_locationManager startUpdatingLocation];
    }
}

#pragma mark User location

- (void)showUserLocationIfInRange
{
    if (_didCenter) {
        return;
    }
    
    CLLocation *location;
    NSDictionary *locationPreferences = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Location"];
    if (!locationPreferences) {    
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        locationPreferences = [[appDelegate appConfig] dictionaryForKey:@"Location"];
    }
    
    NSString *latLonString = [locationPreferences stringForKey:@"DefaultCenter" nilIfEmpty:YES];
    if (latLonString) {
        NSArray *parts = [latLonString componentsSeparatedByString:@","];
        if (parts.count == 2) {
            NSString *lat = [parts objectAtIndex:0];
            NSString *lon = [parts objectAtIndex:1];
            location = [[CLLocation alloc] initWithLatitude:[lat floatValue] longitude:[lon floatValue]];
        }
    }

    DLog(@"%@ %@", location, _userLocation);
    // TODO: make maximum distance a config parameter
    if ([_userLocation distanceFromLocation:location] <= 4000) {
        _mapView.showsUserLocation = YES;
        _mapView.centerCoordinate = _userLocation.coordinate;
        _didCenter = YES;
    } else {
        DLog(@"distance %.1f is out of bounds", [_userLocation distanceFromLocation:location]);
        _locateUserButton.enabled = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        _locateUserButton.enabled = NO;
        _mapView.showsUserLocation = NO;
    } else {
        _locateUserButton.enabled = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"location update failed: %@", [error description]);
    if ([error code] == kCLErrorDenied) {
        [_locationManager stopUpdatingLocation];
        _locateUserButton.enabled = NO;
        _mapView.showsUserLocation = NO;
    }    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [_userLocation release];
    _userLocation = [newLocation retain];
    
    [self showUserLocationIfInRange];
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
    if ([annotation isKindOfClass:[KGOPlacemark class]]) {
        static NSString *AnnotationIdentifier = @"adfgweg";
        view = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
        if (!view) {
            view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier] autorelease];
            view.canShowCallout = YES;
            view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
    } else if ([annotation conformsToProtocol:@protocol(KGOSearchResult)]) {
        id<KGOSearchResult> aResult = (id<KGOSearchResult>)annotation;
        if ([aResult respondsToSelector:@selector(annotationImage)]) {
            UIImage *image = [aResult annotationImage];
            if (image) {
                view = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"fajwioth"] autorelease];
                view.image = image;
                view.canShowCallout = YES;
                // TODO: not all annotations will want to do this
                view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            }
        }
    }
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKAnnotation> annotation = view.annotation;
    if ([annotation conformsToProtocol:@protocol(KGOSearchResult)]) {
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotation, @"place", self, @"pagerController", nil];
        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        // TODO: clean up sidebar home screen so we don't have to deal with this
        if (navStyle == KGONavigationStyleTabletSidebar) {
            UIViewController *vc = [self.mapModule modulePage:LocalPathPageNameDetail params:params];
            [(KGOSidebarFrameViewController *)[appDelegate homescreen] showDetailViewController:vc];
            
        } else {
            [appDelegate showPage:LocalPathPageNameDetail forModuleTag:self.mapModule.tag params:params];
        }
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
    return [KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
	return [NSArray arrayWithObject:MapTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
	return MapTag;
}

- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder didSelectResult:(id<KGOSearchResult>)aResult {
    if ([resultsHolder isKindOfClass:[KGOSearchDisplayController class]]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"place", resultsHolder, @"pagerController", nil];
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        [appDelegate showPage:LocalPathPageNameDetail forModuleTag:MapTag params:params];

    } else if ([aResult conformsToProtocol:@protocol(MKAnnotation)]) { // TODO: check if search is bookmarks, not by the result selected
        [_mapView removeAnnotations:[_mapView annotations]];
        id<MKAnnotation> annotation = (id<MKAnnotation>)aResult;
        [_mapView addAnnotation:annotation];
    }
}

- (BOOL)searchControllerShouldLinkToMap:(KGOSearchDisplayController *)controller {
	[self showMapListToggle]; // override default behavior
	return NO; // notify the controller that it's been overridden
}

- (void)searchController:(KGOSearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
        tableView.hidden = YES;
    }

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
    
    if (_mapView.annotations.count) {
        _mapView.region = [MapHomeViewController regionForAnnotations:_mapView.annotations restrictedToClass:[KGOPlacemark class]];
    }
	
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
