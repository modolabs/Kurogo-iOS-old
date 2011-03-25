#import "CalendarModule.h"
#import "CalendarHomeViewController.h"
#import "CalendarConstants.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "CalendarModel.h"

NSString * const KGODataModelNameCalendar = @"Calendar";

@implementation CalendarModule

@synthesize request = _request;

- (void)dealloc {
	self.request = nil;
    [super dealloc];
}

- (NSString *)defaultCalendar {
    return nil; // TODO
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
    //_searchDelegate = delegate;
    
    NSString *calendar = [self defaultCalendar];
    if (![params objectForKey:@"calendar"] && calendar) {
        NSMutableDictionary *mutableDict = [[params mutableCopy] autorelease];
        [mutableDict setObject:calendar forKey:@"calendar"];
        params = mutableDict;
    }

    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"calendar" path:@"search" params:params];
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
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[CalendarHomeViewController alloc] initWithNibName:@"CalendarHomeViewController" bundle:nil] autorelease];
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [[[CalendarHomeViewController alloc] initWithNibName:@"CalendarHomeViewController" bundle:nil] autorelease];
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(CalendarHomeViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        CalendarDetailViewController *detailVC = [[[CalendarDetailViewController alloc] init] autorelease];
        detailVC.indexPath = [params objectForKey:@"currentIndexPath"];
        detailVC.eventsBySection = [params objectForKey:@"eventsBySection"];
        detailVC.sections = [params objectForKey:@"sections"];
        vc = detailVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
        
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
        NSLog(@"%@", [aResult description]);
        KGOEventWrapper *anEvent = [[[KGOEventWrapper alloc] initWithDictionary:aResult] autorelease];
        [searchResults addObject:anEvent];
    }
    [self.searchDelegate searcher:self didReceiveResults:searchResults];
}


@end

