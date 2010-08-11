#import "StellarModule.h"
#import "StellarMainTableController.h"
#import "MITModuleList.h"
#import "StellarModel.h"
#import "StellarAnnouncementViewController.h"
#import "StellarDetailViewController.h"
#import "StellarClassesTableController.h"
#import "StellarCoursesTableController.h"
#import "Constants.h"
#import "CoreDataManager.h"
#import "SpringboardViewController.h"

@implementation StellarModule

@synthesize mainController, request;

- (id)init
{
	self = [super init];
    if (self != nil) {
        self.tag = StellarTag;
		self.shortName = @"Courses";
		self.longName = @"Course Catalog";
        self.iconName = @"courses";
        self.pushNotificationSupported = YES;
        self.supportsFederatedSearch = YES;
		
		self.mainController = [[[StellarMainTableController alloc] init] autorelease];
		//stellarMainTableController.navigationItem.title = @"MIT Stellar";
		mainController.navigationItem.title = @"Course Catalogue";
        self.viewControllers = [NSArray arrayWithObject:mainController];
    }
    return self;
}


- (BOOL)handleNotification:(MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen {
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarAlertNotification object:nil];
	
	if(shouldOpen) {		
		// mark Launch as begun so we dont handle the path twice.
		hasLaunchedBegun = YES;
		[appDelegate showModuleForTag:self.tag];	
		
		[self handleLocalPath:[NSString stringWithFormat:@"class/%@/News", notification.noticeId] query:nil];

	}
	return YES;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
	// which classes have unread messages may have changed, so broadcast that my stellar may have changed
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarAlertNotification object:nil];

	NSArray *stellarClasses = [StellarModel myStellarClasses];
	NSMutableArray *unusedNotifications = [NSMutableArray array];
	
	// check if any of the unread messages are no longer in "myStellar" list
	for(MITNotification *notification in unreadNotifications) {
		BOOL found = NO;
		for(StellarClass *class in stellarClasses) {
			if([class.masterSubjectId isEqualToString:notification.noticeId]) {
				found = YES;
			}
		}
		
		if(!found) {
			// class not in myStellar, so will probably never get read, just clear it from the unread list now
			[unusedNotifications addObject:notification];
		}
	}
	[MITUnreadNotifications removeNotifications:unusedNotifications];
}

#pragma mark JSONAPIRequest

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	NSString *countString = [[object objectForKey:@"count"] description];
	int count = [countString intValue];
	
	if (count > 100) {
        //TODO: something smarter than just ignore results
        self.searchResults = nil;
		return;
	}
	
	NSMutableArray *classes = [NSMutableArray array];
	NSArray *searchResult = [object objectForKey:@"classes"];
	int ind = 0;
	for(NSDictionary *aDict in searchResult) {
		[classes addObject:[StellarModel StellarClassFromDictionary:aDict index:ind]];
		ind++;
	}
	[CoreDataManager saveData];
    self.searchResults = classes;
}

- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress {
    self.searchProgress = progress;
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request {
    self.request = nil;
}

#pragma mark Search and state

// in this module we may want -resetNavStack
// to return to a view other than the list of schools,
// perhaps user's preferred school
- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:mainController];
}

- (void)performSearchForString:(NSString *)searchText {
    [super performSearchForString:searchText];
    
	self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    // TODO: check for failure
	[self.request requestObjectFromModule:@"stellar" 
                                  command:@"search" 
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"query", nil]];
}

- (void)abortSearch {
    if (self.request) {
        [self.request abortRequest];
        self.request = nil;
    }
    [super abortSearch];
}

- (NSString *)titleForSearchResult:(id)result {
    StellarClass *theClass = (StellarClass *)result;
    if([theClass.name length]) {
        return theClass.name;
	} else {
        return theClass.masterSubjectId;
	}
}

- (NSString *)subtitleForSearchResult:(id)result {
    StellarClass *theClass = (StellarClass *)result;
    return theClass.title;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    
    BOOL didHandle = NO;
    
    [self resetNavStack];

    if ([localPath isEqualToString:LocalPathFederatedSearch]) {
        self.selectedResult = nil;
        mainController.view;
        [mainController presentSearchResults:self.searchResults query:query];
        [self resetNavStack];
        didHandle = YES;
        
    } else if ([localPath isEqualToString:LocalPathFederatedSearchResult]) {
        NSInteger row = [query integerValue];
        self.selectedResult = [self.searchResults objectAtIndex:row];
        StellarDetailViewController *detailVC = [StellarDetailViewController launchClass:self.selectedResult viewController:mainController];
        self.viewControllers = [NSArray arrayWithObject:detailVC];
        didHandle = YES;
    }
    
    /*
	NSArray *pathComponents = [localPath componentsSeparatedByString:@"/"];
	NSString *pathRoot = [pathComponents objectAtIndex:0];	
	StellarMainTableController *rootController = (StellarMainTableController *)[self rootViewController];
	
	if ([pathRoot isEqualToString:@"class"]) {
		StellarClass *stellarClass = [StellarModel classWithMasterId:[pathComponents objectAtIndex:1]];
		if(stellarClass) {
			StellarDetailViewController *detailViewController = [StellarDetailViewController launchClass:stellarClass viewController:rootController];
			if ([pathComponents count] > 2) {
				[detailViewController setCurrentTab:[pathComponents objectAtIndex:2]];
			}
			// check to see if we drilling down into a news announcment
			if (([pathComponents count] > 3) && [[pathComponents objectAtIndex:2] isEqualToString:@"News"]) {
				NSInteger announcementIndex = [[pathComponents objectAtIndex:3] integerValue];
				NSArray *announcements = [StellarModel sortedAnnouncements:stellarClass];
				if (announcements.count > announcementIndex) {
					StellarAnnouncement *announcement = [announcements objectAtIndex:announcementIndex];
					detailViewController.refreshClass = NO;
					StellarAnnouncementViewController *announcementViewController = [[StellarAnnouncementViewController alloc] 
						initWithAnnouncement:announcement rowIndex:announcementIndex];
					[detailViewController.navigationController pushViewController:announcementViewController animated:NO];
					[announcementViewController release];
				}
			}
            didHandle = YES;
		}
		
	} else if ([pathRoot isEqualToString:@"courses"]) {
		NSString *courseGroupString = [pathComponents objectAtIndex:1];
		StellarCourseGroup *courseGroup = [StellarCourseGroup deserialize:courseGroupString];
		
		if(courseGroup) {
			StellarCoursesTableController *coursesTableController = [[StellarCoursesTableController alloc] initWithCourseGroup:courseGroup];
			[rootController.navigationController pushViewController:coursesTableController animated:NO]; 			 
			
			if ([pathComponents count] > 2) {
				NSString *courseId = [pathComponents objectAtIndex:2];
				StellarCourse *course = [StellarModel courseWithId:courseId];
				
				if (course) {
					StellarClassesTableController *classesTableController = [[StellarClassesTableController alloc] initWithCourse:course];
					[coursesTableController.navigationController pushViewController:classesTableController animated:NO];
					[classesTableController release];
				}
			}
			
			[coursesTableController release];
            
            didHandle = YES;
		}
        
	} else if ([pathRoot isEqualToString:@"search-begin"] || [pathRoot isEqualToString:@"search-complete"]) {
		// need to force the view to load before activating the doSearch method
		rootController.view;
		[rootController doSearch:query execute:[pathRoot isEqualToString:@"search-complete"]];
        didHandle = YES;
	}
    */
	return didHandle;
}

- (void)dealloc
{
	[super dealloc];
}

@end
