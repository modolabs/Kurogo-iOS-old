#import "PersonContact.h"
#import "KGOPerson.h"
#import "Foundation+KGOAdditions.h"

@implementation PersonContact 

@dynamic person;

+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType {
    PersonContact *contact = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonContactEntityName];
    contact.type = aType;
    contact.label = [aDict stringForKey:@"label"];
    contact.value = [aDict stringForKey:@"value"];
    return contact;
}

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.value, @"value",
            self.label, @"label", 
            self.type, @"type",
            self.identifier, @"identifier",
            nil];
}

@end
