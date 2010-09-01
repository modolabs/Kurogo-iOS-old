/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "AddressFormatter.h"


@implementation AddressFormatter

+ (NSString *)streetAddressFromAddressBlockText:(NSString *)addressBlock {
	
	NSArray *addressLines = [addressBlock componentsSeparatedByString:@"\n"];
	// Assumes the street address is the next-to-last line in the block.
	if (addressLines.count > 1) {
		return [addressLines objectAtIndex:addressLines.count - 2];
	}

	return @"";
}

@end
