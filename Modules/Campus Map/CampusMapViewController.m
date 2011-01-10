#import <QuartzCore/QuartzCore.h>
#import "CampusMapViewController.h"
#import "MapSearchResultAnnotation.h"
#import "MapSearchResultsTableView.h"
#import "MITMapDetailViewController.h"
#import "MITUIConstants.h"
#import "MapTileOverlayView.h"
#import "MapTileOverlay.h"
#import "MapSearch.h"
#import "CoreDataManager.h"
#import "TileServerManager.h"
#import "CampusMapToolbar.h"
#import "MITSearchDisplayController.h"

#import "MapSelectionController.h"

#define kAPISearch		@"Search"

#define kNoSearchResultsTag 31678
#define kErrorConnectingTag 31679

#define kPreviousSearchLimit 25

@interface CampusMapViewController(Private)

- (void)setupSearchController;
- (void)noSearchResultsAlert;
//- (void)errorConnectingAlert;
- (void)setUpAnnotationsWithNewSearchResults:(NSArray*)searchResults forQuery:(NSString *)searchQuery;
- (void)handleTileServerManagerProjectionIsReady:(NSNotification *)notification;
- (void)recenterMapView;
- (void)restoreToolBar;
- (void)hideToolBar;
- (CGFloat)searchBarWidth;
- (void)receivedNewSearchResults:(NSArray*)searchResults query:(NSString *)searchQuery type:(NSString *)searchType;
- (void)didSetSearchResults; // called after -setSearchResults and -handleTileServer... have both been called at least once

@end

@implementation CampusMapViewController
@synthesize geoButton = _geoButton;
@synthesize searchResults = _searchResults;
@synthesize mapView = _mapView;
@synthesize lastSearchText = _lastSearchText;
@synthesize hasSearchResults = _hasSearchResults;
@synthesize displayingList = _displayingList;
@synthesize searchBar = _searchBar;
@synthesize campusMapModule = _campusMapModule;
@synthesize searchResultsTableView = _searchResultsTableView;
@synthesize searchController = _searchController;


- (CGFloat)searchBarWidth {
    return floor(self.view.frame.size.width * 0.84);
}

