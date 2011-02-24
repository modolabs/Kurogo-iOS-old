#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>
#import "KGOSearchDisplayController.h"

@class KGOSearchBar;
@class MKMapView;

@interface MapHomeViewController : UIViewController <MKMapViewDelegate, KGOSearchDisplayDelegate> {
	
	IBOutlet KGOSearchBar *_searchBar;
	IBOutlet UIToolbar *_bottomBar;
	IBOutlet UIBarButtonItem *_infoButton; // indoor maps only
	IBOutlet UIBarButtonItem *_locateUserButton; // outdoor maps only (for now)
	IBOutlet UIBarButtonItem *_browseButton;
	IBOutlet UIBarButtonItem *_bookmarksButton;
	IBOutlet UIBarButtonItem *_settingsButton;

	// TODO: indoor map initially won't be MKMapView
	IBOutlet MKMapView *_mapView;

	// TODO: toggle between data sources instead
	BOOL indoorMode;
	
	KGOSearchDisplayController *_searchController;
	UITableView *_searchResultsTableView; // only used as temporary reference
	UISegmentedControl *_mapListToggle;

}

@property (nonatomic, retain) NSString *searchTerms;

- (IBAction)infoButtonPressed;
- (IBAction)locateUserButtonPressed;
- (IBAction)browseButtonPressed;
- (IBAction)bookmarksButtonPressed;
- (IBAction)settingsButtonPressed;

- (void)showMapListToggle;
- (void)hideMapListToggle;
- (void)switchToMapView;
- (void)switchToListView;
- (void)mapListSelectionChanged:(id)sender;

- (void)mapTypeDidChange:(NSNotification *)aNotification;

@end
