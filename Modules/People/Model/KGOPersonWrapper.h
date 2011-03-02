#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "KGOSearchModel.h"

@class KGOPerson;

@interface KGOPersonWrapper : NSObject <KGOSearchResult> {
    
    ABAddressBookRef _ab;
    ABRecordRef _abRecord;
    
    KGOPerson *_kgoPerson;
    
    // core data only properties
    NSString *_identifier;
    NSString *_name;
    NSString *_photoURL;
    
    // single field properties
    NSString *_firstName;
    NSString *_lastName;
    NSDate *_birthday;
    NSData *_photo;

    // multivalue object with only one instance in address book
    NSArray *_organizations;

    // disaggregated PersonContact objects (multiple strings in address book)
    NSMutableArray *_phones;
    NSMutableArray *_emails;
    NSMutableArray *_screennames; // for instant messenger clients
    NSMutableArray *_webpages;

    // multiple dicitonaries in address book
    NSMutableArray *_addresses;
}

// core data only properties
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *photoURL;

// single field properties
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSDate *birthday;
@property (nonatomic, copy) NSData *photo;

// multivalue objects with only one instance in address book
@property (nonatomic, retain) NSArray *addresses;
@property (nonatomic, retain) NSArray *organizations;

// disaggregated PersonContact objects
@property (nonatomic, retain) NSArray *phones;
@property (nonatomic, retain) NSArray *emails;
@property (nonatomic, retain) NSArray *screennames;
@property (nonatomic, retain) NSArray *webpages;

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (NSString *)displayAddressForDict:(NSDictionary *)addressDict;

// address book

- (id)initWithABRecord:(ABRecordRef)record;
- (BOOL)saveToAddressBook;
- (ABRecordRef)convertToABPerson;

@property (nonatomic) ABRecordRef ABPerson; // setting this does not override values

// core data

- (id)initWithKGOPerson:(KGOPerson *)person;
- (void)markAsRecentlyViewed;
- (KGOPerson *)convertToKGOPerson;
- (void)saveToCoreData;

@property (nonatomic, retain) KGOPerson *KGOPerson; // setting this will override values

+ (KGOPersonWrapper *)personWithUID:(NSString *)uid;
+ (void)clearRecentlyViewed;
+ (void)clearOldResults;
+ (NSArray *)fetchRecentlyViewed;

@end
