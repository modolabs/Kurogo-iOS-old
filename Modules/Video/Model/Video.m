// 
//  Video.m
//  Universitas
//

#import "Video.h"

#pragma mark Private methods

@interface Video (Private)

+ (NSDate *)dateFromPublishedDictionary:(NSDictionary *)dictionary;
+ (NSSet *)tagsFromTagsDictionary:(NSDictionary *)dictionary;
- (void)setUpTranslationDictionary;

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

- (void)setUpTranslationDictionary {
    self.objectKeyCounterpartsForAPIKeys = 
    [NSDictionary dictionaryWithObjectsAndKeys:
     @"videoID", @"id",
     @"videoDescription", @"description",
     @"thumbnailURLString", @"image",
     @"stillFrameImageURLString", @"stillFrameImage",
     nil];
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
@dynamic thumbnailURLString;
@dynamic height;
@dynamic duration;
@dynamic tags;
@dynamic mobileURL;
@dynamic stillFrameImageURLString;
@dynamic stillFrameImageData;
@dynamic thumbnailImageData;
@dynamic source;
@dynamic streamingURL;
@dynamic publishedTimeStamp;
@dynamic date;

@synthesize objectKeyCounterpartsForAPIKeys;

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        [self setUpTranslationDictionary];
    }
    return self;
}

- (void)dealloc {
    [objectKeyCounterpartsForAPIKeys release];

    [super dealloc];
}


- (void)setUpWithDictionary:(NSDictionary *)dictionaryFromAPI {
    
    for (NSString *APIKey in dictionaryFromAPI) {
        NSString *keyToSet = [self.objectKeyCounterpartsForAPIKeys objectForKey:APIKey];
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
        else if ([keyToSet isEqualToString:@"streamingURL"]) {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ([value isKindOfClass:[NSString class]]) {
                self.streamingURL = value;
            }
        }
        else if ([keyToSet isEqualToString:@"publishedTimeStamp"]) {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ([value isKindOfClass:[NSString class]]) {
                self.publishedTimeStamp = value;
            }
        }
        else if ([keyToSet isEqualToString:@"date"]) {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ([value isKindOfClass:[NSString class]]) {
                self.date = value;
            }
        }
        
        else if ([keyToSet isEqualToString:@"videoID"]) {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ([value isKindOfClass:[NSString class]]) {
                self.videoID = value;
            }
            else if ([value isKindOfClass:[NSNumber class]]) {
                self.videoID = [value stringValue];
            }
            else {
                NSAssert(NO, @"Trying to set videoID to a value with an invalid type.");
            }
        }
        else {
            id value = [dictionaryFromAPI valueForKey:APIKey];
            if ((value) && (![value isKindOfClass:[NSNull class]])) { 
                if (![keyToSet isEqualToString:@"date"]){
                    [self setValue:[dictionaryFromAPI valueForKey:APIKey] forKey:keyToSet];
                }
                
            }
        }
    }        
}

- (NSString *)durationString {
    NSInteger rawDuration = [self.duration intValue];
    NSInteger totalMinutes = rawDuration / 60;
    NSInteger displaySeconds = rawDuration - (totalMinutes * 60);
    NSInteger displayHours = totalMinutes / 60;
    NSInteger displayMinutes = totalMinutes - (displayHours * 60);
    NSString *durationString = [NSString stringWithFormat:@"%02d:%02d", 
                                displayMinutes, displaySeconds];
    if (displayHours > 0) {
        durationString = [NSString stringWithFormat:@"%2d:%@", 
                          displayHours, durationString];
    }
    return durationString;
}

@end
