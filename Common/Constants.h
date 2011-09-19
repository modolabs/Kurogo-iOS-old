#import <Foundation/Foundation.h>
#import "MITBuildInfo.h"

// the config strings for these are List, Grid, Portlet, Sidebar, and SplitView.
typedef enum {
    KGONavigationStyleUnknown,
    KGONavigationStyleTableView,
    KGONavigationStyleIconGrid,
    KGONavigationStylePortlet,
    // the following are not enabled for iPhone
    KGONavigationStyleTabletSidebar,
    KGONavigationStyleTabletSplitView
} KGONavigationStyle;

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
extern NSString * const UnreadNotificationsKey;


// module tags
extern NSString * const HomeTag;
extern NSString * const MapTag;
extern NSString * const PeopleTag;


extern NSString * const LocalPathMapsSelectedAnnotation;

// preferences

extern NSString * const MITNewsTwoFirstRunKey;

extern NSString * const FacebookGroupKey;
extern NSString * const FacebookGroupTitleKey;
extern NSString * const TwitterHashTagKey;

// notification names

extern NSString * const ModuleListDidChangeNotification;
extern NSString * const UserSettingsDidChangeNotification;

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

