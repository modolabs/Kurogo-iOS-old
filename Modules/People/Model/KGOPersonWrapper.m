#import "KGOPersonWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "KGOPerson.h"
#import "CoreDataManager.h"
#import "PersonContact.h"

#define MAX_PEOPLE_RESULTS 25

NSString * const KGOPersonContactTypeEmail = @"email";
NSString * const KGOPersonContactTypePhone = @"phone";
NSString * const KGOPersonContactTypeIM = @"im";
NSString * const KGOPersonContactTypeURL = @"url";

@interface KGOPersonWrapper (Private)

+ (BOOL)isValidAddressDict:(id)aDict;
+ (BOOL)isValidOrganizationDict:(id)aDict;
+ (BOOL)isValidContactDict:(id)aDict;

- (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property;
- (id)getRecordProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;
- (BOOL)setRecordValue:(id)value forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;
- (ABPropertyType)abPropertyTypeForClass:(Class)class;
- (Class)classForABPropertyType:(ABPropertyType)type;
- (BOOL)setMultiValue:(NSArray *)values forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;

@end


@implementation KGOPersonWrapper

@synthesize identifier = _identifier,
name = _name,
firstName = _firstName,
lastName = _lastName,
birthday = _birthday,
photo = _photo,
photoURL = _photoURL,
organizations = _organizations,
addresses = _addresses,
phones = _phones,
emails = _emails,
screennames = _screennames,
webpages = _webpages;

- (void)dealloc {

    [_identifier release];
    [_name release];
    
    [_firstName release];
    [_lastName release];
    [_birthday release];
    [_organizations release];
    [_addresses release];
    [_photo release];
    [_photoURL release];
    [_phones release];
    [_emails release];
    [_screennames release];
    [_webpages release];
    
    [_kgoPerson release];
    
    CFRelease(_ab);
    CFRelease(_abRecord);
    
    [super dealloc];
}

#pragma mark KGOSearchResult

- (NSString *)title {
    return self.name;
}

#pragma mark -
#pragma mark Dictionary representation

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.firstName = [dictionary stringForKey:@"firstName"];
        self.lastName = [dictionary stringForKey:@"lastName"];
        self.birthday = [dictionary dateForKey:@"birthday" format:@"yyyyMMdd"];
        self.photoURL = [dictionary stringForKey:@"photoURL"];

        NSMutableArray *array = [NSMutableArray array];
        for (id aDict in [dictionary arrayForKey:@"organizations"]) {
            if ([KGOPersonWrapper isValidOrganizationDict:aDict])
                [array addObject:aDict];
        }
        if (array.count)
            self.organizations = array;
        
        array = [NSMutableArray array];
        for (id aDict in [dictionary arrayForKey:@"addresses"]) {
            if ([KGOPersonWrapper isValidAddressDict:aDict])
                [array addObject:aDict];
        }
        if (array.count)
            self.addresses = array;
        
        _phones = [[NSMutableArray alloc] init];
        _emails = [[NSMutableArray alloc] init];
        _webpages = [[NSMutableArray alloc] init];
        _screennames = [[NSMutableArray alloc] init];
        
        for (NSDictionary *aDict in [dictionary arrayForKey:@"contacts"]) {
            if ([KGOPersonWrapper isValidContactDict:aDict]) {
                NSString *type = [aDict stringForKey:@"type"];
                if ([type isEqualToString:KGOPersonContactTypePhone]) {
                    [_phones addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeEmail]) {
                    [_emails addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeURL]) {
                    [_webpages addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeIM]) {
                    [_screennames addObject:aDict];
                }
            }
        }
    }
    return self;
}

+ (BOOL)isValidAddressDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]]
        && ([aDict stringForKey:@"displayAddress"] || [aDict stringForKey:@"street"] || [aDict stringForKey:@"city"]
            || [aDict stringForKey:@"state"] || [aDict stringForKey:@"zip"] || [aDict stringForKey:@"country"]);
}

+ (BOOL)isValidOrganizationDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]]
        && ([aDict stringForKey:@"department"] || [aDict stringForKey:@"organization"] || [aDict stringForKey:@"jobTitle"]);
}

+ (BOOL)isValidContactDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]] && [aDict stringForKey:@"label"] && [aDict stringForKey:@"value"];
}

#pragma mark -
#pragma mark Core Data representation

