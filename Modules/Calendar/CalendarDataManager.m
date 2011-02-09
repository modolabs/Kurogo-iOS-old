#import "CalendarDataManager.h"
#import "Constants.h"
#import "CoreDataManager.h"

@implementation CalendarDataManager

+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(CalendarEventListType)listType category:(NSNumber *)catID
{
	// search from beginning of the day
    // or for academic calendar, beginning of the month
	NSUInteger unitFlags = (listType == CalendarEventListTypeAcademic)
        ? (NSYearCalendarUnit | NSMonthCalendarUnit)
        : (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    
	NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:startDate];
	startDate = [[NSCalendar currentCalendar] dateFromComponents:components];
	
	NSTimeInterval interval = [CalendarConstants intervalForEventType:listType
															 fromDate:startDate
															  forward:YES];
	NSDate *endDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:startDate];

    NSPredicate *pred = nil;
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *events = nil;
    if (listType == CalendarEventListTypeEvents && catID == nil) {
        pred = [NSPredicate predicateWithFormat:@"(start >= %@) and (start < %@) and (isRegular == YES)", startDate, endDate];
        events = [[CoreDataManager sharedManager] objectsForEntity:CalendarEventEntityName matchingPredicate:pred sortDescriptors:[NSArray arrayWithObject:sort]];
    } else {
        pred = [NSPredicate predicateWithFormat:@"(start >= %@) and (start < %@)", startDate, endDate];
        EventCategory *category = nil;
        switch (listType) {
            case CalendarEventListTypeEvents:
                category = [CalendarDataManager categoryWithID:[catID intValue]];
                break;
            case CalendarEventListTypeExhibits:
                category = [CalendarDataManager categoryWithID:kCalendarExhibitCategoryID];
                break;
            case CalendarEventListTypeAcademic:
                category = [CalendarDataManager categoryWithID:kCalendarAcademicCategoryID];
                break;
            case CalendarEventListTypeHoliday:
                category = [CalendarDataManager categoryWithID:kCalendarHolidayCategoryID];
                break;
            default:
                break;
        }
        
        // there are so few holidays that we won't filter out ones that have passed
        NSSet *eventSet;
        if (listType != CalendarEventListTypeHoliday) {
            eventSet = [[category events] filteredSetUsingPredicate:pred];
        } else {
            eventSet = [category events];
        }
        events = [[eventSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    [sort release];
	[endDate release];
    return events;
}

+ (NSNumber *)idForCategory:(NSString *)categoryName
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"title contains %@", categoryName];
	EventCategory *category = [[[CoreDataManager sharedManager] objectsForEntity:CalendarCategoryEntityName
                                                               matchingPredicate:pred] lastObject];
	return category.catID;
}

+ (NSArray *)topLevelCategories
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	NSSet *categories = [[CoreDataManager sharedManager] objectsForEntity:CalendarCategoryEntityName
                                                        matchingPredicate:pred
                                                          sortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	for (EventCategory *category in categories) {
		if (category.parentCategory == category) {
			[result addObject:category];
		}
	}

	if ([result count] > 0) {
		return result;
	}
	
	return nil;
}

+ (EventCategory *)categoryWithID:(NSInteger)catID
{	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"catID == %d", catID];
	EventCategory *category = [[[CoreDataManager sharedManager] objectsForEntity:CalendarCategoryEntityName
                                                               matchingPredicate:pred] lastObject];
	if (!category) {
        category = (EventCategory *)[[CoreDataManager sharedManager] insertNewObjectForEntityForName:CalendarCategoryEntityName];
		category.catID = [NSNumber numberWithInt:catID];
        if (catID == kCalendarAcademicCategoryID) {
            category.title = [CalendarConstants titleForEventType:CalendarEventListTypeAcademic];
        } else if (catID == kCalendarHolidayCategoryID) {
            category.title = [CalendarConstants titleForEventType:CalendarEventListTypeHoliday];
        } else if (catID == kCalendarExhibitCategoryID) {
            category.title = [CalendarConstants titleForEventType:CalendarEventListTypeExhibits];
        }
        [[CoreDataManager sharedManager] saveData];
	} else {
        DLog(@"%@", [[category.events allObjects] description]);
    }
	return category;
}

+ (EventCategory *)categoryWithDict:(NSDictionary *)dict
{
    // whatever real ID is assigned to exhibits, override it with our own
	NSInteger catID = [[dict objectForKey:@"name"] isEqualToString:@"exhibits"]
        ? kCalendarExhibitCategoryID
        : [[dict objectForKey:@"catid"] intValue];
	EventCategory *category = [CalendarDataManager categoryWithID:catID];
	[category updateWithDict:dict];
	return category;
}

+ (MITCalendarEvent *)eventWithID:(NSInteger)eventID
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"eventID == %d", eventID];
	MITCalendarEvent *event = [[[CoreDataManager sharedManager] objectsForEntity:CalendarEventEntityName
                                                               matchingPredicate:pred] lastObject];
	if (!event) {
		event = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:CalendarEventEntityName];
		event.eventID = [NSNumber numberWithInt:eventID];
	}
	return event;
}

+ (MITCalendarEvent *)eventWithDict:(NSDictionary *)dict
{
    // TODO: clean up things that are not related to the "soap server"
	// purge rogue categories that the soap server doesn't return
	// from the "categories" api call but show up in events
	if ([[[CoreDataManager sharedManager] managedObjectContext] hasChanges]) {
		[[[CoreDataManager sharedManager] managedObjectContext] undo];
		[[[CoreDataManager sharedManager] managedObjectContext] rollback];
	}

	NSInteger eventID = [[dict objectForKey:@"id"] intValue];
	MITCalendarEvent *event = [CalendarDataManager eventWithID:eventID];	
	[event updateWithDict:dict];
	return event;
}

+ (void)pruneOldEvents
{
    NSDate *freshDate = [[NSDate alloc] initWithTimeInterval:-kCalendarEventTimeoutSeconds
                                                   sinceDate:[NSDate date]];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(lastUpdated < %@)", freshDate];
    NSArray *events = [[CoreDataManager sharedManager] objectsForEntity:CalendarEventEntityName matchingPredicate:pred];
    if ([events count]) {
        [[CoreDataManager sharedManager] deleteObjects:events];
        [[CoreDataManager sharedManager] saveData];
    }
    [freshDate release];
}

@end
