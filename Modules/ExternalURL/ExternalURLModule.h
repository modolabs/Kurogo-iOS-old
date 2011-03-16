// special case of KGOModule that has no interior pages and opens Safari instead

#import <Foundation/Foundation.h>
#import "KGOModule.h"

@interface ExternalURLModule : KGOModule {

}

@property(nonatomic, retain) NSString *url;

@end