- (void)loadView {
    [super loadView];
    
    CGFloat searchBarWidth = [self searchBarWidth];
	
	_viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStylePlain target:self action:@selector(viewTypeChanged:)];
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	// add a search bar to our view
	_searchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, searchBarWidth, NAVIGATION_BAR_HEIGHT)];
	_searchBar.delegate = self;
	_searchBar.placeholder = NSLocalizedString(@"Search Campus Map", nil);
	_searchBar.showsBookmarkButton = NO; // we'll be adding a custom bookmark button
	[self.view addSubview:_searchBar];
    
    // we depend on tileServerManager to set default map region
    // and tell us where to place map annotations
    if (![TileServerManager isInitialized]) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleTileServerManagerProjectionIsReady:) 
                                                     name:kTileServerManagerProjectionIsReady
                                                   object:nil];
    }

	// create the map view 
	_mapView = [[MKMapView alloc] initWithFrame: CGRectMake(0, _searchBar.frame.size.height, self.view.frame.size.width,
                                                            self.view.frame.size.height - _searchBar.frame.size.height)];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapView.mapType = MKMapTypeStandard;
	NSInteger mapTypePref = [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePrefKey];
	if (mapTypePref) {
		_mapView.mapType = mapTypePref;
	}
	_mapView.delegate = self;
    _mapView.region = [TileServerManager defaultRegion];
	_mapView.showsUserLocation = NO;
	_mapView.isAccessibilityElement = YES;
	_mapView.accessibilityLabel = @"Map View";
	[self.view addSubview:_mapView];
    [_searchBar addDropShadow];
	
	// add the rest of the toolbar to which we can add buttons.
	_toolBar = [[CampusMapToolbar alloc] initWithFrame:CGRectMake(searchBarWidth, 0, self.view.frame.size.width - searchBarWidth, NAVIGATION_BAR_HEIGHT)];
    _toolBar.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	_toolBar.translucent = NO;
	[self.view addSubview:_toolBar];
	
	// create toolbar button item for geolocation  
	UIImage* image = [UIImage imageNamed:@"maps/map_button_icon_locate.png"];
	_geoButton = [[UIBarButtonItem alloc] initWithImage:image
												  style:UIBarButtonItemStyleBordered
												 target:self
												 action:@selector(geoLocationTouched:)];
	_geoButton.width = image.size.width + 10;

	[_toolBar setItems:[NSArray arrayWithObjects:_geoButton, nil]];
	
	// add our own bookmark button item since we are not using the default
	// bookmark button of the UISearchBar
    // TODO: don't hard code this frame
	_bookmarkButton = [[UIButton alloc] initWithFrame:CGRectMake(231, 8, 32, 28)];
	[_bookmarkButton setImage:[UIImage imageNamed:@"global/searchfield_star.png"] forState:UIControlStateNormal];
	[self.view addSubview:_bookmarkButton];
	[_bookmarkButton addTarget:self action:@selector(bookmarkButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	
}

- (void)viewDidLoad {
	[super viewDidLoad];
    [self setupSearchController];
}

- (void)setupSearchController {
    if (!_searchController) {
        _searchController = [[MITSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _searchController.delegate = self;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	if (_displayingList) {
		self.navigationItem.rightBarButtonItem.title = @"Map";
        [self restoreToolBar];
	} else if (_hasSearchResults) {
        self.navigationItem.rightBarButtonItem.title = @"List";
	} else {
		self.navigationItem.rightBarButtonItem.title = @"Browse";
	}

	// Check to see if the user changed the desired map type.
	NSInteger mapTypePref = [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePrefKey];
	if (_mapView.mapType != mapTypePref) {
		_mapView.mapType = mapTypePref;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// if there is a bookmarks view controller hanging around, dismiss and release it. 
	if (nil != _selectionVC) {
		[_selectionVC dismissModalViewControllerAnimated:NO];
		[_selectionVC release];
		_selectionVC = nil;
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	_mapView.delegate = nil;
    _searchController.searchResultsTableView = nil;
	self.searchResultsTableView = nil;
    _searchController = nil;
    
	[_mapView release];
	[_toolBar release];
	[_geoButton release];
    
	[_searchResults release];
	_searchResults = nil;
	
	[_viewTypeButton release];
	[_searchBar release];
	
	[_bookmarkButton release];
	[_selectionVC release];
	[_cancelSearchButton release];
}

- (void)dealloc 
{
	_mapView.delegate = nil;
	self.searchResultsTableView = nil;
    
	[_mapView release];
	[_toolBar release];
	[_geoButton release];
    [_searchController release];
    
	[_searchResults release];
	_searchResults = nil;
	
	[_viewTypeButton release];
	[_searchBar release];
	
	[_bookmarkButton release];
	[_selectionVC release];
	[_cancelSearchButton release];
	[super dealloc];
}

// adds custom tiles to the map. not called by anything yet.
// may want to move this to a MKMapView category so other modules can use it.
- (void)addTileOverlay {
    MapTileOverlay *overlay = [[MapTileOverlay alloc] init];
    [_mapView addOverlay:overlay];
    [overlay release];
}

- (void)setSearchResultsWithoutRecentering:(NSArray*)searchResults
{
	_searchFilter = nil;
	
	// remove search results
	[_mapView removeAnnotations:_searchResults];
	[_mapView removeAnnotations:_filteredSearchResults];
	[_searchResults release];
	_searchResults = [searchResults retain];
	
	[_filteredSearchResults release];
	_filteredSearchResults = nil;
	
	// remove any remaining annotations
    [_mapView removeAnnotations:_mapView.annotations];
	
	if (nil != self.searchResultsTableView) {
		self.searchResultsTableView.searchResults = _searchResults;
	}
    
    if ([TileServerManager isInitialized]) {
        [_mapView addAnnotations:_searchResults];
    }
}

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations {

    MKCoordinateRegion region = [TileServerManager defaultRegion];
    
    double minLat = 90;
    double maxLat = -90;
    double minLon = 180;
    double maxLon = -180;
    
    // allow this function to handle MKAnnotationView
    // in addition to MKAnnotation objects by default
    BOOL isAnnotationView = NO;
    if ([annotations count]) {
        id object = [annotations objectAtIndex:0];
        if ([object isKindOfClass:[MKAnnotationView class]]) {
            isAnnotationView = YES;
        }
    }

    for (id object in annotations) {
        id<MKAnnotation> annotation = nil;
        if (isAnnotationView) {
            annotation = ((MKAnnotationView *)object).annotation;
        } else {
            annotation = (id<MKAnnotation>)object;
        }

        CLLocationCoordinate2D coordinate = annotation.coordinate;
        
        if (coordinate.latitude == 0 && coordinate.longitude == 0)
            continue;
        
        if (coordinate.latitude < minLat)
            minLat = coordinate.latitude;
        if (coordinate.latitude > maxLat)
            maxLat = coordinate.latitude;
        if (coordinate.longitude < minLon)
            minLon = coordinate.longitude;
        if (coordinate.longitude > maxLon)
            maxLon = coordinate.longitude;
    }
    
    if (maxLat != -90) {
        
        CLLocationCoordinate2D center;
        center.latitude = minLat + (maxLat - minLat) / 2;
        center.longitude = minLon + (maxLon - minLon) / 2;
        
        // create the span and region with a little padding
        double latDelta = maxLat - minLat;
        double lonDelta = maxLon - minLon;
        
        if (latDelta < 0.002) latDelta = 0.002;
        if (lonDelta < 0.002) lonDelta = 0.002;

        region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));        
    }
    
    return region;
}

- (void)setSearchResults:(NSArray *)searchResults
{
	[self setSearchResultsWithoutRecentering:searchResults];

	if (![_searchResults count]) {
        _hasSearchResults = NO;
    } else {
        _hasSearchResults = YES;
        
        if (_mapView.showsUserLocation) {
            _mapView.showsUserLocation = NO;
            _geoButton.style = UIBarButtonItemStyleBordered;
        }
        
        if ([TileServerManager isInitialized]) {
            [self didSetSearchResults];
        }
    }
}

- (void)didSetSearchResults {
    if (_searchResults.count == 1) {
        id<MKAnnotation> annotation = [_mapView.annotations lastObject];
        [_mapView selectAnnotation:annotation animated:YES];
        
    } else {
        _mapView.region = [self regionForAnnotations:_searchResults];
    }
}

- (void)setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter
{
	_searchFilter = filter;
	
	// if there was no filter, just add the annotations the normal way
	if(nil == filter) {
		[self setSearchResults:searchResults];
		return;
	}
	
	[_mapView removeAnnotations:_filteredSearchResults];
	[_mapView removeAnnotations:_searchResults];

	self.searchResults = searchResults;
	
	[_filteredSearchResults release];
	_filteredSearchResults = nil;
	
	
	// reformat the search results for the map. Combine items that are in common buildings into one annotation result.
	NSMutableDictionary* mapSearchResults = [NSMutableDictionary dictionaryWithCapacity:_searchResults.count];
	for (ArcGISMapAnnotation *annotation in _searchResults)
	{
		ArcGISMapAnnotation *previousAnnotation = [mapSearchResults objectForKey:[annotation performSelector:filter]];
		if (nil == previousAnnotation) {
			ArcGISMapAnnotation *newAnnotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:annotation.coordinate] autorelease];
			[mapSearchResults setObject:newAnnotation forKey:[annotation performSelector:filter]];
		}
	}
	
	_filteredSearchResults = [[mapSearchResults allValues] retain];
	
	[_mapView addAnnotations:_filteredSearchResults];	
}

#pragma mark CampusMapViewController(Private)

- (void)noSearchResultsAlert
{
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Results Found", nil)
													 message:NSLocalizedString(@"Your query returned no matches.", nil)
													delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
	alert.isAccessibilityElement = YES;
	alert.accessibilityLabel = @"No search results alert";
	alert.tag = kNoSearchResultsTag;
	alert.delegate = self;
	[alert show];
}
/*
- (void)errorConnectingAlert
{
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
													 message:NSLocalizedString(@"Please check your Internet connection and try again later.", nil)
													delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
	alert.tag = kErrorConnectingTag;
	alert.delegate = self;
	[alert show];
}
*/
- (void)handleTileServerManagerProjectionIsReady:(NSNotification *)notification {
    
    // TODO: don't do this if the user has intentially scrolled somewhere else
    _mapView.region = [TileServerManager defaultRegion];

    if (self.searchResults != nil) {
        for (ArcGISMapAnnotation *annotation in self.searchResults) {
            if (!annotation.coordinate.latitude)
                [annotation updateWithInfo:annotation.info]; // updateWithInfo acts differently when tile server is up
        }
        [_mapView addAnnotations:self.searchResults];
        [self didSetSearchResults];
    }
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
}

#pragma mark UIAlertViewDelegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// if the alert view was "no search results", give focus back to the search bar
	if (alertView.tag = kNoSearchResultsTag) {
        [_searchController setActive:YES animated:YES];
	}
}


#pragma mark User actions
-(void) geoLocationTouched:(id)sender
{
    _mapView.showsUserLocation = !_mapView.showsUserLocation;
    
    if (_mapView.showsUserLocation) {
        _geoButton.style = UIBarButtonItemStyleDone;
        
        if (CLLocationCoordinate2DIsValid(_lastUserLocation)
            && _mapView.userLocation.coordinate.latitude == _lastUserLocation.latitude
            && _mapView.userLocation.coordinate.longitude == _lastUserLocation.longitude)

        { // if the user's location didn't change, this doesn't get called automatically
            [self mapView:_mapView didUpdateUserLocation:_mapView.userLocation];
        }
        
    } else {
        _geoButton.style = UIBarButtonItemStyleBordered;
        
        _lastUserLocation = _mapView.userLocation.coordinate;
        
        if ([_mapView.annotations count]) {
            _mapView.region = [self regionForAnnotations:_mapView.annotations];
        }
    }
}

- (void)showListView:(BOOL)showList
{
    CGRect frame = _searchBar.frame;
    
	if (showList && !_displayingList) {
        _viewTypeButton.title = @"Map";
        
        // show the list.
        if (nil == self.searchResultsTableView) {
            self.searchResultsTableView = [[[MapSearchResultsTableView alloc] initWithFrame:_mapView.frame] autorelease];
            self.searchResultsTableView.campusMapVC = self;
            _searchController.searchResultsTableView = self.searchResultsTableView;
            _searchController.searchResultsDelegate = self.searchResultsTableView;
            _searchController.searchResultsDataSource = self.searchResultsTableView;
        }
        
        self.searchResultsTableView.searchResults = _searchResults;
        
        [self.view addSubview:self.searchResultsTableView];
        [_searchBar addDropShadow];
        
        // hide the toolbar and stretch the search bar
        _toolBar.alpha = 0.0;
        frame.size.width = self.view.frame.size.width;

	} else if (!showList && _displayingList) {
        
        [self.searchResultsTableView removeFromSuperview];
        _searchController.searchResultsTableView = nil;
        self.searchResultsTableView = nil;
        
        if (_hasSearchResults) {
            _viewTypeButton.title = @"List";
        } else {
            _viewTypeButton.title = @"Browse";
            // show the map, by hiding the list.
            _toolBar.alpha = 1.0;
            frame.size.width = [self searchBarWidth];
        }
	}

    _searchBar.frame = frame;
    frame = _bookmarkButton.frame;
    frame.origin.x = _searchBar.frame.size.width - frame.size.width - 7;
    _bookmarkButton.frame = frame;
	
	_displayingList = showList;
	
}

- (void)viewTypeChanged:(id)sender
{
	// if there is nothing in the search bar, we are browsing categories; otherwise go to list view
	if (!_displayingList && !_hasSearchResults) {
		if (nil != _selectionVC) {
			[_selectionVC dismissModalViewControllerAnimated:NO];
			[_selectionVC release];
			_selectionVC = nil;
		}
		
        _selectionVC = [[MapSelectionController alloc] init];
        _selectionVC.mapVC = self;
        
        if ([self.searchController isActive]) {
            [self.searchController setActive:NO animated:YES];
            [self searchBarCancelButtonClicked:_searchBar];
        }
        
        UINavigationController *dummyNavC = [[UINavigationController alloc] initWithRootViewController:_selectionVC];
        
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:dummyNavC animated:YES];
        [dummyNavC release];
        
	} else {	
		[self showListView:!_displayingList];
	}
}

