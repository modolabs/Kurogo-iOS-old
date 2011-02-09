#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "JSONAPIRequest.h"
#import "CalendarEventMapAnnotation.h"
#import "MITCalendarEvent.h"
#import <MapKit/MapKit.h>


@implementation CalendarModule

@synthesize request, searchSpan;

- (void)dealloc {
    [super dealloc];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
    _searchDelegate = delegate;
    
    self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.request requestObjectFromModule:@"calendar"
                                  command:@"search"
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"Calendar"];
}

#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result
{	
    self.request = nil;
    
    NSArray *resultEvents = [result objectForKey:@"events"];
    NSMutableArray *arrayForTable;
    
    if ([resultEvents isKindOfClass:[NSDictionary class]]) {
        //self.searchSpan = [result objectForKey:@"span"];
        arrayForTable = [NSMutableArray arrayWithCapacity:[resultEvents count]];
        
        for (NSDictionary *eventDict in resultEvents) {
            MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
            [arrayForTable addObject:event];
        }
        
        //self.searchResults = arrayForTable;
    }
}

- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress {

}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {

}

@end

