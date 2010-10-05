
#import "ShuttleLocation.h"


@implementation ShuttleLocation
@synthesize coordinate = _coordinate;
@synthesize endCoordinate = _endCoordinate;
@synthesize secsSinceReport = _secsSinceReport;
@synthesize heading = _heading;
@synthesize iconURL;
@synthesize speed = _speed;
@synthesize vehicleId = _vehicleId;

-(id) initWithDictionary:(NSDictionary*)dictionary
{
	if(self = [super init])
	{
        _vehicleId = [[dictionary objectForKey:@"id"] integerValue];
        
		_coordinate.latitude = [[dictionary objectForKey:@"lat"] doubleValue];
		_coordinate.longitude = [[dictionary objectForKey:@"lon"] doubleValue];

        _endCoordinate = _coordinate;
        
		self.secsSinceReport = [[dictionary objectForKey:@"secsSinceReport"] intValue];
		self.heading = [[dictionary objectForKey:@"heading"] intValue];
        self.speed = [[dictionary objectForKey:@"speed"] floatValue];
		
		self.iconURL = [dictionary objectForKey:@"iconURL"];
	}
	
	return self;
}

// Title and subtitle for use by selection UI.
- (NSString *)title
{
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}

@end
