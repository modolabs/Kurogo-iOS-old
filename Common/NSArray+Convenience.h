/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>

// Convenience methods for NSArray.

@interface NSArray (Convenience)

// Returns nil if the index goes past the end of the array instead of throwing an NSRangeException.
- (id)safeObjectAtIndex:(NSUInteger)index;

@end