- (id)initWithKGOPerson:(KGOPerson *)person {
    self = [super init];
    if (self) {
        self.KGOPerson = person;
    }
    return self;
}

- (void)saveToCoreData {
    [self convertToKGOPerson]; // make sure we have a reference to the NSManagedObject
    
    [[CoreDataManager sharedManager] saveData];
}

- (KGOPerson *)KGOPerson {
    return _kgoPerson;
}

- (void)setKGOPerson:(KGOPerson *)person {
    if (_kgoPerson != person) {
        [_kgoPerson release];
        _kgoPerson = [person retain];
    }
    self.firstName = _kgoPerson.firstName;
    self.lastName = _kgoPerson.lastName;
    self.birthday = _kgoPerson.birthday;
    self.photo = _kgoPerson.photo;
    
    NSMutableArray *array = [NSMutableArray array];
    for (PersonOrganization *organization in _kgoPerson.organizations) {
        [array addObject:[organization dictionary]];
    }
    self.organizations = [NSArray arrayWithArray:array];
    
    array = [NSMutableArray array];
    for (PersonAddress *address in _kgoPerson.addresses) {
        [array addObject:[address dictionary]];
    }
    self.addresses = [NSArray arrayWithArray:array];
    
    _phones = [[NSMutableArray alloc] init];
    _emails = [[NSMutableArray alloc] init];
    _webpages = [[NSMutableArray alloc] init];
    _screennames = [[NSMutableArray alloc] init];
    
    for (PersonContact *aContact in _kgoPerson.contacts) {
        if ([aContact.type isEqualToString:KGOPersonContactTypePhone]) {
            [_phones addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeEmail]) {
            [_emails addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeURL]) {
            [_webpages addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeIM]) {
            [_screennames addObject:[aContact dictionary]];
        }
    }
}

- (KGOPerson *)convertToKGOPerson {
    if (!_kgoPerson) {
        _kgoPerson = [[KGOPerson personWithIdentifier:_identifier] retain];
    }
    _kgoPerson.firstName = self.firstName;
    _kgoPerson.lastName = self.lastName;
    _kgoPerson.birthday = self.birthday;
    _kgoPerson.photo = self.photo;
    
    for (NSDictionary *aDict in _organizations) {
        _kgoPerson.organizations;
    }
    
    for (NSDictionary *aDict in _addresses) {
        _kgoPerson.addresses;
    }
    
    NSMutableSet *allContacts = [NSMutableSet set];
    
    for (NSDictionary *aDict in _phones) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypePhone]];
    }
    for (NSDictionary *aDict in _emails) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeEmail]];
    }
    for (NSDictionary *aDict in _webpages) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeURL]];
    }
    for (NSDictionary *aDict in _screennames) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeIM]];
    }
    
    _kgoPerson.contacts = allContacts;
    
    return _kgoPerson;
}

#pragma mark Core Data class methods

+ (KGOPersonWrapper *)personWithUID:(NSString *)uid
{
	KGOPersonWrapper *person = [[CoreDataManager sharedManager] getObjectForEntity:KGOPersonEntityName attribute:@"uid" value:uid];
	return person;
}

+ (void)clearRecentlyViewed {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed = YES"];
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred];
    for (KGOPerson *person in results) {
        [[CoreDataManager sharedManager] deleteObject:person];
    }
    [[CoreDataManager sharedManager] saveData];
}

+ (void)clearOldResults {
    // if the person's result was viewed over X days ago, remove it
    // TODO: configure these timeouts and MAX_PEOPLE_RESULTS
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:-1500000];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed = NO OR lastUpdate < %@", timeout];
    NSArray *sort = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO] autorelease]];
    
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred sortDescriptors:sort];
    if (results.count > MAX_PEOPLE_RESULTS) {
        for (KGOPerson *person in [results subarrayWithRange:NSMakeRange(MAX_PEOPLE_RESULTS, results.count - MAX_PEOPLE_RESULTS)]) {
            [[CoreDataManager sharedManager] deleteObject:person];
        }
        [[CoreDataManager sharedManager] saveData];
    }
}

