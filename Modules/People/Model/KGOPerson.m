#import "KGOPerson.h"

#import "PersonAddress.h"
#import "PersonContact.h"
#import "PersonOrganization.h"
#import "CoreDataManager.h"

@implementation KGOPerson 

@dynamic photoURL;
@dynamic firstName;
@dynamic birthday;
@dynamic identifier;
@dynamic photo;
@dynamic name;
@dynamic lastName;
@dynamic viewed;
@dynamic organizations;
@dynamic addresses;
@dynamic contacts;

+ (KGOPerson *)personWithIdentifier:(NSString *)anIdentifier {
    KGOPerson *person = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOPersonEntityName];
    person.identifier = anIdentifier;
    return person;
}

@end
