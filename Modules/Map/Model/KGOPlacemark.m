#import "KGOPlacemark.h"
#import "KGOMapCategory.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import <CoreLocation/CoreLocation.h>
#import "KGOHTMLTemplate.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation KGOPlacemark

@dynamic longitude;
@dynamic street;
@dynamic geometryType;
@dynamic title;
@dynamic latitude;
@dynamic identifier;
@dynamic geometry;
@dynamic info;
@dynamic sortOrder;
@dynamic photo;
@dynamic bookmarked;
@dynamic categories;
@dynamic photoURL;
@dynamic userInfo;

@synthesize moduleTag;

#pragma mark KGOSearchResult, MKAnnotation

- (NSString *)subtitle {
    return self.street;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude floatValue], [self.longitude floatValue]);
}

- (BOOL)isBookmarked {
    return [self.bookmarked boolValue];
}

- (void)addBookmark {
    if (![self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:YES];
        [[CoreDataManager sharedManager] saveData];
    }
}

- (void)removeBookmark {
    if ([self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:NO];
        [[CoreDataManager sharedManager] saveData];
    }
}

- (BOOL)didGetSelected:(id)selector
{
    NSArray *placemarkArray = [NSArray arrayWithObject:self];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:placemarkArray, @"annotations", nil];
    return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:[self moduleTag] params:params];
}

#pragma mark -

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    self.title = [dictionary nonemptyStringForKey:@"title"];
    
    id descriptionInfo = [dictionary objectForKey:@"description"];
    if ([descriptionInfo isKindOfClass:[NSString class]] && [descriptionInfo length]) {
        self.info = descriptionInfo;
        
    } else if ([descriptionInfo isKindOfClass:[NSArray class]]) {
        KGOHTMLTemplate *itemTemplate = [[[KGOHTMLTemplate alloc] init] autorelease];
        // TODO: this is relying on the server returning "label" and "title"
        // for each field item, may not be robust
        itemTemplate.templateString = @"<li><strong>__label__: </strong>__title__</li>";
        self.info = [NSString stringWithFormat:@"<ul>%@</ul>", [itemTemplate stringWithMultiReplacements:descriptionInfo]];
    }
    
    CLLocationDegrees lat = [dictionary floatForKey:@"lat"];
    CLLocationDegrees lon = [dictionary floatForKey:@"lon"];
    if (lat || lon) {
        self.latitude = [NSNumber numberWithFloat:lat];
        self.longitude = [NSNumber numberWithFloat:lon];
    }
    
    self.photoURL = [dictionary nonemptyStringForKey:@"photo"];
    
    NSString *theGeometryType = [dictionary nonemptyStringForKey:@"geometryType"];
    if (theGeometryType) {
        self.geometryType = theGeometryType;
        if ([theGeometryType isEqualToString:@"point"]) {
            NSDictionary *theGeometry = [dictionary dictionaryForKey:@"geometry"];
            lat = [theGeometry floatForKey:@"lat"];
            lon = [theGeometry floatForKey:@"lon"];
            if (lat || lon) {
                CLLocation *location = [[[CLLocation alloc] initWithLatitude:lat longitude:lon] autorelease];
                self.geometry = [NSKeyedArchiver archivedDataWithRootObject:location];
            }
        } else {
            // TODO: other geometry types
        }
    }
}

+ (KGOPlacemark *)placemarkWithDictionary:(NSDictionary *)dictionary {
    NSString *theIdentifier = nil;
    id idObject = [dictionary objectForKey:@"id"];
    if ([idObject isKindOfClass:[NSString class]] || [idObject isKindOfClass:[NSNumber class]]) {
        theIdentifier = [idObject description];
    }
    CGFloat latitude = [dictionary floatForKey:@"lat"];
    CGFloat longitude = [dictionary floatForKey:@"lon"];
    
    KGOPlacemark *placemark = nil;
    if (theIdentifier && (latitude || longitude)) {
        placemark = [KGOPlacemark placemarkWithID:theIdentifier latitude:latitude longitude:longitude];
        [placemark updateWithDictionary:dictionary];
    }
    
    return placemark;
}

+ (KGOPlacemark *)placemarkWithID:(NSString *)placemarkID latitude:(CGFloat)latitude longitude:(CGFloat)longitude
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:
                         @"identifier like %@ and latitude = %@ and longitude = %@",
                         placemarkID, [NSNumber numberWithFloat:latitude], [NSNumber numberWithFloat:longitude]];

    KGOPlacemark *result = [[[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName
                                                            matchingPredicate:pred] lastObject];
    if (!result) {
        result = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOPlacemarkEntityName];
        result.identifier = placemarkID;
        result.latitude = [NSNumber numberWithFloat:latitude];
        result.longitude = [NSNumber numberWithFloat:longitude];
    }
    
    return result;
}


- (void)addCategoriesObject:(KGOPlacemark *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] addObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCategoriesObject:(KGOPlacemark *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] removeObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] unionSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeCategories:(NSSet *)value {
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] minusSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