- (void)receivedNewSearchResults:(NSArray*)searchResults query:(NSString *)searchQuery type:(NSString *)searchType
{	
    NSMutableArray *searchResultsArr = [NSMutableArray arrayWithCapacity:searchResults.count];
    
    if (searchType == nil) {
        for (NSDictionary *info in searchResults) {
            ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:info] autorelease];
            [searchResultsArr addObject:annotation];
        }
    } else if ([searchType isEqualToString:@"course"]) {
        for (NSDictionary *info in searchResults) {
            HarvardMapSearchAnnotation *annotation = [[[HarvardMapSearchAnnotation alloc] initWithInfo:info] autorelease];
            [searchResultsArr addObject:annotation];
        }
    }

    self.searchResults = searchResultsArr;
}


#pragma mark UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self setupSearchController]; // in case we got rid of it from a memory warning
    [self hideToolBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    
    [self restoreToolBar];

	// delete any previous instance of this search term
	MapSearch* mapSearch = [CoreDataManager getObjectForEntity:CampusMapSearchEntityName attribute:@"searchTerm" value:searchBar.text];
	if (nil != mapSearch) {
		[CoreDataManager deleteObject:mapSearch];
	}
	
	// insert the new instance of this search term
	mapSearch = [CoreDataManager insertNewObjectForEntityForName:CampusMapSearchEntityName];
	mapSearch.searchTerm = searchBar.text;
	mapSearch.date = [NSDate date];
	[CoreDataManager saveData];
	
	// determine if we are past our max search limit. If so, trim an item
	NSError* error = nil;
	
	NSFetchRequest* countFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[countFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName inManagedObjectContext:[CoreDataManager managedObjectContext]]];
	NSUInteger count = 	[[CoreDataManager managedObjectContext] countForFetchRequest:countFetchRequest error:&error];
	
	// cap the number of previous searches maintained in the DB. If we go over the limit, delete one. 
	if(nil == error && count > kPreviousSearchLimit)
	{
		// get the oldest item
		NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
		NSFetchRequest* limitFetchRequest = [[[NSFetchRequest alloc] init] autorelease];		
		[limitFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[limitFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName inManagedObjectContext:[CoreDataManager managedObjectContext]]];
		[limitFetchRequest setFetchLimit:1];
		NSArray* overLimit = [[CoreDataManager managedObjectContext] executeFetchRequest: limitFetchRequest error:nil];
		 
		if (overLimit && overLimit.count == 1) {
			[[CoreDataManager managedObjectContext] deleteObject:[overLimit objectAtIndex:0]];
		}

		[CoreDataManager saveData];
	}
	
	// ask the campus map view controller to perform the search
	[self search:searchBar.text params:nil];
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.navigationItem.rightBarButtonItem.title = _displayingList ? @"Map" : @"Browse";
	_hasSearchResults = NO;
    [_mapView removeAnnotations:_mapView.annotations];
    _searchBar.text = nil;
    [self restoreToolBar];
}

