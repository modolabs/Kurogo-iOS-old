#import <Foundation/Foundation.h>
#import "CalendarModel.h"
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
    
    NSDictionary *_dateFormatters;
    
}

@property (nonatomic, assign) id<CalendarDataManagerDelegate> delegate;
@property (nonatomic, readonly) KGOCalendarGroup *currentGroup;
@property (nonatomic, retain) NSString *moduleTag;

- (BOOL)requestGroups;
- (BOOL)requestCalendarsForGroup:(KGOCalendarGroup *)group;

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar params:(NSDictionary *)params;
- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar time:(NSDate *)time;

- (void)selectGroupAtIndex:(NSInteger)index;

- (NSString *)mediumDateStringFromDate:(NSDate *)date;
- (NSString *)shortTimeStringFromDate:(NSDate *)date;
- (NSString *)shortDateTimeStringFromDate:(NSDate *)date;

@end