+ (NSArray *)fetchRecentlyViewed {
    NSMutableArray *recents = [NSMutableArray array];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed = YES"];
    NSArray *sort = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO] autorelease]];
    NSArray *storedPeople = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred sortDescriptors:sort];
    for (KGOPerson *person in storedPeople) {
        KGOPersonWrapper *personWrapper = [[[KGOPersonWrapper alloc] initWithKGOPerson:person] autorelease];
        [recents addObject:personWrapper];
    }
    return recents;
}

#pragma mark -
#pragma mark Address Book representation

- (id)initWithABRecord:(ABRecordRef)record {
    
    if (ABRecordGetRecordType(record) != kABPersonType) {
        NSLog(@"attempted to initialize KGOPerson with a non-person Address Book record");
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        _ab = ABAddressBookCreate();
        _abRecord = CFRetain(record);
        
        _firstName = [self getRecordProperty:kABPersonFirstNameProperty expectedClass:[NSString class]];
        _lastName = [self getRecordProperty:kABPersonLastNameProperty expectedClass:[NSString class]];
        _birthday = [self getRecordProperty:kABPersonDepartmentProperty expectedClass:[NSDate class]];
        
        if (ABPersonHasImageData(_abRecord)) {
            // if on iOS 4.1 and later, we can use
            // ABPersonCopyImageDataWithFormat(_abRecord, kABPersonImageFormatThumbnail)
            CFDataRef imageData = ABPersonCopyImageData(_abRecord);
            _photo = [(NSData *)imageData copy];
            CFRelease(imageData);
        }
        
        
        _phones = [self getRecordProperty:kABPersonPhoneProperty expectedClass:[NSArray class]];
        _emails = [self getRecordProperty:kABPersonEmailProperty expectedClass:[NSArray class]];
        _screennames = [self getRecordProperty:kABPersonInstantMessageProperty expectedClass:[NSArray class]];
        _webpages = [self getRecordProperty:kABPersonURLProperty expectedClass:[NSArray class]];
    }
    return self;
}

- (ABRecordRef)ABPerson {
    return _abRecord;
}

- (ABRecordRef)convertToABPerson {
    if (!_ab) {
        _ab = ABAddressBookCreate();
    }
    if (!_abRecord) {
        _abRecord = ABPersonCreate();
    }
    if (_firstName)    [self setRecordValue:_firstName forProperty:kABPersonFirstNameProperty expectedClass:[NSString class]];
    if (_lastName)     [self setRecordValue:_lastName forProperty:kABPersonLastNameProperty expectedClass:[NSString class]];
    if (_birthday)     [self setRecordValue:_birthday forProperty:kABPersonOrganizationProperty expectedClass:[NSDate class]];
    
    if (_photo) {
        CFErrorRef error = NULL;
        if (!ABPersonSetImageData(_abRecord, (CFDataRef)_photo, &error)) {
            NSLog(@"could not set image data");
        }
    }
    
    if (_addresses);
    if (_organizations);
    
    if (_phones)       [self setMultiValue:_phones forProperty:kABPersonPhoneProperty expectedClass:[NSString class]];
    if (_emails)       [self setMultiValue:_emails forProperty:kABPersonEmailProperty expectedClass:[NSString class]];
    if (_screennames)  [self setMultiValue:_screennames forProperty:kABPersonInstantMessageProperty expectedClass:[NSString class]];
    if (_webpages)     [self setMultiValue:_webpages forProperty:kABPersonURLProperty expectedClass:[NSString class]];
    
    return _abRecord;
}

- (void)setABPerson:(ABRecordRef)person {
    if (!_ab) {
        _ab = ABAddressBookCreate();
    }
    if (person != _abRecord) {
        CFRelease(_abRecord);
        _abRecord = CFRetain(person);
    }
}

- (void)addMultiValue:(NSDictionary *)valueDict forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    [self convertToABPerson]; // make sure we have a reference to the address book

    NSString *label = [valueDict objectForKey:@"label"];
    NSString *value = [valueDict objectForKey:@"value"];
    
    // check value against user declared class
    if (![value isKindOfClass:expectedClass])
        return;
    
    // check user declared class against address book class
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    if ((usableType | kABMultiValueMask) != (internalType | kABMultiValueMask))
        return;
    
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(property);
    NSArray *allValues = (NSArray *)ABMultiValueCopyArrayOfAllValues(multi);
    if (![allValues containsObject:value]) {
        ABMultiValueAddValueAndLabel(multi, value, (CFStringRef)label, NULL);
    }
    [allValues release];
}

