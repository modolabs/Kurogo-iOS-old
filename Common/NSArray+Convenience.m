#import "NSArray+Convenience.h"


@implementation NSArray (Convenience)

#ifdef USE_MOBILE_DEV

- (id)safeObjectAtIndex:(NSUInteger)index
{
    return [self objectAtIndex:index];
}

#else

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

#endif

@end
