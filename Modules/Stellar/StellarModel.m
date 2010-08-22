#import "StellarModel.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarAnnouncement.h"
#import "StellarCache.h"
#import "ConnectionWrapper.h"
#import "CoreDataManager.h"
#import "StellarMainSearch.h"

#define DAY 24 * 60 * 60
#define MONTH 30 * DAY

NSString * const MyStellarChanged = @"MyStellarChanged";

/** This class is responsible for grabbing stellar data 
 the methods are written to accept callbacks, so everything is asynchronous
 
 there are two levels of data retrieval (depending on the type of query being executed)
 
 CoreData (semi permanent on disk storage)
 
 JSONAPIRequest (requires server connection to call the mit mobile web server)
**/


NSInteger classNameCompare(id class1, id class2, void *context);
NSInteger classNameInCourseCompare(id class1, id class2, void *context);
NSString* cleanPersonName(NSString *personName);

@interface StellarModel (Private)

+ (BOOL) classesFreshForCourse: (StellarCourse *)course;
+ (NSArray *) classesForCourse: (StellarCourse *)course;
+ (void) classesForCourseCompleteRequest:(ClassesRequest *)classesRequest;

@end

@implementation StellarModel

+ (BOOL) coursesCached {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSDate *coursesLastSaved = (NSDate *)[settings objectForKey:@"stellarCoursesLastSaved"];
	if(coursesLastSaved == nil) {
		return NO;
	} else {
		return (BOOL)(-[coursesLastSaved timeIntervalSinceNow] < MONTH);
	}
}

+ (void) loadCoursesFromServerAndNotify: (id<CoursesLoadedDelegate>)delegate {
	if([StellarModel coursesCached]) {
		[delegate coursesLoaded];
		return;
	}
	
	JSONAPIRequest *apiRequest = [JSONAPIRequest 
		requestWithJSONAPIDelegate:[[[CoursesRequest alloc] 
			initWithCoursesDelegate:delegate] autorelease]];
	[apiRequest requestObjectFromModule:@"courses" command:@"courses" parameters:nil];

}

+ (BOOL) classesFreshForCourse: (StellarCourse *)course term: (NSString *)term {
	// check for an existance of a last cached date first
	if (![course.term length] || !course.lastCache || !term) {
		return NO;
	}

	// check if term is old
	if (![course.term isEqualToString:term]) {
		// new term remove all the classes for this course
		[course removeStellarClasses:course.stellarClasses];
		course.lastChecksum = nil;
		course.lastCache = nil;
		[CoreDataManager saveData];
		return NO;
	}
		
	return (-[course.lastCache timeIntervalSinceNow] < 2 * DAY);
}
	
+ (void) loadClassesForCourse: (StellarCourse *)stellarCourse delegate: (NSObject<ClassesLoadedDelegate>*) delegate {
	ClassesRequest *classesRequest = [[[ClassesRequest alloc] initWithDelegate:delegate course:stellarCourse] autorelease];
	// check if the current class list cache for course is old

	NSString *term = [[NSUserDefaults standardUserDefaults] objectForKey:StellarTermKey];
	if ([StellarModel classesFreshForCourse:stellarCourse term:term]) {
		[classesRequest performSelector:@selector(notifyClassesLoadedDelegate) withObject:nil afterDelay:0.1];
	} else {
		// see if the class info has changed using a checksum		
		if(stellarCourse.lastChecksum) {
			JSONAPIRequest *apiRequest = [JSONAPIRequest
										   requestWithJSONAPIDelegate:[[[ClassesChecksumRequest alloc] initWithClassesRequest:classesRequest] autorelease]];
		
			[apiRequest 
				requestObjectFromModule:@"courses" 
				command:@"subjectList" 
				parameters:[NSDictionary dictionaryWithObjectsAndKeys: 
					stellarCourse.title, @"id", 
					@"true", @"checksum", stellarCourse.courseGroup, @"coursegroup",
					nil]];
		} else {
			[self classesForCourseCompleteRequest:classesRequest];
		}
	}
}

/* this method is the final call to the server, to retreive all the classes for a given course
   along with a checksum for detecting changes to a course
 */
