
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>{

	int _secsSinceReport;
	int _heading;
    CGFloat _speed;
    NSInteger vehicleId;
    UIImage *_image;

	CLLocationCoordinate2D _coordinate;
    CLLocationCoordinate2D _endCoordinate; // end of animation
}

@property (nonatomic) NSInteger secsSinceReport;
@property (nonatomic) NSInteger heading;
@property (nonatomic) CGFloat speed;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationCoordinate2D endCoordinate;
@property (nonatomic) NSInteger vehicleId;
@property (nonatomic, assign) UIImage *image;

+ (void)clearAllMarkerImages;

-(id) initWithDictionary:(NSDictionary*)dictionary;

@end
