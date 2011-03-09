#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "MapModule.h"
#import "MapSettingsViewController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOMapCategory.h"
#import "CoreDataManager.h"
#import "MapKit+KGOAdditions.h"

@implementation MapHomeViewController

@synthesize searchTerms;

- (void)mapTypeDidChange:(NSNotification *)aNotification {
    _mapView.mapType = [[aNotification object] integerValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KGOModule *mapModule = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] moduleForTag:MapTag];
    self.title = mapModule.shortName;

    _mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePreference];
    [_mapView centerAndZoomToDefaultRegion];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapTypeDidChange:) name:MapTypePreferenceChanged object:nil];

	_searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
	
	indoorMode = NO;
	NSArray *items = nil;
	UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	if (indoorMode) {
		items = [NSArray arrayWithObjects:_infoButton, spacer, _browseButton, spacer, _bookmarksButton, spacer, _settingsButton, nil];
		_infoButton.image = nil;
	} else {
		items = [NSArray arrayWithObjects:_locateUserButton, spacer, _browseButton, spacer, _bookmarksButton, spacer, _settingsButton, nil];
		_locateUserButton.image = nil;
	}

	_bottomBar.items = items;
	
	_browseButton.image = nil;
	_bookmarksButton.image = nil;
	_settingsButton.image = nil;
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
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:categoryVC animated:YES];
}

- (IBAction)bookmarksButtonPressed {
}

- (IBAction)settingsButtonPressed {
	MapSettingsViewController *vc = [[[MapSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    vc.title = @"Settings";
    vc.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:vc animated:YES];
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
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"place", controller, @"searchController", nil];
    KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showPage:LocalPathPageNameDetail forModuleTag:MapTag params:params];
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

@end