- (void)searchOverlayTapped {
    // be more aggressive about clearing results
    // because "browse" only appears when there are no results
    [self searchBarCancelButtonClicked:_searchBar];
}

- (void)hideToolBar {
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
    _bookmarkButton.alpha = 0.0;
    if (!_displayingList) {
        _searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT);
        _toolBar.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)restoreToolBar {
    [_searchBar setShowsCancelButton:NO animated:YES];
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
    _bookmarkButton.alpha = 1.0;
    if (!_displayingList) {
        _searchBar.frame = CGRectMake(0, 0, [self searchBarWidth], NAVIGATION_BAR_HEIGHT);
        _toolBar.alpha = 1.0;
    }
    [UIView commitAnimations];

    CGRect frame = _bookmarkButton.frame;
    frame.origin.x = _searchBar.frame.size.width - frame.size.width - 7;
    _bookmarkButton.frame = frame;
}

#pragma mark Custom Bookmark Button Functionality

// TODO: merge this code with -[self viewTypeChanged:]
- (void)bookmarkButtonClicked:(UIButton *)sender
{
	if (nil != _selectionVC) {
		[_selectionVC dismissModalViewControllerAnimated:NO];
		[_selectionVC release];
		_selectionVC = nil;
	}
	
    _selectionVC = [[MapSelectionController alloc] init];
    _selectionVC.mapVC = self;
    UINavigationController *dummyNavC = [[UINavigationController alloc] initWithRootViewController:_selectionVC];
    
    _selectionVC.view;
    [_selectionVC switchToSegmentIndex:MapSelectionControllerSegmentBookmarks];

	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate presentAppModalViewController:dummyNavC animated:YES];
    [dummyNavC release];
}

