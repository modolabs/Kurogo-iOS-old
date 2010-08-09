#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarClassTime.h"
#import "StellarStaffMember.h"
#import "JSONAPIRequest.h"

extern NSString * const MyStellarChanged;
/** @brief Callback for stellar courses
 * 
 *  Notify's client code that courses are now saved in Core Data. 
 *  If course can not be saved in Core Date because the server was unreachable
 */
#pragma mark Course Loading 
@protocol CoursesLoadedDelegate <NSObject>
/** 
 *  Called when courses are available to be loaded with +[StellarModel allCourses] 
 */
- (void) coursesLoaded;
/**
 *  Called when failed to retrieve courses from the server
 */
- (void) handleCouldNotReachStellar; 
@end

/** 
 * Receives JSON from JSONAPIRequest for a stellar courses request
 */
@interface CoursesRequest : NSObject <JSONAPIDelegate> {
	id<CoursesLoadedDelegate> coursesLoadedDelegate;
}
@property(nonatomic, retain) id<CoursesLoadedDelegate> coursesLoadedDelegate;

/**
 *  designated initalizer 
 *  Notify's the CoursesLoadedDelegate of success or failure
 */
- (id) initWithCoursesDelegate: (id<CoursesLoadedDelegate>)delegate;
@end

#pragma mark Class List Loading

/** @brief Callback for classlist
 * 
 *  Pass back to client code an NSArray of StellarClass objects
 *  for a given course.
 */
@protocol ClassesLoadedDelegate <NSObject>
/** 
 *  Called when classes successfully loaded from server or cache.
 *  @param classes an array of StellarClass objects
 */
- (void) classesLoaded: (NSArray *)classes;
/**
 *  Called when unable to retrieve classes from the network
 */
- (void) handleCouldNotReachStellar;
@end

/** 
 * Receives JSON from JSONAPIRequest for a stellar class list request
 */
@interface ClassesRequest : NSObject <JSONAPIDelegate> {
	id<ClassesLoadedDelegate> classesLoadedDelegate;
	StellarCourse *stellarCourse;
}
@property(nonatomic, retain) id<ClassesLoadedDelegate> classesLoadedDelegate;
@property(nonatomic, retain) StellarCourse *stellarCourse;

/**
 *  designated initalizer 
 *  @param delegate receives an NSArray of StellarClass objects
 *  @param stellarCourse the course for which classes are being looked up
 */
- (id) initWithDelegate: (NSObject<ClassesLoadedDelegate>*)delegate course: (StellarCourse *)stellarCourse;
- (void) notifyClassesLoadedDelegate;
- (void) markCourseAsNew;
@end

@interface ClassesChecksumRequest : NSObject <JSONAPIDelegate> {
	ClassesRequest *classesRequest;
}
- (id) initWithClassesRequest:(ClassesRequest *)aClassesRequest;
@end

#pragma mark Class Info Loading

/**
 *  @brief Callback for loading a stellar class
 * 
 *  Callback for loading detailed information about
 *  a specific class.  There are several phases for 
 *  retreiving this information, usually general information
 *  is already available so it tries to return this is quickly as possible
 *  often cached and possibly out of date detailed information is also available
 *  finally up to date detailed information is retrieved over the network from
 *  the server.
 */
@protocol ClassInfoLoadedDelegate <NSObject>

/**
 *  Called when general information (such as times/locations/staff) is available
 *  @param class needs at minimum the masterSubjectId to be populated
 */
- (void) generalClassInfoLoaded: (StellarClass *)class;

/**
 *  Called when some detailed information is available
 *  The detail information is the general information plus the stellar announcements
 *  @param class needs at minimum the masterSubjectId to be populated
 */
- (void) initialAllClassInfoLoaded: (StellarClass *)class;

/**
 *  Called when all the class information is available
 *  The detail information is the general information plus the stellar announcements
 *  @param class needs at minimum the masterSubjectId to be populated
 */
- (void) finalAllClassInfoLoaded: (StellarClass *)class;
/** 
 *  Called when no class exists for the given master subject id
 */
- (void) handleClassNotFound;
/**
 *  Called when unable to load class information from the server
 */
- (void) handleCouldNotReachStellar;
@end

/** 
 *  Receives JSON from JSONAPIRequest for a stellar class
 *  including all class information such as announcements
 *  times and location
 */ 
@interface ClassInfoRequest : NSObject <JSONAPIDelegate> {
	id<ClassInfoLoadedDelegate> classInfoLoadedDelegate;
}


@property (nonatomic, retain) id<ClassInfoLoadedDelegate> classInfoLoadedDelegate;

/**
 *  designated initalizer 
 *  @param delegate receives a StellarClass object with class information populated
 */
- (id) initWithClassInfoDelegate: (id<ClassInfoLoadedDelegate>) delegate;
@end

/**
 *  @brief Callback for searching for classes
 * 
 *  This callback receives an NSArray of StellarClass objects
 *  that match some given searchTerms
 */
@protocol ClassesSearchDelegate <NSObject>
/**
 *  Called when search completes
 *  @param classes the found NSArray of StellarClass objects returned by the search
 *  @param searchTerms the string used for the search
 */
