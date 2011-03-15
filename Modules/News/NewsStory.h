#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NewsImage;

@interface NewsStory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSString * story_id;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSDate * postDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * topStory;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSNumber * searchResult;
@property (nonatomic, retain) NSNumber * bookmarked;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) NewsImage * thumbImage;
@property (nonatomic, retain) NewsImage * featuredImage;

@end
