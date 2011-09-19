#import "Video.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"

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
@dynamic sortOrder;
@dynamic bookmarked;

@synthesize moduleTag;

- (void)dealloc {

    [super dealloc];
}

+ (Video *)videoWithID:(NSString *)identifier
{
    Video *video = [[CoreDataManager sharedManager] uniqueObjectForEntity:@"Video"
                                                                attribute:@"videoID"
                                                                    value:identifier];
    if (!video) {
        video = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"Video"];
        video.videoID = identifier;
    }
    return video;
}

+ (Video *)videoWithDictionary:(NSDictionary *)dictionary
{
    Video *result = nil;
    NSString *videoID = [dictionary nonemptyForcedStringForKey:@"id"];
    if (videoID) {
        result = [Video videoWithID:videoID];
        [result updateWithDictionary:dictionary];
    }
    return result;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    self.title = [dictionary stringForKey:@"title"];
    self.author = [dictionary stringForKey:@"author"];
    self.stillFrameImageURLString = [dictionary nonemptyStringForKey:@"stillFrameImage"];
    self.thumbnailURLString = [dictionary nonemptyStringForKey:@"image"];
    self.duration = [dictionary numberForKey:@"duration"];
    self.videoDescription = [dictionary nonemptyStringForKey:@"description"];
    self.url = [dictionary nonemptyStringForKey:@"url"];
    NSDictionary *dateDict = [dictionary dictionaryForKey:@"published"];
    if (dateDict) {
        self.published = [Video dateFromPublishedDictionary:dateDict];
    }
    NSDictionary *tagsDict = [dictionary dictionaryForKey:@"tags"];
    if (tagsDict) {
        self.tags = [Video tagsFromTagsDictionary:tagsDict];
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    self.thumbnailImageData = data;
}

#pragma mark - KGOSearchResult

- (NSString *)identifier
{
    return self.videoID;
}

- (NSString *)subtitle
{
    return [NSString stringWithFormat:@"(%@) %@", [self durationString], self.videoDescription];
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

- (BOOL)isBookmarked {
    return [self.bookmarked boolValue];
}

- (void)addBookmark {
    if (![self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:YES];
    }
}

- (void)removeBookmark {
    if ([self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:NO];
    }
}

- (BOOL)didGetSelected:(id)selector
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self, @"video",
                            self.source, @"section",
                            nil];
    return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail
                                  forModuleTag:self.moduleTag
                                        params:params];
}


@end
