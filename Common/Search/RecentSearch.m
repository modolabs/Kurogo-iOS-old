#import "RecentSearch.h"


@implementation RecentSearch 

@dynamic module;
@dynamic text;
@dynamic date;

- (NSString *)title {
	return self.text;
}

@end
