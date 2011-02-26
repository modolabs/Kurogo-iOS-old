#import "KGOContact.h"
#import "CoreDataManager.h"

@class KGOPerson;

@interface PersonContact : KGOContact
{
}

@property (nonatomic, retain) KGOPerson * person;

+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType;
- (NSDictionary *)dictionary;

@end



