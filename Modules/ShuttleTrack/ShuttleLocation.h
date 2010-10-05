
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>{

	int _secsSinceReport;
	int _heading;
    CGFloat _speed;
	NSString * iconURL;
    NSInteger vehicleId;

	CLLocationCoordinate2D _coordinate;
    CLLocationCoordinate2D _endCoordinate; // end of animation
}

@property (nonatomic) NSInteger secsSinceReport;
@property (nonatomic) NSInteger heading;
@property (nonatomic) CGFloat speed;
@property (readwrite, retain) NSString * iconURL; 
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationCoordinate2D endCoordinate;
@property (nonatomic) NSInteger vehicleId;

-(id) initWithDictionary:(NSDictionary*)dictionary;

@end
