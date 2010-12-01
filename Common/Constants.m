#import "Constants.h"

#ifdef USE_MOBILE_DEV
NSString * const MITMobileWebDomainString =        @"localhost:8888";
NSString * const MITMobileWebAPIURLString = @"http://localhost:8888/api/";
#else
    #ifdef USE_MOBILE_TEST
    NSString * const MITMobileWebDomainString = @"mobile-dev.harvard.edu";
    NSString * const MITMobileWebAPIURLString = @"http://mobile-dev.harvard.edu/api/";
    #else
        #ifdef USE_MOBILE_STAGE
        NSString * const MITMobileWebDomainString = @"mobile-staging.harvard.edu";
        NSString * const MITMobileWebAPIURLString = @"http://mobile-staging.harvard.edu/api/";
        #else
        NSString * const MITMobileWebDomainString = @"m.harvard.edu";
        NSString * const MITMobileWebAPIURLString = @"http://m.harvard.edu/api/";
        #endif
    #endif
#endif
 

// keys for NSUserDefaults dictionary go here (app preferences)
NSString * const MITModuleTabOrderKey = @"MITModuleTabOrder";
NSString * const MITActiveModuleKey = @"ActiveModule";
NSString * const MITNewsTwoFirstRunKey = @"MITNews2ClearedCachedArticles";
NSString * const MITEventsModuleInSortOrderKey = @"MITEventsModuleInSortOrder";
NSString * const EmergencyUnreadCountKey = @"UnreadEmergencyCount";
NSString * const ShuttleSubscriptionsKey = @"ActiveShuttleSubscriptions";
NSString * const StellarTermKey = @"StellarTerm";
NSString * const TwitterShareUsernameKey = @"TwitterShareUsername";
NSString * const MITDeviceIdKey = @"device_id";
NSString * const MITPassCodeKey = @"pass_key";
NSString * const DeviceTokenKey = @"DeviceToken";
NSString * const MITUnreadNotificationsKey = @"UnreadNotifications";
NSString * const PushNotificationSettingsKey = @"ModulesDisabledForPush";
NSString * const MITModulesSavedStateKey = @"MITModulesSavedState";
NSString * const ShakeToReturnPrefKey = @"ShakeToReturnHomePref";
NSString * const MapTypePrefKey = @"MapTypePref";

NSString * const MITInternalURLScheme = @"harvardmobile";


// module tags
NSString * const CalendarTag   = @"calendar";
NSString * const EmergencyTag  = @"emergencyinfo";
NSString * const CampusMapTag  = @"campusmap";
NSString * const NewsOfficeTag = @"newsoffice";
NSString * const DirectoryTag  = @"people";
NSString * const StellarTag    = @"courses";
NSString * const ShuttleTag    = @"shuttletrack";
NSString * const MobileWebTag  = @"mobileweb";
NSString * const SettingsTag   = @"settings";
NSString * const AboutTag      = @"about";
NSString * const DiningTag	   = @"dining";
NSString * const SchoolsTag    = @"schools";
NSString * const LibrariesTag  = @"libraries";

// notification names
NSString * const EmergencyInfoDidLoadNotification = @"MITEmergencyInfoDidLoadNotification";
NSString * const EmergencyInfoDidFailToLoadNotification = @"MITEmergencyInfoDidFailToLoadNotification";
NSString * const EmergencyInfoDidChangeNotification = @"MITEmergencyInfoDidChangeNotification";
NSString * const EmergencyContactsDidLoadNotification = @"MITEmergencyContactsDidLoadNotification";

NSString * const ShuttleAlertRemoved = @"MITShuttleAlertRemovedNotification";

NSString * const UnreadBadgeValuesChangeNotification = @"UnreadBadgeValuesChangeNotification";

NSString * const MyStellarAlertNotification = @"MyStellarAlertNotification";

NSString * const kTileServerManagerProjectionIsReady = @"TileServerManagerProjectionIsReadyNotification";