+ (void) classesForCourseCompleteRequest:(ClassesRequest *)classesRequest {
	JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:classesRequest];
	[apiRequest 
	 requestObjectFromModule:@"courses" 
	 command:@"subjectList" 
	 parameters:[NSDictionary dictionaryWithObjectsAndKeys: 
		classesRequest.stellarCourse.title, @"id",
		@"true", @"checksum",
		@"true", @"full", classesRequest.stellarCourse.courseGroup, @"coursegroup",
		nil]];
}

+ (NSArray *) classesForCourse:(StellarCourse *)course {
	return [[course.stellarClasses allObjects] sortedArrayUsingFunction:classNameInCourseCompare context:course];
}

+ (void) executeStellarSearch: (NSString *)searchTerms courseGroupName: (NSString *)courseGroupName courseName: (NSString *)courseName delegate: (id<ClassesSearchDelegate>)delegate {
	JSONAPIRequest *apiRequest = [JSONAPIRequest
		requestWithJSONAPIDelegate:[[[ClassesSearchRequest alloc]
									 initWithDelegate:delegate searchTerms:searchTerms] autorelease]];
	[apiRequest 
		requestObjectFromModule:@"courses" 
		command:@"search" 
		parameters:[NSDictionary dictionaryWithObjectsAndKeys: 
					searchTerms, @"query",
					courseGroupName, @"courseGroup", courseName, @"courseName", nil]]; //[NSDictionary dictionaryWithObject:searchTerms forKey:@"query"]];
}
	
+ (NSArray *) allCourses {
	return [CoreDataManager fetchDataForAttribute:StellarCourseEntityName];
}

+ (NSArray *) myStellarClasses {
	return [[CoreDataManager objectsForEntity:StellarClassEntityName 
				matchingPredicate:[NSPredicate predicateWithFormat:@"isFavorited == 1"]]
			 sortedArrayUsingFunction:classNameCompare context:NULL];	
}

+ (NSArray *) sortedAnnouncements: (StellarClass *)class {
	return [[class.announcement allObjects]
	 sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO] autorelease]]];
}

+ (void) loadAllClassInfo: (StellarClass *)class delegate: (id<ClassInfoLoadedDelegate>)delegate {
	// there three states class info can exist in
	// 1) just contains general information such as the name and location and instructors
	// 2) contains all the information and has been recently retrived from the mobile web server (therefore is up-to-date)
	
	
	if([class.name length]) {
		[delegate generalClassInfoLoaded:class];
	}
	
	if([class.isFavorited boolValue]) {
		[delegate initialAllClassInfoLoaded:class];
	}
	
	// finally we call the server to get the most definitive data
	JSONAPIRequest *apiRequest = [JSONAPIRequest
		requestWithJSONAPIDelegate:[[[ClassInfoRequest alloc] 
			initWithClassInfoDelegate:delegate] autorelease]];
	
	[apiRequest 
		requestObjectFromModule:@"courses" 
		command:@"subjectInfo" 
		parameters:[NSDictionary dictionaryWithObject: class.masterSubjectId forKey:@"id"]];
}

+ (void) saveClassToFavorites: (StellarClass *)class {
	class.isFavorited = [NSNumber numberWithInt:1];
	[CoreDataManager saveData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
}

+ (void) removeClassFromFavorites: (StellarClass *)class notify: (BOOL)sendNotification{
	class.isFavorited = [NSNumber numberWithInt:0];
	[CoreDataManager saveData];

	if(sendNotification) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
	}
}

+ (void) removeClassFromFavorites: (StellarClass *)class {
	[self removeClassFromFavorites:class notify:YES];
}

+ (void) removeOldFavorites: (id<ClearMyStellarDelegate>)delegate {
	// we call the server to get the current semester
	NSArray *favorites = [self myStellarClasses];
	JSONAPIRequest *apiRequest = [JSONAPIRequest
		requestWithJSONAPIDelegate:[[[TermRequest alloc] 
			initWithClearMyStellarDelegate:delegate stellarClasses:favorites] autorelease]];
		
	[apiRequest requestObjectFromModule:@"courses" command:@"term" parameters:nil];
}

