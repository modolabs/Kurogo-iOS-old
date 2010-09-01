/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

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
