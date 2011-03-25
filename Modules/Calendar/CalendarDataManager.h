#import <Foundation/Foundation.h>
#import "CalendarModel.h"
#import "CalendarConstants.h"
#import "KGORequestManager.h"

@protocol CalendarDataManagerDelegate <NSObject>

- (void)groupsDidChange:(NSArray *)groups;
- (void)groupDataDidChange:(KGOCalendarGroup *)group;
- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar;

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

- (BOOL)requestGroups;
//- (BOOL)requestCalendarsForGroup:(NSString *)group;
- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar time:(NSDate *)time;

- (void)selectGroupAtIndex:(NSInteger)index;

@end
