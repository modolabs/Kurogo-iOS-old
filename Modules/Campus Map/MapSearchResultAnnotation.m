#import "MapSearchResultAnnotation.h"
#import "TileServerManager.h"


@implementation ArcGISMapSearchResultAnnotation
@synthesize uniqueID = _uniqueID;
@synthesize polygon = _polygon;
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
	
	[super dealloc];
}


- (id)initWithInfo:(NSDictionary*)info
{
	if (self = [super init]) {
		self.info = info;

        NSDictionary *infoAttributes = [self.info objectForKey:@"attributes"];
        NSDictionary *infoGeometry = [self.info objectForKey:@"geometry"];
        
		self.uniqueID = [infoAttributes objectForKey:@"OBJECTID"];
        self.name = [infoAttributes objectForKey:@"Building Name"];
        self.street = [infoAttributes objectForKey:@"Address"];
        self.city = [infoAttributes objectForKey:@"City"];
        self.yearBuilt = [[infoAttributes objectForKey:@"Year Built"] intValue];
        
        NSArray *rings = [infoGeometry objectForKey:@"rings"];
        self.polygon = [[PolygonOverlay alloc] initWithRings:rings];
        self.coordinate = self.polygon.coordinate;

        NSLog(@"found %@ at %.4f, %.4f", self.name, self.coordinate.longitude, self.coordinate.latitude);

        NSLog(@"%@", [self.polygon description]);
		self.dataPopulated = YES;
	}
	
	return self;
}

- (BOOL)canAddOverlay {
    return [self.polygon.rings count] > 0;
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
	    
	return info;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
	if (self = [super init]) {
		_coordinate = coordinate;
	}
	
	return self;
}

#pragma mark MKAnnotation

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    return self.street;
}
                       
@end




/*

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
 
*/