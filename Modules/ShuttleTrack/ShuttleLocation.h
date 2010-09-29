
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>{

	int _secsSinceReport;
	int _heading;
	NSString * iconURL;

	CLLocationCoordinate2D _coordinate;
}

@property int secsSinceReport;
@property int heading;
@property (readwrite, retain) NSString * iconURL; 

-(id) initWithDictionary:(NSDictionary*)dictionary;

@end
