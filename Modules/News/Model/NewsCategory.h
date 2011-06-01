#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NewsStory;

@interface NewsCategory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSNumber * nextSeekId;
@property (nonatomic, retain) NSString * category_id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) NSNumber * isMainCategory;
@property (nonatomic, retain) NSNumber * moreStories;
@property (nonatomic, retain) NSSet* stories;

@end
