#import "KGOModule.h"

@interface FacebookModule : KGOModule {
    
}

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
// TODO: move this to Common if we find this format used in other places
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)string;

@end
