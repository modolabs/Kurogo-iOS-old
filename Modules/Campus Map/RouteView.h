#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MITMapView;

@interface RouteView : UIView {

	MKMapView* _map;
}

@property (nonatomic, assign) MKMapView* map;

@end
