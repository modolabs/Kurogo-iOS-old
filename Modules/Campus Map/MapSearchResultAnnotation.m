#import "MapSearchResultAnnotation.h"
#import "TileServerManager.h"


@implementation ArcGISMapAnnotation
@synthesize uniqueID = _uniqueID;
@synthesize polygon = _polygon;
@synthesize name = _name;
@synthesize street = _street;
@synthesize info = _info;
@synthesize dataPopulated = _dataPopulated;
@synthesize coordinate = _coordinate;

- (void)searchAnnotationWithDelegate:(id<JSONAPIDelegate>)delegate category:(NSString *)category {
	JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:delegate];
    NSLog(@"%@", [delegate description]);
	apiRequest.userData = self;
    NSDictionary *params = nil;
    if (category) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"q", category, @"category", nil];
    } else {
        params = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"q", nil];
    }
	[apiRequest requestObjectFromModule:@"map"
                                command:@"search"
                             parameters:params];
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
	}
	return self;
}

- (void)updateWithInfo:(NSDictionary *)info 
{
    self.info = info;
    
    if (!self.name) {
        self.name = [info objectForKey:@"displayName"];
    }
    
    if ([TileServerManager isInitialized]) {
        NSDictionary *infoAttributes = [self.info objectForKey:@"attributes"];
        NSString *geometryType = [self.info objectForKey:@"geometryType"];
        NSDictionary *infoGeometry = [self.info objectForKey:@"geometry"];
        if ([geometryType isEqualToString:@"esriGeometryPolygon"]) {
            NSArray *rings = [infoGeometry objectForKey:@"rings"];
            if (rings) {
                self.polygon = [[PolygonOverlay alloc] initWithRings:rings];
                self.coordinate = self.polygon.coordinate;
            }
        } else if ([geometryType isEqualToString:@"esriGeometryPoint"]) {
            CGFloat x = [[infoGeometry objectForKey:@"x"] doubleValue];
            CGFloat y = [[infoGeometry objectForKey:@"y"] doubleValue];
            self.coordinate = [TileServerManager coordForProjectedPoint:CGPointMake(x, y)];
            
        } else {
            NSLog(@"info: %@", [self.info description]);
        }

        if (!self.name) {
            self.name = [infoAttributes objectForKey:@"Building Name"];
        }
        
        
        if (!self.uniqueID) {
            self.uniqueID = [infoAttributes objectForKey:@"OBJECTID"];
            if (!self.uniqueID) {
                self.uniqueID = [NSString stringWithFormat:@"%d", [self hash]];
            }
        }
        
        if (!self.street)
            self.street = [infoAttributes objectForKey:@"Address"];
        
        NSLog(@"found %@ at %.4f, %.4f", self.name, self.coordinate.longitude, self.coordinate.latitude);
        
        if (infoAttributes) {
            self.dataPopulated = YES;
        }
    }
}

- (BOOL)canAddOverlay {
    return (self.dataPopulated && [[self.polygon rings] count] > 0);
}

- (NSDictionary *)info {
	// if there is a dictionary of info, return it. Otherwise construct the dictionary based on what we do have. 
	if (nil != _info)
		return _info;
	
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	if (nil != self.uniqueID)	[info setObject:self.uniqueID	forKey:@"id"];
	if (nil != self.name)		[info setObject:self.name		forKey:@"name"];
	if (nil != self.street)		[info setObject:self.street		forKey:@"street"];
	    
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
    if ([self.name length]) {
        return self.name;
    } else if ([self.street length]) {
        return self.street; // don't turn off the annotation if we have something to show
    }
    return nil;
}

- (NSString *)subtitle
{
    if ([self.name length]) {
        return self.street;
    } // otherwise street would be returned in title
    return nil;
}

@end






@implementation HarvardMapSearchAnnotation

@synthesize featureType = _featureType, matchString = _matchString, searchString = _searchString, coordinate = _coordinate;

- (id)initWithInfo:(NSDictionary*)info {
	if (self = [super init]) {
        self.matchString = [info objectForKey:@"match_string"];
        self.searchString = [info objectForKey:@"feature_type"];
        self.featureType = [info objectForKey:@"feature_type"];
        CGFloat lat = [[info objectForKey:@"lat"] doubleValue];
        CGFloat lon = [[info objectForKey:@"lon"] doubleValue];
        self.coordinate = CLLocationCoordinate2DMake(lat, lon);
	}
        
	return self;
}

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
 