+ (StellarCourse *) courseWithId: (NSString *)courseId {
	return [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"number" value:courseId];
}

+ (StellarClass *) classWithMasterId: (NSString *)masterSubjectId {
	StellarClass *stellarClass;
	NSArray *stellarClasses = [CoreDataManager objectsForEntity:StellarClassEntityName 
		matchingPredicate:[NSPredicate predicateWithFormat:@"masterSubjectId == %@", masterSubjectId]];
	if([stellarClasses count]) {
		stellarClass = [stellarClasses objectAtIndex:0];
	} else {
		stellarClass = (StellarClass *)[CoreDataManager insertNewObjectForEntityForName:StellarClassEntityName];
		stellarClass.masterSubjectId = masterSubjectId;
	}
	return stellarClass;
}
	
+ (StellarClass *) StellarClassFromDictionary: (NSDictionary *)aDict index:(NSInteger)index{
	StellarClass *stellarClass = [StellarModel classWithMasterId:[aDict objectForKey:@"masterId"]];
	
	NSString *name = [aDict objectForKey:@"name"];
	
	/*if ([[name substringToIndex:1] isEqualToString:@"0"])
	 name = [name substringFromIndex:1];*/

	// if name is not defined do not attempt to overwrite with new information
	if([name length]) {
		if (index >= 0)
			stellarClass.order = [NSNumber numberWithInt:(int)index];
		
		stellarClass.name = name;
		stellarClass.title = [aDict objectForKey:@"title"];
		stellarClass.blurb = [aDict objectForKey:@"description"];
		
		if ([aDict objectForKey:@"preReq"]) {
			stellarClass.preReqs = [aDict objectForKey:@"preReq"];
		}
		if ([aDict objectForKey:@"credits"]) {
			stellarClass.credits = [aDict objectForKey:@"credits"];
		}
		if ([aDict objectForKey:@"cross_reg"]) {
			stellarClass.cross_reg = [aDict objectForKey:@"cross_reg"];
		}
		if ([aDict objectForKey:@"exam_group"]) {
			stellarClass.examGroup = [aDict objectForKey:@"exam_group"];
		}
		if ([aDict objectForKey:@"department"]) {
			stellarClass.department = [aDict objectForKey:@"department"];
		}
		if ([aDict objectForKey:@"school"]) {
			stellarClass.school = [aDict objectForKey:@"school"];
			stellarClass.school_short = [aDict objectForKey:@"school"];
		} 
		if ([aDict objectForKey:@"short_name"]) {
			stellarClass.school_short = [aDict objectForKey:@"short_name"];
		}
		
		stellarClass.term = [aDict objectForKey:@"term"];
		//stellarClass.term = @"Fall 2010";
		stellarClass.url = [aDict objectForKey:@"stellarUrl"];
		stellarClass.lastAccessedDate = [NSDate date];
	
		// add the class times
		for(NSManagedObject *managedObject in stellarClass.times) {
			// remove the old version of the class times
			[CoreDataManager deleteObject:managedObject];
		}
		/*NSDictionary *test = [aDict objectForKey:@"times"];
		//NSDictionary *test1 = (NSArray *)[aDict valueForKey:@"times"];
		
		int cnt = [(NSArray *)[aDict objectForKey:@"times"] count];
		int r = cnt*cnt;*/
		
		NSInteger orderId = 0;
		if ([[aDict valueForKey:@"parsed_meeting_times"] class] == [NSNull class]) {
			for(NSDictionary *time in (NSArray *)[aDict valueForKey:@"times"]) {
				[stellarClass addTimesObject:[StellarModel stellarParseErrorTimeFromDictionary:time class:stellarClass orderId:orderId]];
				orderId++;
			}
		}
		else {
			for(NSDictionary *time in (NSArray *)[aDict valueForKey:@"parsed_meeting_times"]) {
				[stellarClass addTimesObject:[StellarModel stellarTimeFromDictionary:time class:stellarClass orderId:orderId]];
				orderId++;
			}
		}
	
		// add the class staff
		for(NSManagedObject *managedObject in stellarClass.staff) {
			// remove the old version of the class staff
			[CoreDataManager deleteObject:managedObject];
		}
	
		
		NSDictionary *staff = (NSDictionary *)[aDict objectForKey:@"staff"];
		
		
		NSArray *instructors = (NSArray *)[staff objectForKey:@"instructors"];
		//NSArray *tas = (NSArray *)[staff objectForKey:@"tas"];
		for(NSString *staff in instructors) {
			if ([staff length] > 0)
				[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"instructor"]];
		}
		/*for(NSString *staff in tas) {
			if ([staff length] > 0)
				[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"ta"]];
		}*/

		// add the annoucements
		/*NSArray *annoucements;
		if(annoucements = [aDict objectForKey:@"announcements"]) {
			for(NSManagedObject *managedObject in stellarClass.announcement) {
				// remove the old version of the class annoucements
				[CoreDataManager deleteObject:managedObject];
			}
			for(NSDictionary *annoucementDict in annoucements) {
				[stellarClass addAnnouncementObject:[StellarModel stellarAnnouncementFromDict:annoucementDict]];
			}
		}*/
	}
	return stellarClass;
}

