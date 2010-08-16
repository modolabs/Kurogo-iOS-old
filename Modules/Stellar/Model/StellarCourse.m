
#import "StellarCourse.h"

#import "StellarClass.h"

@implementation StellarCourse 

@dynamic lastCache;
@dynamic lastChecksum;
@dynamic number;
@dynamic title;
@dynamic stellarClasses;
@dynamic term;
@dynamic courseGroup;
@dynamic courseGroupShort;
//@synthesize groupArray;

- (NSComparisonResult)compare:(StellarCourse *)otherObject {
    return [self.title compare:otherObject.title];
}

@end
