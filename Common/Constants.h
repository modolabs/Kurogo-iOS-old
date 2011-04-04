#import <Foundation/Foundation.h>
#import "MITBuildInfo.h"

// local path names for handleLocalPath
extern NSString * const LocalPathPageNameHome;
extern NSString * const LocalPathPageNameDetail;
extern NSString * const LocalPathPageNameSearch;
extern NSString * const LocalPathPageNameCategoryList;
extern NSString * const LocalPathPageNameItemList;
extern NSString * const LocalPathPageNameMapList;
extern NSString * const LocalPathPageNameBookmarks;
extern NSString * const LocalPathPageNameWebViewDetail;

// keys for NSUserDefaults dictionary go here (app preferences)
extern NSString * const DeviceTokenKey;
extern NSString * const UnreadNotificationsKey;


// module tags
extern NSString * const AboutTag;
extern NSString * const CalendarTag;
extern NSString * const CoursesTag;
extern NSString * const DiningTag;
extern NSString * const EmergencyTag;
extern NSString * const FullWebTag;
extern NSString * const HomeTag;
extern NSString * const LibrariesTag;
extern NSString * const MapTag;
extern NSString * const NewsTag;
extern NSString * const PeopleTag;
extern NSString * const SettingsTag;
extern NSString * const SchoolsTag;
extern NSString * const TransitTag;
extern NSString * const PhotosTag;
extern NSString * const LoginTag;
extern NSString * const VideoTag;



extern NSString * const LocalPathMapsSelectedAnnotation;

// preferences

extern NSString * const MITNewsTwoFirstRunKey;


// notification names

extern NSString * const ModuleListDidChangeNotification;

// core data entity names

extern NSString * const KGOPersonEntityName;
extern NSString * const PersonContactEntityName;
extern NSString * const PersonOrganizationEntityName;
extern NSString * const PersonAddressEntityName;

extern NSString * const KGOPlacemarkEntityName;
extern NSString * const MapCategoryEntityName;

extern NSString * const NewsStoryEntityName;
extern NSString * const NewsCategoryEntityName;
extern NSString * const NewsImageEntityName;
extern NSString * const NewsImageRepEntityName;

extern NSString * const EmergencyNoticeEntityName;
extern NSString * const EmergencyContactsSectionEntityName;
extern NSString * const EmergencyContactEntityName;



// resource names
extern NSString * const MITImageNameUpArrow;
extern NSString * const MITImageNameDownArrow;

// errors
extern NSString * const MapsErrorDomain;
#define errMapProjection 0

extern NSString * const ShuttlesErrorDomain;
#define errShuttleRouteNotAvailable 0

extern NSString * const JSONErrorDomain;
#define errJSONParseFailed 0

