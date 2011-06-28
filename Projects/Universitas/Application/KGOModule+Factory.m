#import "KGOModule+Factory.h"
#import "KGOModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "EmergencyModule.h"
#import "ExternalURLModule.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import "NewsModule.h"
#import	"MapModule.h"
#import "PeopleModule.h"
#import "ContentModule.h"
#import "SettingsModule.h"
#import "VideoModule.h"
#import "LinksModule.h"

@implementation KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    if (!className) {
        NSDictionary *moduleMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"AboutModule", @"about",
                                   @"CalendarModule", @"calendar",
                                   @"ContentModule", @"content",
                                   @"HomeModule", @"home",
                                   @"EmergencyModule", @"emergency",
                                   @"ExternalURLModule", @"fullweb",
                                   @"LoginModule", @"login",
                                   @"MapModule", @"map",
                                   @"NewsModule", @"news",
                                   @"PeopleModule", @"people",
                                   @"SettingsModule", @"customize",
                                   @"VideoModule", @"video",
                                   @"LinksModule", @"links",
                                   nil];
        
        NSString *serverID = [args objectForKey:@"id"];
        className = [moduleMap objectForKey:serverID];
    }

    if (className) {
        Class moduleClass = NSClassFromString(className);
        if (moduleClass) {
            module = [[[moduleClass alloc] initWithDictionary:args] autorelease];
        }
    }
    
    if (!module) {
        DLog(@"could not initialize module with params: %@", [args description]);
    }
    
    return module;
}

@end
