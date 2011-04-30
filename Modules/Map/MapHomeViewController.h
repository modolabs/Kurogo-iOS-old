#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>
#import "KGOSearchDisplayController.h"
#import "KGORequest.h"

@class KGOSearchBar;
@class MKMapView;
@class MapModule;
@class KGOSegmentedControl;
@class KGOPlacemark;

@interface MapHomeViewController : UIViewController <MKMapViewDelegate,
KGOSearchDisplayDelegate, KGODetailPagerController, CLLocationManagerDelegate,
KGORequestDelegate> {
	
	IBOutlet KGOSearchBar *_searchBar;
	IBOutlet KGOToolbar *_bottomBar;
    IBOutlet UIImageView *_toolbarDropShadow;

	UIButton *_infoButton; // indoor maps only
	UIButton *_locateUserButton; // outdoor maps only (for now)
	UIButton *_browseButton;
	UIButton *_bookmarksButton;
	UIButton *_settingsButton;
    
    CLLocationManager *_locationManager;
    CLLocation *_userLocation;
    BOOL _didCenter;
    
    IBOutlet UIView *_mapBorder; // ipad only

	// TODO: indoor map initially won't be MKMapView
	IBOutlet MKMapView *_mapView;

	BOOL indoorMode;
	
	KGOSearchDisplayController *_searchController;
	UITableView *_searchResultsTableView; // only used as temporary reference
	KGOSegmentedControl *_mapListToggle;

    NSArray *_annotations;

    KGOPlacemark *_pendingPlacemark;
    KGORequest *_placemarkInfoRequest;
}

@property (nonatomic, retain) MapModule *mapModule;

@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *annotations;

@property (nonatomic) BOOL searchOnLoad; // tell the controller to start searching right away
@property (nonatomic, retain) NSDictionary *searchParams; // custom query to search if different from display text


- (IBAction)infoButtonPressed;
- (IBAction)locateUserButtonPressed;
- (IBAction)browseButtonPressed;
- (IBAction)bookmarksButtonPressed;
- (IBAction)settingsButtonPressed;

- (void)showUserLocationIfInRange;

- (void)setupToolbarButtons;
- (void)toolbarButtonPressed:(id)sender;

- (void)showMapListToggle;
- (void)hideMapListToggle;
- (void)switchToMapView;
- (void)switchToListView;
- (void)mapListSelectionChanged:(id)sender;

- (void)mapTypeDidChange:(NSNotification *)aNotification;

+ (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations restrictedToClass:(Class)restriction;

@end