+ (StellarClassTime *) stellarTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)class orderId: (NSInteger)orderId {
	StellarClassTime *stellarClassTime = (StellarClassTime *)[CoreDataManager insertNewObjectForEntityForName:StellarClassTimeEntityName];
	stellarClassTime.stellarClass = class;
	stellarClassTime.title = @"Lecture"; //[time objectForKey:@"title"];
	stellarClassTime.location = [time objectForKey:@"location"];
	stellarClassTime.time = [[NSString alloc] initWithFormat:@"%@ %@", [time objectForKey:@"days"],[time objectForKey:@"time"]];
	stellarClassTime.order = [NSNumber numberWithInt:orderId];
	return stellarClassTime;
}

+ (StellarClassTime *) stellarParseErrorTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)class orderId: (NSInteger)orderId {
	StellarClassTime *stellarClassTime = (StellarClassTime *)[CoreDataManager insertNewObjectForEntityForName:StellarClassTimeEntityName];
	stellarClassTime.stellarClass = class;
	stellarClassTime.title = [time objectForKey:@"title"];
	stellarClassTime.location = [time objectForKey:@"location"];
	stellarClassTime.time = [time objectForKey:@"time"];
	stellarClassTime.order = [NSNumber numberWithInt:orderId];
	return stellarClassTime;
}

+ (StellarStaffMember *) stellarStaffFromName: (NSString *)name class:(StellarClass *)class type: (NSString *)type {
	StellarStaffMember *stellarStaffMember = (StellarStaffMember *)[CoreDataManager insertNewObjectForEntityForName:StellarStaffMemberEntityName];
	stellarStaffMember.stellarClass = class;
	stellarStaffMember.name = cleanPersonName(name);
	stellarStaffMember.type = type;
	return stellarStaffMember;
}

+ (StellarAnnouncement *) stellarAnnouncementFromDict: (NSDictionary *)dict {
	StellarAnnouncement *stellarAnnouncement = (StellarAnnouncement *)[CoreDataManager insertNewObjectForEntityForName:StellarAnnouncementEntityName];
	stellarAnnouncement.pubDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[(NSNumber *)[dict objectForKey:@"unixtime"] doubleValue]];
	stellarAnnouncement.title = (NSString *)[dict objectForKey:@"title"];
	stellarAnnouncement.text = (NSString *)[dict objectForKey:@"text"];
	return stellarAnnouncement;
}
	
@end

@implementation CoursesRequest
@synthesize coursesLoadedDelegate;