#pragma mark MKMapView delegation

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    DLog(@"located; %@", _mapView.showsUserLocation ? @"YES" : @"NO");
    if (_mapView.showsUserLocation) {
        _mapView.region = MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.001, 0.001));
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    if ([overlay isKindOfClass:[PolygonOverlay class]]) {
        PolygonOverlayView *view = [[PolygonOverlayView alloc] initWithOverlay:overlay];
        return [view autorelease];
    } else if ([overlay isKindOfClass:[MapTileOverlay class]]) {
        MapTileOverlayView *view = [[MapTileOverlayView alloc] initWithOverlay:overlay];
        return [view autorelease];
    }
    return nil;
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    DLog(@"%@", _mapView.showsUserLocation ? @"YES" : @"NO");
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    DLog(@"%@", _mapView.showsUserLocation ? @"YES" : @"NO");
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if (annotation == mapView.userLocation) {
        MKAnnotationView *annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"eghrfa"] autorelease];
        annotationView.image = [UIImage imageNamed:@"maps/map_location.png"];
        return annotationView;
    } else {
        MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"hfauiwh"] autorelease];
        annotationView.animatesDrop = YES;
        annotationView.canShowCallout = YES;
        if ([annotation isKindOfClass:[ArcGISMapAnnotation class]] && ((ArcGISMapAnnotation *)annotation).dataPopulated) {
            UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            annotationView.rightCalloutAccessoryView = disclosureButton;
        }
        return annotationView;
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    // if this is the user location, don't do anything
    if ([views count] == 1 && ((MKAnnotationView *)[views lastObject]).annotation == _mapView.userLocation)
        return;
    
    _mapView.region = [self regionForAnnotations:_searchResults];
    
    if ([_mapView.annotations count] == 1 && [_mapView.selectedAnnotations count] == 0) {
        id<MKAnnotation> annotation = [_mapView.annotations lastObject];
        // check if annotation has lat/lon
        if (![annotation isKindOfClass:[ArcGISMapAnnotation class]]
            || ((ArcGISMapAnnotation *)annotation).coordinate.longitude != 0) {
            [_mapView selectAnnotation:[_mapView.annotations lastObject] animated:YES];
        }
    }
}

