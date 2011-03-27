#import "Constants.h"

// local path names for handleLocalPath
NSString * const LocalPathPageNameHome = @"index";
NSString * const LocalPathPageNameDetail = @"detail";
NSString * const LocalPathPageNameSearch = @"search";
NSString * const LocalPathPageNameCategoryList = @"categories";
NSString * const LocalPathPageNameItemList = @"items";
NSString * const LocalPathPageNameMapList = @"map";
NSString * const LocalPathPageNameBookmarks = @"bookmarks";

// keys for NSUserDefaults dictionary go here (app preferences)
NSString * const DeviceTokenKey = @"DeviceToken";
NSString * const UnreadNotificationsKey = @"UnreadNotifications";


// module tags
NSString * const AboutTag      = @"about";
NSString * const CalendarTag   = @"calendar";
NSString * const CoursesTag    = @"courses";
NSString * const DiningTag	   = @"dining";
NSString * const EmergencyTag  = @"emergency";
NSString * const FullWebTag    = @"fullweb";
NSString * const HomeTag       = @"home";
NSString * const LibrariesTag  = @"libraries";
NSString * const MapTag        = @"map";
NSString * const NewsTag       = @"news";
NSString * const PeopleTag     = @"people";
NSString * const SchoolsTag    = @"schools";
NSString * const SettingsTag   = @"settings";
NSString * const TransitTag    = @"transit";
NSString * const PhotosTag     = @"photos";
NSString * const LoginTag      = @"login";
NSString * const VideoTag     = @"video";
NSString * const ContentTag    = @"content";
NSString * const AdmissionsTag    = @"admissions";



// preferences

NSString * const ShakeToReturnPrefKey = @"ShakeToReturnHome";
NSString * const MapTypePrefKey = @"MapTypePreference";
NSString * const MITNewsTwoFirstRunKey = @"MITNews2ClearedCachedArticles";

// notification names

NSString * const ModuleListDidChangeNotification = @"ModuleList";

// core data entity names
NSString * const KGOPersonEntityName = @"KGOPerson";
NSString * const PersonContactEntityName = @"PersonContact";
NSString * const PersonOrganizationEntityName = @"PersonOrganization";
NSString * const PersonAddressEntityName = @"PersonAddress";

NSString * const KGOPlacemarkEntityName = @"KGOPlacemark";
NSString * const MapCategoryEntityName = @"KGOMapCategory";

NSString * const NewsStoryEntityName = @"NewsStory";
NSString * const NewsCategoryEntityName = @"NewsCategory";
NSString * const NewsImageEntityName = @"NewsImage";
NSString * const NewsImageRepEntityName = @"NewsImageRep";


// local paths for handleLocalPath
NSString * const LocalPathMapsSelectedAnnotation = @"annotation";


// resource names

NSString * const MITImageNameUpArrow = @"global/arrow-white-up.png";
NSString * const MITImageNameDownArrow = @"global/arrow-white-down.png";

// errors
NSString * const MapsErrorDomain = @"com.modolabs.Maps.ErrorDomain";
NSString * const ShuttlesErrorDomain = @"com.modolabs.Shuttles.ErrorDomain";
NSString * const JSONErrorDomain = @"com.modolabs.JSON.ErrorDomain";

