#import "CalendarConstants.h"

NSString * const CalendarStateEventList = @"events";
NSString * const CalendarStateCategoryList = @"categories";
NSString * const CalendarStateCategoryEventList = @"category";
//NSString * const CalendarStateSearchHome = @"search";
//NSString * const CalendarStateSearchResults = @"results";
NSString * const CalendarStateEventDetail = @"detail";

@implementation CalendarConstants

#pragma mark Event list types (scroller buttons)

NSString * const CalendarEventTitleEvents = @"Events";
NSString * const CalendarEventTitleExhibits = @"Exhibits";
NSString * const CalendarEventTitleAcademic = @"Academic Calendar";
NSString * const CalendarEventTitleHoliday = @"Holidays";
NSString * const CalendarEventTitleCategory = @"Categories";

+ (NSString *)titleForEventType:(CalendarEventListType)listType
{
	switch (listType) {
		case CalendarEventListTypeEvents:
			return CalendarEventTitleEvents;
		case CalendarEventListTypeExhibits:
			return CalendarEventTitleExhibits;
		case CalendarEventListTypeAcademic:
			return CalendarEventTitleAcademic;
		case CalendarEventListTypeHoliday:
			return CalendarEventTitleHoliday;
		case CalendarEventListTypeCategory:
			return CalendarEventTitleCategory;
		default:
			return nil;
	}
}

#pragma mark Parameters for querying server

NSString * const CalendarEventAPIDay = @"day";
NSString * const CalendarEventAPIAcademic = @"academic";
NSString * const CalendarEventAPIHoliday = @"holidays";
NSString * const CalendarEventAPICategory = @"categories";
NSString * const CalendarEventAPISearch = @"search";

+ (NSString *)apiCommandForEventType:(CalendarEventListType)listType
{
	switch (listType) {
		case CalendarEventListTypeEvents:
			return CalendarEventAPIDay;
		case CalendarEventListTypeExhibits:
			return CalendarEventAPIDay;
		case CalendarEventListTypeAcademic:
			return CalendarEventAPIAcademic;
		case CalendarEventListTypeHoliday:
			return CalendarEventAPIHoliday;
		case CalendarEventListTypeCategory:
			return CalendarEventAPICategory;
		default:
			return nil;
	}
}

+ (NSString *)dateStringForEventType:(CalendarEventListType)listType forDate:(NSDate *)aDate
{
	NSDate *now = [NSDate date];	
	if ((listType == CalendarEventListTypeEvents
         || listType == CalendarEventListTypeExhibits)
		&& [now compare:aDate] != NSOrderedAscending
		&& [now timeIntervalSinceDate:aDate] < [CalendarConstants intervalForEventType:listType fromDate:aDate forward:YES]) {
		return @"Today";
	}

	NSString *dateString = nil;
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	if (listType == CalendarEventListTypeAcademic) {
		[df setDateFormat:@"yyyy"];
		
	} else {
		//[df setDateStyle:kCFDateFormatterMediumStyle];
		//[df setDateFormat:@"EEEE, MMM. dd"];
		[df setDateFormat:@"EEEE M/dd"];
	}
	
	dateString = [df stringFromDate:aDate];
	[df release];
	
	int nextYearDate = [dateString intValue] + 1;
	
	if (listType == CalendarEventListTypeAcademic) 
		dateString = [[NSString alloc] initWithFormat:@"%@-%i", dateString, nextYearDate];
	
	return dateString;
}

+ (NSTimeInterval)intervalForEventType:(CalendarEventListType)listType fromDate:(NSDate *)aDate forward:(BOOL)forward
{
	NSInteger sign = forward ? 1 : -1;
	switch (listType) {
		//case CalendarEventListTypeExhibits:
		//	return 86400.0 * 7.0 * sign;
		case CalendarEventListTypeAcademic:
		{
			//NSLog(@"%@", [aDate description]);
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDateComponents *comps = [[NSDateComponents alloc] init];
			//[comps setMonth:sign];
			[comps setYear:sign];
			NSDate *targetDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
			[comps release];
			return [targetDate timeIntervalSinceDate:aDate];
		}
		case CalendarEventListTypeHoliday:
			// haven't decided what is reasonable here, just using a large number of days
			return 86400.0 * 180;
		//case CalendarEventListTypeCategory:
		case CalendarEventListTypeEvents:
		default:
			return 86400.0 * sign;
	}
}

@end
