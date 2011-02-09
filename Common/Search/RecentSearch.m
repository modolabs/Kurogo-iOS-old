#import "RecentSearch.h"


@implementation RecentSearch 

@dynamic module;
@dynamic text;
@dynamic date;

- (NSString *)resultTitle {
	return self.text;
}

@end
