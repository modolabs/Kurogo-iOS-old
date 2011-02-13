#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOEventAttendee;
@class KGOEventCategory;

@interface KGOEvent :  NSManagedObject <KGOSearchResult>
{
}

@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * rrule;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * shortloc;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) NSSet* attendees;
@property (nonatomic, retain) NSSet* contacts;

@end


@interface KGOEvent (CoreDataGeneratedAccessors)
- (void)addCategoriesObject:(KGOEventCategory *)value;
- (void)removeCategoriesObject:(KGOEventCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

- (void)addAttendeesObject:(KGOEventAttendee *)value;
- (void)removeAttendeesObject:(KGOEventAttendee *)value;
- (void)addAttendees:(NSSet *)value;
- (void)removeAttendees:(NSSet *)value;

- (void)addContactsObject:(NSManagedObject *)value;
- (void)removeContactsObject:(NSManagedObject *)value;
- (void)addContacts:(NSSet *)value;
- (void)removeContacts:(NSSet *)value;

@end

