#import "PersonContact.h"
#import "KGOPerson.h"
#import "Foundation+KGOAdditions.h"

@implementation PersonContact 

@dynamic person;

+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType {
    PersonContact *contact = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonContactEntityName];
    contact.type = aType;
    contact.label = [aDict stringForKey:@"label" nilIfEmpty:YES];
    contact.value = [aDict stringForKey:@"value" nilIfEmpty:YES];
    return contact;
}

- (NSDictionary *)dictionary {
    return [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"value", @"label", @"type", @"identifier", nil]];
}

@end
