#import "PersonContact.h"
#import "KGOPerson.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

@implementation PersonContact 

@dynamic person;

+ (NSArray *)directoryContacts 
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"person = nil"];
    return [[CoreDataManager sharedManager] objectsForEntity:PersonContactEntityName matchingPredicate:pred];
}

+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType {
    PersonContact *contact = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonContactEntityName];
    contact.type = aType;
    contact.identifier = [aDict stringForKey:@"id" nilIfEmpty:YES];
    contact.label = [aDict stringForKey:@"label" nilIfEmpty:YES];
    contact.value = [aDict stringForKey:@"value" nilIfEmpty:YES];
    return contact;
}

- (NSDictionary *)dictionary {
    return [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"value", @"label", @"type", @"identifier", nil]];
}

@end
