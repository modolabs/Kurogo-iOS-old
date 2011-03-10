#import "RecentSearch.h"


@implementation RecentSearch 

@dynamic module;
@dynamic text;
@dynamic date;

- (NSString *)identifier {
    return nil;
}

- (NSString *)title {
	return self.text;
}

@end
