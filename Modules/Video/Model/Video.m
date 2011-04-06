// 
//  Video.m
//  Universitas
//

#import "Video.h"

#pragma mark Private methods

@interface Video (Private)

+ (NSDate *)dateFromPublishedDictionary:(NSDictionary *)dictionary;
+ (NSSet *)tagsFromTagsDictionary:(NSDictionary *)dictionary;

@end

@implementation Video (Private)

+ (NSDate *)dateFromPublishedDictionary:(NSDictionary *)dictionary {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // TODO: Do something with time zone.
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:[dictionary valueForKey:@"date"]];
    [dateFormatter release];
    return date;
}

+ (NSSet *)tagsFromTagsDictionary:(NSDictionary *)dictionary {
    // TODO.
    return nil;
}

@end

@implementation Video 

@dynamic videoID;
@dynamic videoDescription;
@dynamic author;
@dynamic published;
@dynamic width;
@dynamic url;
@dynamic type;
@dynamic title;
@dynamic imageURLString;
@dynamic height;
@dynamic duration;
@dynamic tags;
@dynamic mobileURL;
@dynamic stillFrameImage;

    
- (void)setUpWithDictionary:(NSDictionary *)dictionaryFromAPI {
    static NSDictionary *objectKeyCounterpartsForAPIKeys = nil;
    
    if (!objectKeyCounterpartsForAPIKeys) {
        objectKeyCounterpartsForAPIKeys = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         @"videoID", @"id",
         @"videoDescription", @"description",
         @"imageURLString", @"image",
         nil];
    }
    
    for (NSString *APIKey in dictionaryFromAPI) {
        NSString *keyToSet = [objectKeyCounterpartsForAPIKeys objectForKey:APIKey];
        if (!keyToSet) {
            keyToSet = APIKey;
        }
        if ([keyToSet isEqualToString:@"published"]) {
            self.published = [[self class] dateFromPublishedDictionary:
                              [dictionaryFromAPI objectForKey:APIKey]];
        }
        else if ([keyToSet isEqualToString:@"tags"]) {
            self.tags = [[self class] tagsFromTagsDictionary:
                         [dictionaryFromAPI objectForKey:APIKey]];
        }
        else {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ((value) && (![value isKindOfClass:[NSNull class]])) {
                [self setValue:[dictionaryFromAPI valueForKey:APIKey] 
                        forKey:keyToSet];
            }
        }
    }        
}

@end