- (id) initWithCoursesDelegate: (id<CoursesLoadedDelegate>)delegate {
	if(self = [super init]) {
		self.coursesLoadedDelegate = delegate;
	}
	return self;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	NSArray *courseGroups = (NSArray *)object;
	if (courseGroups.count == 0) {
		// no courses to save
		return;
	}
	
	NSMutableArray *coursesArray = [NSMutableArray array];
	for (NSDictionary *aDict in courseGroups) {
		
		NSArray *courses = [aDict objectForKey:@"courses"];
		NSString *courseGroupName = [[aDict valueForKey:@"school_name"] description];
		NSString *courseGroupShortName = [[aDict valueForKey:@"school_name_short"] description];
	
		
		for (NSDictionary *course in courses) {
			NSString *courseName = [course valueForKey:@"name"];
			if ([courseName length] < 1)
				courseName = [[NSString alloc] initWithFormat:@"%@-other", courseGroupName];
			
			NSString *title = @"title";
			NSString *predicateFormat = [title stringByAppendingString:@" like %@"];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, courseName];
			
			NSArray * coursesStored = [CoreDataManager objectsForEntity:StellarCourseEntityName matchingPredicate:predicate];
			
			//StellarCourse *oldStellarCourse = [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"title" value:courseName];
			//StellarCourse *oldStellarCourse = [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"courseGroup" value:courseGroupName];
			//if(oldStellarCourse){
				
				// Also, since a course (department) can be in multiple groups (schools), do not treat them as the same 
				// if the courseGroupName is different. Here, do not delete if the courseGroupNames are different.						
				for (StellarCourse *oldCourse in coursesStored) {
					if ([oldCourse.courseGroup isEqualToString:courseGroupName])	
						[CoreDataManager deleteObject:oldCourse];
						//[CoreDataManager deleteObject:oldStellarCourse];
				}
			
			StellarCourse *newStellarCourse = (StellarCourse *)[CoreDataManager insertNewObjectForEntityForName:StellarCourseEntityName];
			newStellarCourse.number = [course objectForKey:@"short"];
			newStellarCourse.title = courseName;
			newStellarCourse.courseGroup = courseGroupName;
			newStellarCourse.courseGroupShort = courseGroupShortName;
			
			[coursesArray addObject:newStellarCourse];
		
		}
	}
	
	
	[CoreDataManager saveData];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"stellarCoursesLastSaved"];
	[self.coursesLoadedDelegate coursesLoaded];	
}
	
