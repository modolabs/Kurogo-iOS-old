#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"
#import "KGOAppDelegate.h"

@implementation MapHomeViewController

@synthesize searchTerms;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// TODO: so maybe having a separate factory function in KGOSearchBar
	// for default search bar isn't the best idea
	CGRect frame = _searchBar.frame;
	[_searchBar removeFromSuperview];
    _searchBar = [[KGOSearchBar defaultSearchBarWithFrame:frame] retain];
	[self.view addSubview:_searchBar];

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

#pragma mark -

- (IBAction)infoButtonPressed {
	
}

- (IBAction)locateUserButtonPressed {
	
}

- (IBAction)browseButtonPressed {
	KGOCategoryListViewController *categoryVC = [[[KGOCategoryListViewController alloc] init] autorelease];
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:categoryVC animated:YES];
}

- (IBAction)bookmarksButtonPressed {
	
}

- (IBAction)settingsButtonPressed {
	
}

#pragma mark Search 

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
	
}

- (BOOL)searchControllerCanShowMap:(KGOSearchDisplayController *)controller {
	
	// show our map view above the list view
	
	if (!_searchBar.toolbarItems.count) {
		UISegmentedControl *segment = [[[UISegmentedControl alloc] init] autorelease];
		[segment insertSegmentWithTitle:@"Map" atIndex:0 animated:NO];
		[segment insertSegmentWithTitle:@"List" atIndex:1 animated:NO];
		[segment setEnabled:NO forSegmentAtIndex:0];
		UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithCustomView:segment] autorelease];
		[_searchBar addToolbarButton:item animated:NO];
	}
	
	return NO;
}

@end
