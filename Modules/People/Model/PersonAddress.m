#import "PersonAddress.h"
#import "KGOPerson.h"

@implementation PersonAddress 

@dynamic person;

- (NSDictionary *)dictionary {
    return [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"city", @"country", @"zip", @"state", @"street", @"street2", @"label", @"displayAddress", nil]];
}

@end
