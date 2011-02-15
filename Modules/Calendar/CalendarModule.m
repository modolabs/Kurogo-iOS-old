#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "JSONAPIRequest.h"
#import "CalendarModel.h"


@implementation CalendarModule

@synthesize request;

- (void)dealloc {
	self.request = nil;
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

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail,
            LocalPathPageNameCategoryList, LocalPathPageNameItemList, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[CalendarEventsViewController alloc] init] autorelease];
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [[[CalendarEventsViewController alloc] init] autorelease];
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(CalendarEventsViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        KGOEvent *event = [params objectForKey:@"event"];
        if (event) {
            vc = [[[CalendarDetailViewController alloc] init] autorelease];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
    }
    return vc;
}

#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result
{	
    self.request = nil;
    
    NSArray *resultEvents = [result objectForKey:@"events"];
    NSMutableArray *arrayForTable;
    
    if ([resultEvents isKindOfClass:[NSArray class]]) {
        arrayForTable = [NSMutableArray arrayWithCapacity:[resultEvents count]];
        
        for (NSDictionary *eventDict in resultEvents) {
            KGOEvent *event = [CalendarDataManager eventWithDict:eventDict];
            [arrayForTable addObject:event];
        }
    }
    
    [_searchDelegate searcher:self didReceiveResults:arrayForTable];
}

- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress {

}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {

}

@end

