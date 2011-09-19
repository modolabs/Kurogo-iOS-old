#import "CalendarModule.h"
#import "CalendarHomeViewController.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "CalendarModel.h"

NSString * const KGODataModelNameCalendar = @"Calendar";

@implementation CalendarModule

@synthesize request = _request, dataManager;

- (void)dealloc {
	self.request = nil;
    [super dealloc];
    
}

- (NSString *)defaultCalendar {
    return nil; // TODO
}

- (void)willLaunch
{
    if (!self.dataManager) {
        self.dataManager = [[[CalendarDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = self.tag;
    }
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate {
    self.searchDelegate = delegate;
    
    //NSString *calendar = [self defaultCalendar];
    
    //Start and end dates for the Calendar Search
    NSDate *currentDate = [NSDate date];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:604800];//# of seconds in a 7 day period
    NSString *startDateString = [NSString stringWithFormat:@"%.0f", [currentDate timeIntervalSince1970]];
    NSString *endDateString = [NSString stringWithFormat:@"%.0f", [endDate timeIntervalSince1970]];
    
    params = [NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", 
                                                        startDateString, @"start", 
                                                        endDateString, @"end", nil];


    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.tag path:@"search" params:params];
    [self.request connect];
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:KGODataModelNameCalendar];
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail,
            LocalPathPageNameCategoryList, LocalPathPageNameItemList, nil];
}


- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]
        || [pageName isEqualToString:LocalPathPageNameSearch]
        || [pageName isEqualToString:LocalPathPageNameCategoryList]
    ) {
        CalendarHomeViewController *calendarVC = [[[CalendarHomeViewController alloc] initWithNibName:@"CalendarHomeViewController"
                                                                                               bundle:nil] autorelease];
        calendarVC.moduleTag = self.tag;
        calendarVC.showsGroups = ![pageName isEqualToString:LocalPathPageNameCategoryList];
        
        calendarVC.dataManager = self.dataManager;
        // TODO: we might not need to set the following as long as viewWillAppear is properly invoked
        self.dataManager.delegate = calendarVC;

        // requested search path
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [calendarVC setSearchTerms:searchText];
        }

        // requested category path
        KGOCalendar *calendar = [params objectForKey:@"calendar"];
        if (calendar) {
            calendarVC.currentCalendar = calendar;
            calendarVC.title = calendar.title;
        } else {
            calendarVC.title = NSLocalizedString(@"Events", nil);
        }

        vc = calendarVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        CalendarDetailViewController *detailVC = [[[CalendarDetailViewController alloc] init] autorelease];
        detailVC.indexPath = [params objectForKey:@"currentIndexPath"];
        detailVC.eventsBySection = [params objectForKey:@"eventsBySection"];
        detailVC.sections = [params objectForKey:@"sections"];
        detailVC.searchResult = [params objectForKey:@"searchResult"];
        detailVC.dataManager = self.dataManager;
        vc = detailVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
    }
    return vc;
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    NSArray *resultArray = [result arrayForKey:@"results"];
    NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
    for (id aResult in resultArray) {
        DLog(@"%@", [aResult description]);
        KGOEventWrapper *anEvent = [[[KGOEventWrapper alloc] initWithDictionary:aResult] autorelease];
        anEvent.moduleTag = self.tag;
        [searchResults addObject:anEvent];
    }
    [self.searchDelegate receivedSearchResults:searchResults forSource:self.shortName];
}


@end

