#import <CoreData/CoreData.h>

@class KGOPerson;

@interface PersonOrganization :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * department;
@property (nonatomic, retain) NSString * organization;
@property (nonatomic, retain) NSString * jobTitle;
@property (nonatomic, retain) KGOPerson * person;

- (NSDictionary *)dictionary;

@end



