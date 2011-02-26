#import <CoreData/CoreData.h>

@class PersonAddress;
@class PersonContact;
@class PersonOrganization;

@interface KGOPerson :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSDate * viewed;
@property (nonatomic, retain) NSSet* organizations;
@property (nonatomic, retain) NSSet* addresses;
@property (nonatomic, retain) NSSet* contacts;

+ (KGOPerson *)personWithIdentifier:(NSString *)anIdentifier;

@end


@interface KGOPerson (CoreDataGeneratedAccessors)
- (void)addOrganizationsObject:(PersonOrganization *)value;
- (void)removeOrganizationsObject:(PersonOrganization *)value;
- (void)addOrganizations:(NSSet *)value;
- (void)removeOrganizations:(NSSet *)value;

- (void)addAddressesObject:(PersonAddress *)value;
- (void)removeAddressesObject:(PersonAddress *)value;
- (void)addAddresses:(NSSet *)value;
- (void)removeAddresses:(NSSet *)value;

- (void)addContactsObject:(PersonContact *)value;
- (void)removeContactsObject:(PersonContact *)value;
- (void)addContacts:(NSSet *)value;
- (void)removeContacts:(NSSet *)value;

@end

