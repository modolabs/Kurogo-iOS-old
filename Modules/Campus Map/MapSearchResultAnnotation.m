#import "MapSearchResultAnnotation.h"
#import "TileServerManager.h"


@implementation ArcGISMapSearchResultAnnotation
@synthesize uniqueID = _uniqueID;
@synthesize polygon = _polygon;
@synthesize name = _name;
@synthesize street = _street;
@synthesize info = _info;
@synthesize bookmark = _bookmark;
@synthesize dataPopulated = _dataPopulated;
@synthesize coordinate = _coordinate;

// TODO: remove query (always self.name) and object (always self)
- (void)searchAnnotationWithDelegate:(id<JSONAPIDelegate>)delegate {
	JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:delegate];
	apiRequest.userData = self;
	[apiRequest requestObjectFromModule:@"map"
                                command:@"search"
                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.name, @"q", nil]];
}

- (void)dealloc {
	self.uniqueID = nil;
	self.name = nil;
	self.street = nil;
	self.info = nil;
	
	[super dealloc];
}

- (NSDictionary *)attributes {
    return [self.info objectForKey:@"attributes"];
}

- (id)initWithInfo:(NSDictionary*)info
{
	if (self = [super init]) {
		[self updateWithInfo:info];
        //if (!self.dataPopulated) {
        //    [self executeServerSearchWithQuery:self.name jsonDelegate:self object:nil];
        //}
	}
	return self;
}

- (void)updateWithInfo:(NSDictionary *)info 
{
    self.info = info;
    
    NSDictionary *infoAttributes = [self.info objectForKey:@"attributes"];
    NSDictionary *infoGeometry = [self.info objectForKey:@"geometry"];
    if (infoGeometry) {
        NSArray *rings = [infoGeometry objectForKey:@"rings"];
        if (rings) {
            self.polygon = [[PolygonOverlay alloc] initWithRings:rings];
            self.coordinate = self.polygon.coordinate;
            NSLog(@"%@", [self.polygon description]);
        }
    }
    
    self.uniqueID = [infoAttributes objectForKey:@"OBJECTID"];
    self.name = [infoAttributes objectForKey:@"Building Name"];
    self.street = [infoAttributes objectForKey:@"Address"];
    
    if (self.name == nil) {
        self.name = [info objectForKey:@"displayName"];
    }
    
    NSLog(@"found %@ at %.4f, %.4f", self.name, self.coordinate.longitude, self.coordinate.latitude);
    
    if (infoAttributes) {
        self.dataPopulated = YES;
    }    
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