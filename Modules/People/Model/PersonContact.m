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
    contact.url = [aDict stringForKey:@"url" nilIfEmpty:YES];
    contact.title = [aDict stringForKey:@"title" nilIfEmpty:YES];
    contact.subtitle = [aDict stringForKey:@"subtitle" nilIfEmpty:YES];
    contact.group = [aDict stringForKey:@"group" nilIfEmpty:YES];
    return contact;
}

- (NSDictionary *)dictionary {
    return [self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"subtitle", @"title", @"type", @"identifier", nil]];
}

@end
