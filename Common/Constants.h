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
extern NSString * const FBPhotosTag;









extern NSString * const LocalPathMapsSelectedAnnotation;

// common URLs
extern NSString * const MITMobileWebDomainString;
extern NSString * const MITMobileWebAPIURLString;


extern NSString * const KGOModuleTabOrderKey;
extern NSString * const MITActiveModuleKey;
extern NSString * const MITNewsTwoFirstRunKey;
extern NSString * const MITEventsModuleInSortOrderKey;
extern NSString * const EmergencyInfoKey;
extern NSString * const EmergencyLastUpdatedKey;
extern NSString * const EmergencyUnreadCountKey;
extern NSString * const ShuttleSubscriptionsKey;
extern NSString * const StellarTermKey;
extern NSString * const MITDeviceIdKey;
extern NSString * const MITPassCodeKey;
extern NSString * const PushNotificationSettingsKey;
extern NSString * const KGOModulesSavedStateKey;
extern NSString * const ShakeToReturnPrefKey;
extern NSString * const MapTypePrefKey;



// notification names
extern NSString * const EmergencyInfoDidLoadNotification;
extern NSString * const EmergencyInfoDidFailToLoadNotification;
extern NSString * const EmergencyInfoDidChangeNotification;
extern NSString * const EmergencyContactsDidLoadNotification;

extern NSString * const ShuttleAlertRemoved;

extern NSString * const UnreadBadgeValuesChangeNotification;

extern NSString * const MyStellarAlertNotification;

extern NSString * const kTileServerManagerProjectionIsReady;

// core data entity names

extern NSString * const NewsStoryEntityName;
extern NSString * const NewsCategoryEntityName;
extern NSString * const NewsImageEntityName;
extern NSString * const NewsImageRepEntityName;
extern NSString * const PersonDetailsEntityName;
extern NSString * const PersonDetailEntityName;
extern NSString * const StellarCourseEntityName;
extern NSString * const StellarClassEntityName;
extern NSString * const StellarClassTimeEntityName;
extern NSString * const StellarStaffMemberEntityName;
extern NSString * const StellarAnnouncementEntityName;
extern NSString * const EmergencyInfoEntityName;
extern NSString * const EmergencyContactEntityName;
extern NSString * const ShuttleRouteEntityName;
extern NSString * const ShuttleStopEntityName;
extern NSString * const ShuttleRouteStopEntityName;
extern NSString * const CalendarEventEntityName;
extern NSString * const CalendarCategoryEntityName;
extern NSString * const CampusMapSearchEntityName;
extern NSString * const CampusMapAnnotationEntityName;
extern NSString * const ShuttleRouteEntityName;
extern NSString * const ShuttleStopEntityName;
extern NSString * const ShuttleRouteStopEntityName;
extern NSString * const LibraryItemEntityName;
extern NSString * const LibraryEntityName;
extern NSString * const LibraryFormatCodeEntityName;
extern NSString * const LibraryLocationCodeEntityName;
extern NSString * const LibraryPubDateCodeEntityName;
extern NSString * const LibraryPhoneEntityName;
extern NSString * const LibraryAliasEntityName;


// resource names
extern NSString * const ImageNameHomeScreenBackground;
extern NSString * const MITImageNameBackground;

extern NSString * const MITImageNameScrollTabBackgroundOpaque;
extern NSString * const MITImageNameScrollTabBackgroundTranslucent;
extern NSString * const MITImageNameScrollTabLeftEndCap;
extern NSString * const MITImageNameScrollTabRightEndCap;
extern NSString * const MITImageNameScrollTabSelectedTab;

extern NSString * const MITImageNameLeftArrow;
extern NSString * const MITImageNameRightArrow;
extern NSString * const MITImageNameUpArrow;
extern NSString * const MITImageNameDownArrow;

extern NSString * const MITImageNameSubheadBarBackground; 

extern NSString * const MITImageNameSearch;
extern NSString * const MITImageNameBookmark;

// errors
extern NSString * const MapsErrorDomain;
#define errMapProjection 0

extern NSString * const ShuttlesErrorDomain;
#define errShuttleRouteNotAvailable 0

extern NSString * const JSONErrorDomain;
#define errJSONParseFailed 0

