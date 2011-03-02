#import "PersonOrganization.h"

#import "KGOPerson.h"

@implementation PersonOrganization 

@dynamic department;
@dynamic organization;
@dynamic jobTitle;
@dynamic person;

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"department", @"jobTitle", @"organization", nil]],
            @"value", nil];
}

@end
