#import "KGOPlacemark.h"
#import "KGOMapCategory.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import <CoreLocation/CoreLocation.h>

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
@dynamic category;

#pragma mark KGOSearchResult, MKAnnotation

- (NSString *)subtitle {
    return self.street;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude floatValue], [self.longitude floatValue]);
}

#pragma mark -

+ (KGOPlacemark *)placemarkWithDictionary:(NSDictionary *)dictionary {
    NSArray *categoryPath = [dictionary arrayForKey:@"category"];
    NSString *theIdentifier = nil;
    id idObject = [dictionary objectForKey:@"id"];
    if ([idObject isKindOfClass:[NSString class]] || [idObject isKindOfClass:[NSNumber class]]) {
        theIdentifier = [idObject description];
    }
    NSLog(@"%@ %@", theIdentifier, categoryPath);
    
    KGOPlacemark *placemark = nil;
    if (categoryPath && theIdentifier) {
        KGOMapCategory *category = [KGOMapCategory categoryWithPath:categoryPath];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", theIdentifier];
        placemark = [[category.places filteredSetUsingPredicate:pred] anyObject];
        if (!placemark) {
            placemark = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOPlacemarkEntityName];
            placemark.identifier = theIdentifier;
            placemark.category = category;
        }
        
        placemark.title = [dictionary stringForKey:@"title" nilIfEmpty:YES];
        placemark.info = [dictionary stringForKey:@"description" nilIfEmpty:YES];
        
        CLLocationDegrees lat = [dictionary floatForKey:@"lat"];
        CLLocationDegrees lon = [dictionary floatForKey:@"lon"];
        if (lat || lon) {
            placemark.latitude = [NSNumber numberWithFloat:[dictionary floatForKey:@"lat"]];
            placemark.longitude = [NSNumber numberWithFloat:[dictionary floatForKey:@"lon"]];
        }

        NSString *theGeometryType = [dictionary stringForKey:@"geometryType" nilIfEmpty:YES];
        if (theGeometryType) {
            placemark.geometryType = theGeometryType;
            if ([theGeometryType isEqualToString:@"point"]) {
                NSDictionary *theGeometry = [dictionary dictionaryForKey:@"geometry"];
                lat = [theGeometry floatForKey:@"lat"];
                lon = [theGeometry floatForKey:@"lon"];
                if (lat || lon) {
                    CLLocation *location = [[[CLLocation alloc] initWithLatitude:lat longitude:lon] autorelease];
                    placemark.geometry = [NSKeyedArchiver archivedDataWithRootObject:location];
                }
            } else {
                // TODO: other geometry types
            }
        }
    }
    
    return placemark;
}


@end
