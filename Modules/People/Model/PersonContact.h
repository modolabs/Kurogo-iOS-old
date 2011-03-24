#import "KGOContactInfo.h"
#import "CoreDataManager.h"

@class KGOPerson;

@interface PersonContact : KGOContactInfo
{
}

@property (nonatomic, retain) KGOPerson * person;

+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType;
- (NSDictionary *)dictionary;

@end



