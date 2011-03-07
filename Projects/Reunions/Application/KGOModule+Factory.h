#import "KGOModule.h"

@interface KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args;

@end