- (void) dealloc {
	[coursesLoadedDelegate release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	[self.coursesLoadedDelegate handleCouldNotReachStellar];
}

@end

@implementation ClassesChecksumRequest
- (id) initWithClassesRequest: (ClassesRequest *)aClassesRequest {
	if (self = [super init]) {
		classesRequest = [aClassesRequest retain];
	}
	return self;
}

- (void) dealloc {
	[classesRequest release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	if([classesRequest.stellarCourse.lastChecksum isEqualToString:[(NSDictionary *)object objectForKey:@"checksum"]]) {
		// checksum is the same no need to update class list
		[classesRequest markCourseAsNew];
		[classesRequest notifyClassesLoadedDelegate];
	} else {
		[StellarModel classesForCourseCompleteRequest:classesRequest];
	}
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	[classesRequest request:request handleConnectionError:error];
}

@end
@implementation ClassesRequest
@synthesize classesLoadedDelegate, stellarCourse;

- (id) initWithDelegate: (id<ClassesLoadedDelegate>)delegate course: (StellarCourse *)course {
	if(self = [super init]) {
		self.classesLoadedDelegate = delegate;
		self.stellarCourse = course;
	}
	return self;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	NSArray *classes = [object objectForKey:@"classes"];
	int index = 0;
	for(NSDictionary *aDict in classes) {
		[[StellarModel StellarClassFromDictionary:aDict index:index] addCourseObject:self.stellarCourse];
		index++;
	}
	self.stellarCourse.lastChecksum = [object objectForKey:@"checksum"];
	[self markCourseAsNew];
	[self notifyClassesLoadedDelegate];
}	

- (void) markCourseAsNew {
	self.stellarCourse.lastCache = [NSDate dateWithTimeIntervalSinceNow:0];
	//self.stellarCourse.term = [[NSUserDefaults standardUserDefaults] objectForKey:StellarTermKey];
	//self.stellarCourse.term = @"Fall 2010";
	[CoreDataManager saveData];
}
	
- (void) notifyClassesLoadedDelegate {
	[self.classesLoadedDelegate classesLoaded:[StellarModel classesForCourse:self.stellarCourse]];
}

- (void) dealloc {
	[classesLoadedDelegate release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	[self.classesLoadedDelegate handleCouldNotReachStellar];
}

@end

@implementation ClassesSearchRequest

- (id) initWithDelegate: (id<ClassesSearchDelegate>)delegate searchTerms: (NSString *)theSearchTerms {
	if(self = [super init]) {
		classesSearchDelegate = [delegate retain];
		searchTerms = [theSearchTerms retain];
	}
	return self;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	
	NSString *countString = [[object objectForKey:@"count"] description];
	int count = [countString intValue];
	
	NSString *actual_countString = [[object objectForKey:@"actual_count"] description];
	int actual_count = [actual_countString intValue];
	
	if (count > 100) {
		NSObject *detectError = [object objectForKey:@"schools"];
		
		if ([detectError class] == [NSNull class]) {
			[self request:request handleConnectionError:nil];
		}
		
		else if ([classesSearchDelegate class] == [StellarMainSearch class]) {
			[classesSearchDelegate handleTooManySearchResultsForMainSearch:object];
		}
		//else
		//[classesSearchDelegate handleTooManySearchResults];
		
		return;
	}
	
	NSMutableArray *classes = [NSMutableArray array];
	NSArray *searchResult = [object objectForKey:@"classes"];
	
	if ([searchResult class] == [NSNull class]) {
		[self request:request handleConnectionError:nil];
	}

	int ind = 0;
	for(NSDictionary *aDict in searchResult) {
		[classes addObject:[StellarModel StellarClassFromDictionary:aDict index:ind]];
		ind++;
	}
	[CoreDataManager saveData];
	[classesSearchDelegate searchComplete:classes searchTerms:searchTerms actualCount:actual_count];
}	

- (void) dealloc {
	[classesSearchDelegate release];
	[searchTerms release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	[classesSearchDelegate handleCouldNotReachStellarWithSearchTerms:searchTerms];
}

@end

@implementation ClassInfoRequest
@synthesize classInfoLoadedDelegate;

- (id) initWithClassInfoDelegate: (id<ClassInfoLoadedDelegate>)delegate {
	if(self = [super init]) {
		self.classInfoLoadedDelegate = delegate;
	}
	return self;
}

- (void) dealloc {
	[classInfoLoadedDelegate release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {	
	if([(NSDictionary *)object objectForKey:@"error"]) {
		[self.classInfoLoadedDelegate handleClassNotFound];
		return;
	}
	
	StellarClass *class = [StellarModel StellarClassFromDictionary:(NSDictionary *)object index:-1];
	
	[CoreDataManager saveData];
	[self.classInfoLoadedDelegate finalAllClassInfoLoaded:class];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	[self.classInfoLoadedDelegate handleCouldNotReachStellar];
}

@end


@implementation TermRequest

- (id) initWithClearMyStellarDelegate: (id<ClearMyStellarDelegate>)delegate stellarClasses: (NSArray *)theMyStellarClasses {
	if(self = [super init]) {
		clearMyStellarDelegate = [delegate retain];
		myStellarClasses = [theMyStellarClasses retain];
		
	}
	return self;
}

- (void) dealloc {
	[myStellarClasses release];
	[clearMyStellarDelegate release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	NSString *term = [(NSDictionary *)object objectForKey:@"term"];
	[[NSUserDefaults standardUserDefaults] setObject:term forKey:StellarTermKey];
	
	NSMutableArray *oldClasses = [NSMutableArray array];
	for(StellarClass *class in myStellarClasses) {
		if(![term isEqualToString:class.term]) {
			[StellarModel removeClassFromFavorites:class notify:NO];
			[oldClasses addObject:class];
		}
	}
	
	if([oldClasses count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
		[clearMyStellarDelegate classesRemoved:oldClasses];
	}
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	return;
}

@end


NSInteger classIdCompare(NSDictionary *classId1, NSDictionary *classId2) {
	// check the nil cases first
	if(!classId1 && !classId2) {
		return 0;
	}
	if(!classId1) {
		return 1;
	}
	if(!classId2) {
		return -1;
	}
	
	NSString *coursePart1 = [classId1 objectForKey:@"coursePart"];
	NSString *classPart1 = [classId1 objectForKey:@"classPart"];
	NSString *coursePart2 = [classId2 objectForKey:@"coursePart"];
	NSString *classPart2 = [classId2 objectForKey:@"classPart"];
	
	if([coursePart1 compare:coursePart2 options:NSNumericSearch] != 0) {
		return [coursePart1 compare:coursePart2 options:NSNumericSearch];
	}
	
	return [classPart1 compare:classPart2];
}	
	
NSArray *extractClassIds(StellarClass *class) {
	// implementing a cache for this function because
	// this function apparantly is performance bottleneck
	NSArray *classIds = [StellarCache getClassIdsForName:class.name];
	if (classIds) {
		return classIds;
	}
	
	NSArray *words = [class.name componentsSeparatedByString:@" "];
	
	classIds = [NSArray array];
    //filter out words that our class ids
	for(NSString *word in words) {
		NSArray *parts = [word componentsSeparatedByString:@"."];
		if([parts count] == 2) {
			classIds = [classIds arrayByAddingObject:[NSDictionary 
				dictionaryWithObjectsAndKeys:[parts objectAtIndex:0], @"coursePart", [parts objectAtIndex:1], @"classPart", nil]
			];
		}
	}
	
	if(class.name) {
		[StellarCache addClassIds:classIds forName:class.name];
	}
	return classIds;
}

NSDictionary *firstClassId(StellarClass *class) {
	NSArray *classIds = extractClassIds(class);
	if([classIds count]) {
		return [classIds objectAtIndex:0];
	}
	return nil;
}

// compares any two class names
NSInteger classNameCompare(id class1, id class2, void *context) {
	// examples.. if class is "6.002 / 8.003", coursePart=@"6", classPart=@"002" 

	//NSString *name1 = ((StellarClass *)class1).name;
	NSDictionary *classId1 = firstClassId((StellarClass *)class1);
	
	//NSString *name2 = ((StellarClass *)class2).name;
	NSDictionary *classId2 = firstClassId((StellarClass *)class2);

	NSInteger classIdCompareResult = classIdCompare(classId1, classId2);
	if(classIdCompareResult) {
		return classIdCompareResult;
	}
	return [((StellarClass *)class1).order compare: ((StellarClass *)class2).order];//[name1 compare:name2];
}

// compares class name by the part of the name that corresponds to certain class
NSInteger classNameInCourseCompare(id class1, id class2, void *context) {
	NSString *courseId = ((StellarCourse *)context).number;
	StellarClass *stellarClass1 = class1;
	StellarClass *stellarClass2 = class2;
	
	NSDictionary *classId1 = nil;
	NSArray *classIds1 = extractClassIds((StellarClass *)class1);
	for(NSDictionary *classId in classIds1) {
		if([[classId objectForKey:@"coursePart"] isEqualToString:courseId]) {
			classId1 = classId;
			break;
		}
	}
	
	NSDictionary *classId2 = nil;
	NSArray *classIds2 = extractClassIds((StellarClass *)class2);
	for(NSDictionary *classId in classIds2) {
		if([[classId objectForKey:@"coursePart"] isEqualToString:courseId]) {
			classId2 = classId;
			break;
		}
	}
	
	/*NSInteger classIdCompareResult = classIdCompare(classId1, classId2);
	if(classIdCompareResult) {
		return classIdCompareResult;
	}
	
	NSInteger nameCompare = [stellarClass1.name compare:stellarClass2.name];
	if(nameCompare) {
		return nameCompare;
	}*/
	
	return [stellarClass1.order compare:stellarClass2.order];   //[stellarClass1.title compare:stellarClass2.title];
}	

NSString* cleanPersonName(NSString *personName) {
	NSArray *parts = [personName componentsSeparatedByString:@" "];
	NSMutableArray *cleanParts = [NSMutableArray array];
	for (NSString *part in parts) {
		if([part length]) {
			[cleanParts addObject:part];
		}
	}
	return [cleanParts componentsJoinedByString:@" "];
}
