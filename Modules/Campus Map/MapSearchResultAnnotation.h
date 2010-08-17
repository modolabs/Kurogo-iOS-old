#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JSONAPIRequest.h"
#import "PolygonOverlay.h"


@interface ArcGISMapAnnotation : NSObject <MKAnnotation> {

	CLLocationCoordinate2D _coordinate;
    NSString *_uniqueID; // hidden
	NSString *_name;
	NSString *_street;

    PolygonOverlay *_polygon;
    
	// has the data of this object been populated yet
	BOOL _dataPopulated;
	
	NSDictionary* _info;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) PolygonOverlay *polygon;

@property (nonatomic, retain) NSString *uniqueID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *street;
@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, retain) NSDictionary *info;

@property BOOL dataPopulated;

- (void)searchAnnotationWithDelegate:(id<JSONAPIDelegate>)delegate category:(NSString *)category;

- (id)initWithInfo:(NSDictionary*)info;
- (void)updateWithInfo:(NSDictionary *)info;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (BOOL)canAddOverlay;

@end





// the mapsearch for courses outputs this kind of data:

/*
 "feature_type" : "Course Location",
 "search_string" : "barker center 114 kresge room",
 "match_string" : "Barker Center 114 Kresge Room",
 "xcoord" : "760329.91",
 "ycoord" : "2961044.576"
 */




@interface HarvardMapSearchAnnotation : NSObject <MKAnnotation> {
    NSString *_featureType;
    NSString *_searchString;
    NSString *_matchString;
    CLLocationCoordinate2D _coordinate;
}

- (id)initWithInfo:(NSDictionary*)info;

@property (nonatomic, retain) NSString *featureType;
@property (nonatomic, retain) NSString *matchString;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end


