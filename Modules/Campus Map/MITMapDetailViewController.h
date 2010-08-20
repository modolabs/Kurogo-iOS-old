#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TabViewControl.h"
#import "JSONAPIRequest.h"
#import "ConnectionWrapper.h"


@class ArcGISMapAnnotation;
@class CampusMapViewController;

@interface MITMapDetailViewController : UIViewController <ConnectionWrapperDelegate, TabViewControlDelegate, JSONAPIDelegate, UIWebViewDelegate> {

	IBOutlet UIButton* _bookmarkButton;

	IBOutlet UILabel* _nameLabel; // building name label
	IBOutlet UILabel* _locationLabel; 	// building address label
	
	// map thumbnail
	IBOutlet MKMapView* _mapView;
	IBOutlet UIButton* _mapViewContainer;

	IBOutlet UIScrollView* _scrollView; // main content scroll view
	
	IBOutlet TabViewControl* _tabViewControl; // tab controller for which we are a delegate.
	IBOutlet UIView* _tabViewContainer; // container view for the tabbed contents.     
	CGFloat _tabViewContainerMinHeight;
	
    // details tab
	IBOutlet UIWebView* _whatsHereView;
    
	// photo tab
	IBOutlet UIView* _buildingView; // view for the building image info
	IBOutlet UIImageView* _buildingImageView; // image view for the building
	
	IBOutlet UIView* _loadingImageView;
	IBOutlet UIView* _loadingResultView;
	
	// array of views that appear in our tabs, indexed by tab index. 
	NSMutableArray* _tabViews;
	
	ArcGISMapAnnotation *_annotation; // the search result we are attempting to display
	CampusMapViewController* _campusMapVC; // the campus map view we were pushed from, if any
	
	// Connection Wrapper used for loading building images
	ConnectionWrapper *imageConnectionWrapper;
	
	// network activity status for loading building image
	BOOL networkActivity;
	
	// to persist saved state
	int _startingTab;
}

@property (nonatomic, retain) ArcGISMapAnnotation *annotation;
@property (nonatomic, assign) CampusMapViewController* campusMapVC;
@property (nonatomic, retain) NSString* queryText;
@property (nonatomic, retain) ConnectionWrapper *imageConnectionWrapper;
@property int startingTab;

-(IBAction) mapThumbnailPressed:(id)sender;
-(IBAction) bookmarkButtonTapped;

@end
