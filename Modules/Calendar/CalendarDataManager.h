#import <Foundation/Foundation.h>
#import "CalendarModel.h"
#import "CalendarConstants.h"
#import "KGORequestManager.h"

@protocol CalendarDataManagerDelegate <NSObject>

- (void)groupsDidChange:(NSArray *)groups;
- (void)categoriesDidChange:(NSArray *)categories;
- (void)eventsDidChange:(NSArray *)events category:(NSString *)category;

@end

@class KGOCalendarGroup;

@interface CalendarDataManager : NSObject <KGORequestDelegate> {
    
    KGOCalendarGroup *_currentGroup;
    
    KGORequest *_groupsRequest;
    NSMutableDictionary *_categoriesRequests;
    NSMutableDictionary *_eventsRequests;
    
}

@property (nonatomic, assign) id<CalendarDataManagerDelegate> delegate;
@property (nonatomic, readonly) KGOCalendarGroup *currentGroup;

- (void)requestGroups;
- (void)requestCategoriesForGroup:(NSString *)group;
- (void)requestEventsForCategory:(NSString *)category startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (void)selectGroupAtIndex:(NSInteger)index;

/*

+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(CalendarEventListType)listType category:(NSNumber *)catID;
+ (NSNumber *)idForCategory:(NSString *)categoryName;

+ (NSArray *)topLevelCategories;
+ (KGOEventCategory *)categoryWithID:(NSInteger)catID;
+ (KGOEvent *)eventWithID:(NSInteger)eventID;
+ (KGOEvent *)eventWithDict:(NSDictionary *)dict;
+ (KGOEventCategory *)categoryWithDict:(NSDictionary *)dict;
+ (void)pruneOldEvents;
*/
@end
