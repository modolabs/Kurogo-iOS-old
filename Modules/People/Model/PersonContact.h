#import "KGOContactInfo.h"

@class KGOPerson;

@interface PersonContact : KGOContactInfo
{
}

@property (nonatomic, retain) KGOPerson * person;

+ (NSArray *)directoryContacts;
+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType;
- (NSDictionary *)dictionary;

@end



