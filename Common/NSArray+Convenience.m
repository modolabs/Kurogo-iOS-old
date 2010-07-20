#import "NSArray+Convenience.h"


@implementation NSArray (Convenience)

- (id)safeObjectAtIndex:(NSUInteger)index
{
	if (self.count > index)
	{
		return [self objectAtIndex:index];
	}
	else 
	{
		return nil;
	}

}

@end