- (void) searchComplete: (NSArray *)classes searchTerms: (NSString *)searchTerms;
/**
 *  Called when a search attempt fails to connect to the server
 */
- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms;

/**
 *  Called when a search attempt returns more than 100 terms
 */
- (void) handleTooManySearchResults;
@end

/** 
 *  Receives JSON from JSONAPIRequest for a stellar class search
 */
@interface ClassesSearchRequest : NSObject <JSONAPIDelegate> {
	id<ClassesSearchDelegate> classesSearchDelegate;
	NSString *searchTerms;
}

/**
 *  designated initalizer 
 *  @param delegate receives an NSArray of StellarClass objects
 *  @param searchTerms the string used to search for classes from Stellar
 */
- (id) initWithDelegate: (id<ClassesSearchDelegate>)delegate searchTerms: (NSString *)searchTerms;
@end

/**
 *  Callback to notify client code that all the stellar bookmarks have been removed
 *  this is usually due to a change of semester
 */
@protocol ClearMyStellarDelegate <NSObject>

/** 
 *  Called when classes are removed from the bookmarks
 *  @param classes an array of the StellarClass objects that were removed
 */
- (void) classesRemoved: (NSArray *)classes;
@end

/** 
 *  Receives a JSON representation indicating the current semester
 *  and removes class in the NSArray which are old
 */
@interface TermRequest : NSObject <JSONAPIDelegate> {
	id<ClearMyStellarDelegate> clearMyStellarDelegate;
	NSArray *myStellarClasses;
}

/**
 *  designated initalizer 
 *  @param delegate receives an NSArray of StellarClass objects that were removed
 *  @param theMyStellarClass an NSArray of StellarClass objects that may need to be removed from the bookmarks
 */
- (id) initWithClearMyStellarDelegate: (id<ClearMyStellarDelegate>)delegate stellarClasses: (NSArray *)theMyStellarClasses;
@end


/**
 *  @brief Singleton class to access stellar data.
 *
 *  Data is retrieved from network or disk or memory cache.
 *  Most the methods use specially defined protocol to receive the data.
 */
@interface StellarModel : NSObject {
}

// load*FromServerAndNotify methods retreive data from the server and store it in the CoreData Store
// to use the loaded data must call a retrive* method after it has been loaded

/**
 *  @return a boolean indicating if the courses are currently available on the disk
 */
+ (BOOL) coursesCached;

/**
 *  loads the courses from the server and notify's the callback
 *  @param delegate called when the courses are available on the disk
 */
+ (void) loadCoursesFromServerAndNotify: (id<CoursesLoadedDelegate>)delegate;

/**
 *  loads the classes for a course.
 *  @param delegate recieves an NSArray of StellarClass objects
 */
+ (void) loadClassesForCourse: (StellarCourse *)stellarCourse delegate: (NSObject<ClassesLoadedDelegate> *)delegate;

/**
 *  loads the detailed class information for a given courses
 *  @param stellarClass class object with at least the masterSubjectId property value already set.
 *  @param delegate receives the a StellarClass object with values set in three different stages of loading
 */
+ (void) loadAllClassInfo: (StellarClass *)stellarClass delegate: (id<ClassInfoLoadedDelegate>)delegate;

/**
 *  loads a search for classes from the server
 *  @param searchTerms the terms used for the search
 *  @param delegate receives the NSArray of StellarClass objects the search returned
 */
+ (void) executeStellarSearch: (NSString *)searchTerms delegate: (id<ClassesSearchDelegate>)delegate;

/**
 *  adds a class to the list of bookmarked classes
 *  @param class the class to bookmark
 */
+ (void) saveClassToFavorites: (StellarClass *)class;
/**
 *  remove a class from the list of bookmarks
 *  @param class the class to remove
 */
+ (void) removeClassFromFavorites: (StellarClass *)class;

/**
 *  lookup the current semester from the server and remove old classes based on server response
 */
+ (void) removeOldFavorites: (id<ClearMyStellarDelegate>)delegate;

/**
 *  retreives all the classes stored on cache
 *  @returns an array of StellarCourse objects
 */
+ (NSArray *) allCourses;

/**
 *  retreives the list of bookmarked classes
 *  @returns an array of StellarClass objects
 */
+ (NSArray *) myStellarClasses;

+ (NSArray *) sortedAnnouncements: (StellarClass *)class;

#pragma mark factory methods for stellar data objects (currently using CoreData)

+ (StellarCourse *) courseWithId: (NSString *)courseId;
/** 
 *  @returns a StellarClass object, does query based on masterSubjectId
 */
+ (StellarClass *) classWithMasterId: (NSString *)masterId;

#pragma mark factory JSON -> Stellar
+ (StellarClass *) StellarClassFromDictionary: (NSDictionary *)aDict index:(NSInteger)index;
+ (StellarClassTime *) stellarTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)stellarClass orderId: (NSInteger)orderId;
+ (StellarStaffMember *) stellarStaffFromName: (NSString *)name class:(StellarClass *)stellarClass type: (NSString *)type;
+ (StellarAnnouncement *) stellarAnnouncementFromDict: (NSDictionary *)dict;

@end
