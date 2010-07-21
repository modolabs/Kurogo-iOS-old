#import "MITMapSearchResultAnnotation.h"
#import "TileServerManager.h"

@implementation ArcGISMapSearchResultAnnotation
@synthesize uniqueID = _uniqueID;
@synthesize polygons = _polygons;
@synthesize name = _name;
@synthesize street = _street;
@synthesize city = _city;
@synthesize info = _info;
@synthesize yearBuilt = _yearBuilt;
@synthesize bookmark = _bookmark;
@synthesize dataPopulated = _dataPopulated;
@synthesize coordinate = _coordinate;

+ (void)executeServerSearchWithQuery:(NSString *)query jsonDelegate:(id<JSONAPIDelegate>)delegate object:(id)object {
	JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:delegate];
	apiRequest.userData = object;
	[apiRequest requestObjectFromModule:@"map"
                                command:@"search"
                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:query, @"q", nil]];
}

- (void)dealloc {
	self.uniqueID = nil;
	self.name = nil;
	self.street = nil;
	self.city = nil;
	self.info = nil;
    self.polygons = nil;
	
	[super dealloc];
}


- (id)initWithInfo:(NSDictionary*)info
{
    NSLog(@"%@", [info description]);
	if (self = [super init]) {
		self.info = info;

        NSDictionary *infoAttributes = [self.info objectForKey:@"attributes"];
        NSDictionary *infoGeometry = [self.info objectForKey:@"geometry"];
        
		self.uniqueID = [infoAttributes objectForKey:@"OBJECTID"];
        self.name = [infoAttributes objectForKey:@"Building Name"];
        self.street = [infoAttributes objectForKey:@"Address"];
        self.city = [infoAttributes objectForKey:@"City"];
        self.yearBuilt = [[infoAttributes objectForKey:@"Year Built"] intValue];
        
        // already an array of coordinates
        self.polygons = [infoGeometry objectForKey:@"rings"];

        
        if ([self.polygons count] > 0) {
            NSArray *ring = [self.polygons objectAtIndex:0];
            NSInteger numPoints = 0;
            CGFloat totalX = 0.0;
            CGFloat totalY = 0.0;

            for (NSArray *point in ring) {
                totalX += [[point objectAtIndex:0] doubleValue];
                totalY += [[point objectAtIndex:1] doubleValue];
                numPoints++;
            }
            
            CGPoint centroid = CGPointMake(totalX / numPoints, totalY / numPoints);
            _coordinate = [TileServerManager coordForProjectedPoint:centroid];
        }
        
		//_coordinate.latitude = [[info objectForKey:@"lat_wgs84"] doubleValue];
		//_coordinate.longitude = [[info objectForKey:@"long_wgs84"] doubleValue];
				
		self.dataPopulated = YES;
	}
	
	return self;
}

- (NSDictionary *)info {
	// if there is a dictionary of info, return it. Otherwise construct the dictionary based on what we do have. 
	if (nil != _info)
		return _info;
	
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	if (nil == self.uniqueID)	[info setObject:self.uniqueID	forKey:@"id"];
	if (nil == self.name)		[info setObject:self.name		forKey:@"name"];
	if (nil == self.street)		[info setObject:self.street		forKey:@"street"];
	if (nil == self.city)		[info setObject:self.city		forKey:@"city"];
	
	//[info setObject:[NSNumber numberWithDouble:_coordinate.latitude]	forKey:@"lat_wgs84"];
	//[info setObject:[NSNumber numberWithDouble:_coordinate.longitude]	forKey:@"long_wgs84"];
    
	return info;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D) coordinate {
	if (self = [super init]) {
		_coordinate = coordinate;
	}
	
	return self;
}

#pragma mark MKAnnotation

- (NSString *)title
{
    if (nil != self.name) {
		return self.name;
	}
	
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}
                       
@end





@implementation HarvardMapSearchResultAnnotation

@synthesize featureType = _featureType, matchString = _matchString, searchString = _searchString, coordinate = _coordinate;

- (NSString *)title
{
    if (nil != self.matchString) {
		return self.matchString;
	}
	
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}




@end
