#import "FacebookPhoto.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "FacebookModule.h"
#import "FacebookUser.h"
#import "FacebookComment.h"

NSString * const FacebookPhotoEntityName = @"FacebookPhoto";

@implementation FacebookPhoto
@dynamic src;
@dynamic data;
@dynamic width;
@dynamic title;
@dynamic height;
@dynamic thumbData;

@synthesize thumbSrc = _thumbSrc;

+ (FacebookPhoto *)photoWithDictionary:(NSDictionary *)dictionary {
    
    FacebookPhoto *photo = nil;
    id identifier = [dictionary objectForKey:@"object_id"];
    if (!identifier) {
        identifier = [dictionary objectForKey:@"id"];
    }
    // not sure yet if this is a string or number or if anything else is possible
    NSLog(@"object_id is %@ of type %@", identifier, [[identifier class] description]);
    
    if (identifier) {
        identifier = [NSString stringWithFormat:@"%@", identifier];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
        photo = [[[CoreDataManager sharedManager] objectsForEntity:FacebookPhotoEntityName matchingPredicate:pred] lastObject];
        if (!photo) {
            photo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookPhotoEntityName];
            photo.identifier = identifier;
            
            // TODO: figure out whether these attributes of photos ever change -- 
            // if so we need to put these lines outside the enclosing if statement
            photo.src = [dictionary stringForKey:@"source" nilIfEmpty:YES]; // from Graph API
            if (!photo.src) {
                photo.src = [dictionary objectForKey:@"src"]; // from FQL
            }
            
            CGFloat width = [dictionary floatForKey:@"width"]; // graph
            if (!width) {
                width = [[dictionary objectForKey:@"src_width"] floatValue]; // fql
            }
            if (width) {
                photo.width = [NSNumber numberWithFloat:width];
            }
            
            CGFloat height = [dictionary floatForKey:@"height"]; // graph
            if (!height) {
                height = [[dictionary objectForKey:@"src_height"] floatValue]; // fql
            }
            if (height) {
                photo.height = [NSNumber numberWithFloat:height];
            }
            
            // TODO: decide if we're using created_time (created) or updated_time (modified)
            NSString *createdTime = [dictionary stringForKey:@"created_time" nilIfEmpty:YES]; // graph
            if (!createdTime) {
                createdTime = [dictionary stringForKey:@"created" nilIfEmpty:YES];
            }
            if (createdTime) {
                // graph API returns RFC3339 strings
                NSDate *date = [FacebookModule dateFromRFC3339DateTimeString:createdTime];
                if (date) {
                    photo.date = date;
                }
            }
        }
        
        // attributes that might change
        NSString *theTitle = [dictionary stringForKey:@"name" nilIfEmpty:YES]; // graph
        if (!theTitle) {
            theTitle = [dictionary stringForKey:@"caption" nilIfEmpty:YES]; // fql
        }
        if (![theTitle isEqualToString:photo.title]) {
            photo.title = theTitle;
        }
        
        NSString *owner = [dictionary objectForKey:@"owner"]; // fql
        NSDictionary *ownerDict = nil; // graph
        if (!owner) {
            ownerDict = [dictionary dictionaryForKey:@"from"];
            // TODO: remove this line which is just for type debugging
            owner = [ownerDict objectForKey:@"id"];
        }
        NSLog(@"owner is %@ of type %@", owner, [[owner class] description]);
        
        if (ownerDict) {
            photo.owner = [FacebookUser userWithDictionary:ownerDict];
        } else if (owner) {
            owner = [NSString stringWithFormat:@"%@", owner];
            photo.owner = [FacebookUser userWithID:owner];
        }
        
        if (!photo.thumbData) {
            photo.thumbSrc = [dictionary stringForKey:@"src_small" nilIfEmpty:YES]; // fql
            if (!photo.thumbSrc) {
                // TODO: don't assume images are always sorted in descending size
                NSDictionary *smallImage = [[dictionary arrayForKey:@"images"] lastObject];
                photo.thumbSrc = [smallImage stringForKey:@"source" nilIfEmpty:YES];
            }
        }
        
        NSDictionary *comments = [dictionary dictionaryForKey:@"comments"];
        if (comments) {
            NSArray *commentData = [comments arrayForKey:@"data"];
            for (NSDictionary *commentDict in commentData) {
                FacebookComment *aComment = [FacebookComment commentWithDictionary:commentDict];
                aComment.parent = photo;
            }
        }
    }
    
    return photo;
}

@end
