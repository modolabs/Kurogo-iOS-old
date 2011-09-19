//
//  Video.h
//  Universitas
//

#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"
#import "MITThumbnailView.h"

@interface Video :  NSManagedObject <KGOSearchResult, MITThumbnailDelegate>
{
}

@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSString * videoDescription;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * thumbnailURLString;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSSet* tags;
@property (nonatomic, retain) NSString * mobileURL;
@property (nonatomic, retain) NSString * stillFrameImageURLString;
@property (nonatomic, retain) NSData * stillFrameImageData;
@property (nonatomic, retain) NSData * thumbnailImageData;
@property (nonatomic, retain) NSData * streamingURL;
@property (nonatomic, retain) NSData * publishedTimeStamp;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSNumber *bookmarked;
@property (nonatomic, retain) NSNumber * sortOrder;
// source can be "search" or the name of a section.
@property (nonatomic, retain) NSString * source;

@property (nonatomic, retain) NSString *moduleTag;

+ (Video *)videoWithID:(NSString *)identifier;
+ (Video *)videoWithDictionary:(NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

- (NSString *)durationString;
/*
- (BOOL)isBookmarked;
- (void)addBookmark;
- (void)removeBookmark;
*/
@end


@interface Video (CoreDataGeneratedAccessors)
- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)value;
- (void)removeTags:(NSSet *)value;

@end

