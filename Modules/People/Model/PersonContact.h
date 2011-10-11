#import "KGOContactInfo.h"

@class KGOPerson;
@class PersonContactGroup;

@interface PersonContact : KGOContactInfo
{
}

@property (nonatomic, retain) KGOPerson * person;
@property (nonatomic, retain) PersonContactGroup * contactGroup;

+ (NSArray *)directoryContacts;
+ (PersonContact *)personContactWithDictionary:(NSDictionary *)aDict type:(NSString *)aType;
- (NSDictionary *)dictionary;

@end



