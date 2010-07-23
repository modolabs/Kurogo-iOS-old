#import <CoreData/CoreData.h>

@class NewsStory;

@interface NewsImage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * ordinality;
@property (nonatomic, retain) NSString * credits;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NewsStory * thumbParent;
@property (nonatomic, retain) NewsStory * featuredParent;

@end