- (void)pushAnnotationDetails:(id <MKAnnotation>)annotation animated:(BOOL)animated
{
	// determine the type of the annotation. If it is a search result annotation, display the details
	if ([annotation isKindOfClass:[ArcGISMapAnnotation class]]) {
		
		// push the details page onto the stack for the item selected. 
		MITMapDetailViewController *detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController" bundle:nil] autorelease];
		
		detailsVC.annotation = annotation;
		detailsVC.title = @"Info";
		detailsVC.campusMapVC = self;
		
		[self.navigationController pushViewController:detailsVC animated:animated];		
	}
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    id<MKAnnotation>annotation = view.annotation;
    if ([annotation isKindOfClass:[ArcGISMapAnnotation class]]) {
        ArcGISMapAnnotation *polyAnnotation = (ArcGISMapAnnotation *)annotation;
        if ([polyAnnotation canAddOverlay]) {
            PolygonOverlay *polyOverlay = polyAnnotation.polygon;
            [mapView addOverlay:polyOverlay];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    id<MKAnnotation>annotation = view.annotation;
    if ([annotation isKindOfClass:[ArcGISMapAnnotation class]]) {
        ArcGISMapAnnotation *polyAnnotation = (ArcGISMapAnnotation *)annotation;
        if ([polyAnnotation canAddOverlay]) {
            PolygonOverlay *polyOverlay = polyAnnotation.polygon;
            [mapView removeOverlay:polyOverlay];
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	[self pushAnnotationDetails:view.annotation animated:YES];
}

//- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
//}

#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject
{	
    
    if (JSONObject && [JSONObject isKindOfClass:[NSDictionary class]]) {
        NSArray *searchResults = [JSONObject objectForKey:@"results"];

        if ([request.userData isKindOfClass:[NSString class]]
            && [request.userData isEqualToString:kAPISearch])
        {
            // result is coming in from -[self search:params:]

            [_lastSearchText release];
            _lastSearchText = [request.params objectForKey:@"q"];
            
            NSString *searchType = [request.params objectForKey:@"loc"];
            
            [self receivedNewSearchResults:searchResults query:_lastSearchText type:searchType];
            
            // if there were no search results, tell the user about it. 
            if (nil == searchResults || searchResults.count <= 0) {
                [self noSearchResultsAlert];
                _hasSearchResults = NO;
                self.navigationItem.rightBarButtonItem.title = _displayingList ? @"Map" : @"Browse";
            } else {
                _hasSearchResults = YES;
                [_searchController hideSearchOverlayAnimated:YES];
                if(!_displayingList)
                    self.navigationItem.rightBarButtonItem.title = @"List";
            }
            
            
        } else if ([request.userData isKindOfClass:[ArcGISMapAnnotation class]]) {
            // updating an annotation search request
            ArcGISMapAnnotation *annotation = request.userData;
            
            if (searchResults.count > 0) {
                BOOL isViewingAnnotation = ([[_mapView selectedAnnotations] lastObject] == annotation);
                [_mapView removeAnnotation:annotation];

                [annotation updateWithInfo:[searchResults objectAtIndex:0]];
                [_mapView addAnnotation:annotation];
                
                if (isViewingAnnotation) {
                    [_mapView selectAnnotation:annotation animated:NO];
                }
                _hasSearchResults = YES;
                self.navigationItem.rightBarButtonItem.title = @"List";
            } else {
                _hasSearchResults = NO;
                self.navigationItem.rightBarButtonItem.title = @"Browse";
            }
            
        }

	} else if (JSONObject && [JSONObject isKindOfClass:[NSArray class]]) {
        NSString *category = [request.params objectForKey:@"category"];
        if (category != nil) {
            self.searchResults = nil;
            
            if ([JSONObject count]) {
                
                // TODO: cache results to reduce the number of network calls
                // made for the same exact purpose as "browse by categories"
                for (NSDictionary *thisItem in JSONObject) {
                    ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:thisItem] autorelease];
                    if (!annotation.dataPopulated) {
                        [annotation searchAnnotationWithDelegate:self category:category];
                    }
                }
                [_searchController hideSearchOverlayAnimated:YES];
            } else {
                
                [self noSearchResultsAlert];
                _hasSearchResults = NO;
                self.navigationItem.rightBarButtonItem.title = _displayingList ? @"Map" : @"Browse";
            }
        }
    }
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    if ([request.userData isKindOfClass:[NSString class]]
        && [(NSString *)request.userData isEqualToString:kAPISearch])
    {
        return YES;
	}
    return NO;
}

- (void)search:(NSString *)searchText params:(NSDictionary *)params
{
     
	if (nil == searchText) {
		self.searchResults = nil;

		[_lastSearchText release];
		_lastSearchText = nil;
		
	} else {
        JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        apiRequest.userData = kAPISearch;
        
        NSMutableDictionary *searchParams = [[params mutableCopy] autorelease];
        if (!searchParams) {
            searchParams = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        
        NSArray *searchParts = [searchText componentsSeparatedByString:@":"];
        if ([searchParts count] == 2 && [[searchParts objectAtIndex:0] isEqualToString:@"category"]) {
            searchText = [searchParts objectAtIndex:1];
            [searchParams setObject:searchText forKey:@"category"];
        } else {
            [searchParams setObject:searchText forKey:@"q"];
        }
        
        [apiRequest requestObjectFromModule:@"map"
                                    command:@"search"
                                 parameters:searchParams];
	}
}


@end