// core data entity names
NSString * const NewsStoryEntityName = @"NewsStory";
NSString * const NewsCategoryEntityName = @"NewsCategory";
NSString * const NewsImageEntityName = @"NewsImage";
NSString * const NewsImageRepEntityName = @"NewsImageRep";
NSString * const PersonDetailsEntityName = @"PersonDetails";
NSString * const PersonDetailEntityName = @"PersonDetail";
NSString * const StellarCourseEntityName = @"StellarCourse";
NSString * const StellarClassEntityName = @"StellarClass";
NSString * const StellarClassTimeEntityName = @"StellarClassTime";
NSString * const StellarStaffMemberEntityName = @"StellarStaffMember";
NSString * const StellarAnnouncementEntityName = @"StellarAnnouncement";
NSString * const EmergencyInfoEntityName = @"EmergencyInfo";
NSString * const EmergencyContactEntityName = @"EmergencyContact";
NSString * const ShuttleRouteEntityName = @"ShuttleRouteCache";
NSString * const ShuttleStopEntityName = @"ShuttleStopLocation";
NSString * const ShuttleRouteStopEntityName = @"ShuttleRouteStop";
NSString * const CalendarEventEntityName = @"MITCalendarEvent";
NSString * const CalendarCategoryEntityName = @"EventCategory";
NSString * const CampusMapSearchEntityName = @"MapSearch";
NSString * const CampusMapAnnotationEntityName = @"MapSavedAnnotation";
NSString * const LibraryItemEntityName = @"LibraryItem";
NSString * const LibraryEntityName = @"Library";
NSString * const LibraryPhoneEntityName = @"LibraryPhone";

// local paths for handleLocalPath
NSString * const LocalPathMapsSelectedAnnotation = @"annotation";


// resource names

NSString * const ImageNameHomeScreenBackground = @"home/home-background.png";
NSString * const MITImageNameBackground      = @"global/body-background.png";

NSString * const MITImageNameEmail           = @"global/action-email.png";
NSString * const MITImageNameEmailHighlight  = @"global/action-email-highlight.png";
NSString * const MITImageNameMap             = @"global/action-map.png";
NSString * const MITImageNameMapHighlight    = @"global/action-map-highlight.png";
NSString * const MITImageNamePeople          = @"global/action-people.png";
NSString * const MITImageNamePeopleHighlight = @"global/action-people-highlight.png";
NSString * const MITImageNamePhone           = @"global/action-phone.png";
NSString * const MITImageNamePhoneHighlight  = @"global/action-phone-highlight.png";
NSString * const MITImageNameExternal           = @"global/action-external.png";
NSString * const MITImageNameExternalHighlight  = @"global/action-external-highlight.png";
NSString * const MITImageNameEmergency          = @"global/action-emergency.png";
NSString * const MITImageNameEmergencyHighlight = @"global/action-emergency-highlight.png";
NSString * const MITImageNameSecure           = @"global/action-secure.png";
NSString * const MITImageNameSecureHighlight  = @"global/action-secure-highlight.png";

NSString * const MITImageNameScrollTabBackgroundOpaque = @"global/scrolltabs-background-opaque.png";
NSString * const MITImageNameScrollTabBackgroundTranslucent = @"global/scrolltabs-background-transparent.png";
NSString * const MITImageNameScrollTabLeftEndCap = @"global/scrolltabs-leftarrow.png";
NSString * const MITImageNameScrollTabRightEndCap = @"global/scrolltabs-rightarrow.png";
NSString * const MITImageNameScrollTabSelectedTab = @"global/scrolltabs-selected.png";

NSString * const MITImageNameLeftArrow = @"global/arrow-white-left.png";
NSString * const MITImageNameRightArrow = @"global/arrow-white-right.png";
NSString * const MITImageNameUpArrow = @"global/arrow-white-up.png";
NSString * const MITImageNameDownArrow = @"global/arrow-white-down.png";

NSString * const MITImageNameSubheadBarBackground = @"global/subheadbar_background.png";

NSString * const MITImageNameSearch = @"global/search.png";
NSString * const MITImageNameBookmark = @"global/bookmark.png";

// errors
NSString * const MapsErrorDomain = @"com.modolabs.Maps.ErrorDomain";
NSString * const ShuttlesErrorDomain = @"com.modolabs.Shuttles.ErrorDomain";
NSString * const JSONErrorDomain = @"com.modolabs.JSON.ErrorDomain";

