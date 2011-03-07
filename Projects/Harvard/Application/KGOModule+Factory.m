#import "KGOModule+Factory.h"
#import "KGOModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "CoursesModule.h"
#import "DiningModule.h"
#import "FullWebModule.h"
#import "HomeModule.h"
#import "LibrariesModule.h"
#import "NewsModule.h"
#import	"MapModule.h"
#import "PeopleModule.h"
#import "SchoolsModule.h"
#import "SettingsModule.h"
#import "TransitModule.h"

@implementation KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    
    if ([className isEqualToString:@"AboutModule"])
        module = [[[AboutModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"CalendarModule"])
        module = [[[CalendarModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"CoursesModule"])
        module = [[[CoursesModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"DiningModule"])
        module = [[[DiningModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FullWebModule"])
        module = [[[FullWebModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"HomeModule"])
        module = [[[HomeModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"LibrariesModule"])
        module = [[[LibrariesModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"MapModule"])
        module = [[[MapModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"NewsModule"])
        module = [[[NewsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"PeopleModule"])
        module = [[[PeopleModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"SchoolsModule"])
        module = [[[SchoolsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"SettingsModule"])
        module = [[[SettingsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"TransitModule"])
        module = [[[TransitModule alloc] initWithDictionary:args] autorelease];
    
    return module;
}

@end
