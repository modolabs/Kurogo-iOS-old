#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class NewsImage;

@interface NewsStory : NSManagedObject <KGOSearchResult> {
@private
}
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSNumber * hasBody;
@property (nonatomic, retain) NSString * identifier;
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
