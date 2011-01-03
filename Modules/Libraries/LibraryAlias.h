#import <CoreData/CoreData.h>

@class Library;

@interface LibraryAlias :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Library * library;

@end



