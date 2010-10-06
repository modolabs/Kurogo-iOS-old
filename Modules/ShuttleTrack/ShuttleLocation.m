
#import "ShuttleLocation.h"
#import "ConnectionDetector.h"

@implementation ShuttleLocation
@synthesize coordinate = _coordinate;
@synthesize endCoordinate = _endCoordinate;
@synthesize secsSinceReport = _secsSinceReport;
@synthesize heading = _heading;
@synthesize speed = _speed;
@synthesize vehicleId = _vehicleId;
@synthesize image = _image;

static NSMutableDictionary *s_markerImages = nil;

+ (void)clearAllMarkerImages
{
    [s_markerImages release];
    s_markerImages = nil;
}

- (id)initWithDictionary:(NSDictionary*)dictionary
{
	if (self = [super init])
	{
        _vehicleId = [[dictionary objectForKey:@"id"] integerValue];
        
		_coordinate.latitude = [[dictionary objectForKey:@"lat"] doubleValue];
		_coordinate.longitude = [[dictionary objectForKey:@"lon"] doubleValue];

        _endCoordinate = _coordinate;
        
		self.secsSinceReport = [[dictionary objectForKey:@"secsSinceReport"] intValue];
		self.heading = [[dictionary objectForKey:@"heading"] intValue];
        self.speed = [[dictionary objectForKey:@"speed"] floatValue];
		
		//self.iconURL = [dictionary objectForKey:@"iconURL"];

        if (s_markerImages == nil)
            s_markerImages = [[NSMutableDictionary alloc] init];
        
        NSString *iconURL = [dictionary objectForKey:@"iconURL"];
        NSString *hash = [NSString stringWithFormat:@"%d", [iconURL hash]];
        UIImage *image = [s_markerImages objectForKey:hash];
        if (image == nil) {
            NSURL *url = [NSURL URLWithString:iconURL];
            if ([ConnectionDetector isConnected]) {
                // TODO: make sure this doens't block
                NSData *data = [NSData dataWithContentsOfURL:url];
                image = [[UIImage alloc] initWithData:data];
                [s_markerImages setObject:image forKey:hash];
            }
        }
        self.image = image;
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

- (void)dealloc
{
    _image = nil;
    [super dealloc];
}

@end