- (ABPropertyType)abPropertyTypeForClass:(Class)class {
    if (class == [NSString class])
        return kABStringPropertyType;
    if (class == [NSDate class])
        return kABDateTimePropertyType;
    if (class == [NSArray class])
        return kABMultiValueMask;
    // i haven't seen use cases for integer/real/dictionary
    return kABInvalidPropertyType;
}

- (Class)classForABPropertyType:(ABPropertyType)type {
    if ((type | kABMultiValueMask) == (kABStringPropertyType | kABMultiValueMask))
        return [NSString class];
    if ((type | kABMultiValueMask) == (kABDateTimePropertyType | kABMultiValueMask))
        return [NSDate class];
    return [NSNull class]; // something that will fail every check
}

- (BOOL)setRecordValue:(id)value forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    if (![value isKindOfClass:expectedClass])
        return NO;
    
    BOOL success = NO;
    [self convertToABPerson]; // make sure we have a reference to the address book
    CFErrorRef error = NULL;

    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    
    if ((internalType & kABMultiValueMask) && (usableType & kABMultiValueMask)) {
        success = [self setMultiValue:value forProperty:property expectedClass:[self classForABPropertyType:internalType]];
        
    } else if (internalType == usableType) {
        success = ABRecordSetValue(_abRecord, property, value, &error);
        if (!success) {
            NSLog(@"error setting value %@", value);
        }
    }
    
    return success;
}

- (BOOL)setMultiValue:(NSArray *)values forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    if ((usableType | kABMultiValueMask) != (internalType | kABMultiValueMask))
        return NO;
    
    [self ABPerson]; // make sure we have a reference to the address book
    BOOL success = NO;
    CFErrorRef error = NULL;

    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(property);
    for (NSDictionary *aDict in values) {
        // TODO: use only valid label strings -- home, work, etc.
        NSString *label = [aDict objectForKey:@"label"];
        id value = [aDict objectForKey:@"value"];
        if ([value isKindOfClass:expectedClass]) {
            ABMultiValueAddValueAndLabel(multi, (CFTypeRef)value, (CFStringRef)label, NULL);
        }
    }
    success = ABRecordSetValue(_abRecord, property, multi, &error);
    if (!success) {
        NSLog(@"error setting values %@", values);
    }
    CFRelease(multi);
    return success;
}

- (id)getRecordProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    [self convertToABPerson]; // make sure we have a reference to the address book
    id result = nil;
    CFTypeRef value = ABRecordCopyValue(_abRecord, property);
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    
    if ((internalType & kABMultiValueMask) && (usableType & kABMultiValueMask)) {
        if (expectedClass == [NSArray class])
            result = [self getMultiValueRecordProperty:property];
        
    } else if (internalType == usableType)  {
        result = [[(id)value copy] autorelease];
    }
    CFRelease(value);
    return result;
}

- (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property {
    [self convertToABPerson]; // make sure we have a reference to the address book
    NSMutableArray *result = nil;
    
    ABMultiValueRef multi = ABRecordCopyValue(_abRecord, property);
    if (multi) {
        CFIndex count = ABMultiValueGetCount(multi);
        result = [NSMutableArray arrayWithCapacity:count];
        
        for (CFIndex i = 0; i < count; i++) {
            NSDictionary *valueSet = nil;
            
            CFStringRef label = ABMultiValueCopyLabelAtIndex(multi, i);
            CFTypeRef value = ABMultiValueCopyValueAtIndex(multi, i);
            
            if (label) {
                valueSet = [NSDictionary dictionaryWithObjectsAndKeys:(NSString *)label, @"label", (id)value, @"value", nil];
            } else if (value) {
                valueSet = [NSDictionary dictionaryWithObjectsAndKeys:(id)value, @"value", nil];
            }
            
            if (valueSet) {
                [result addObject:valueSet];
            }
            
            CFRelease(label);
            CFRelease(value);
        }
    }
    CFRelease(multi);
    
    return result;
}

- (BOOL)saveToAddressBook {
    BOOL success = YES; // if there are no changes just say we succeeded
    [self convertToABPerson]; // make sure we have a reference to the address book
    
    if (ABAddressBookHasUnsavedChanges(_ab)) {
        CFErrorRef error = NULL;
        success = ABAddressBookSave(_ab, &error);
    }
    return success;
}

@end
