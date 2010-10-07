#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ShuttleRoute.h"
#import "ShuttleDataManager.h"

// note: this class does not create a pollingTimer because
// the one created by its associated ShuttleRouteViewController
// will already be polling

@interface RouteMapViewController : UIViewController <MKMapViewDelegate, ShuttleDataManagerDelegate>{

	IBOutlet MKMapView* _mapView;
	
	IBOutlet UILabel* _routeTitleLabel;
	IBOutlet UILabel* _routeStatusLabel;
	IBOutlet UIButton* _gpsButton; 
	IBOutlet UIImageView *_scrim;
	
	ShuttleRoute* _route;
	
	// extended info for the route. 
	//ShuttleRoute* _routeInfo;
	
	NSArray *_vehicleAnnotations;
    NSArray *_oldVehicleAnnotations;
	
	// extended route info keyed by stop ID
	NSMutableDictionary* _routeStops;
	
	CGFloat _lastZoomLevel;

	UIImage* _smallStopImage;
	UIImage* _smallUpcomingStopImage;
	UIImage* _largeStopImage;
	UIImage* _largeUpcomingStopImage;
	UIViewController* _MITParentViewController;
	
	BOOL hasStopInfoForMap;
	
	// the data representing the route points for overlay 
	MKPolyline * routeLine;
	
	// the view we create for the line on the map for overlay of route
	MKPolylineView* routeLineView;
	
	// the rect that bounds the loaded points for route-overlay
	MKMapRect routeRect;
	
	BOOL hasNarrowedRegion;
	
	UIView *loadingIndicator;
	
	UIView *logoView;
}

@property (nonatomic, retain) ShuttleRoute* route;
@property (nonatomic, assign) UIViewController* parentViewController;

@property (readonly) MKMapView* mapView;

@property (nonatomic, retain) MKPolyline * routeLine;
@property (nonatomic, retain) MKPolylineView* routeLineView;

-(IBAction) gpsTouched:(id)sender;
-(IBAction) refreshTouched:(id)sender;

-(void)narrowRegion;
-(void)assignRoutePoints;
-(void)setRouteOverLayBounds:(CLLocationCoordinate2D)center latDelta:(double)latDelta  lonDelta:(double) lonDelta;

-(void)fallBackViewDidLoad;
-(void) refreshRouteTitleInfo;
-(void)selectAnnon:(id <MKAnnotation>)annotation;

-(void)addLoadingIndicator;
-(void)removeLoadingIndicator;

@end
