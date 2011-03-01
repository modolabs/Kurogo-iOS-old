#import "PersonOrganization.h"

#import "KGOPerson.h"

@implementation PersonOrganization 

@dynamic department;
@dynamic organization;
@dynamic jobTitle;
@dynamic person;

- (NSDictionary *)dictionary {
    return [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"department", @"jobTitle", @"organization", nil]];
}

@end
