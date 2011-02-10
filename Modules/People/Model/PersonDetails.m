#import "PersonDetails.h"
#import "CoreDataManager.h"
#import "PeopleRecentsData.h"

#define kPersonUIDLength 44

NSString * const kPersonDetailsValueSeparatorToken = @"%/%";

@implementation PersonDetails 

@dynamic viewed;

@dynamic lastUpdate;
@dynamic mail;
@dynamic cn;
@dynamic uid;
@dynamic facsimiletelephonenumber;
@dynamic jobTitle;
@dynamic telephonenumber;
@dynamic sn;
@dynamic postaladdress;
@dynamic ou;
@dynamic givenname;

#pragma mark KGOSearchResult

- (NSString *)title {
    return self.cn;
}

- (NSString *)subtitle {
    if (self.jobTitle.length)
        return self.jobTitle;
    else if (self.ou.length)
        return self.ou;
    return nil;
}

#pragma mark -

// TODO: rewrite this to use appropriate fields
+ (PersonDetails *)personDetailsWithDictionary:(NSDictionary *)dictionary {
    NSString *uidString = [dictionary objectForKey:@"uid"];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uid == %@)", uidString];
	PersonDetails *person = [[[CoreDataManager sharedManager] objectsForEntity:PersonDetailsEntityName matchingPredicate:pred] lastObject];
    if (!person) {
        person = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonDetailsEntityName];
        person.uid = uidString;
    }
    NSString *value = [[dictionary objectForKey:@"cn"] lastObject];
    if (![value isEqualToString:person.cn]) {
        person.cn = value;
    }
    if (![(value = [[dictionary objectForKey:@"ou"] lastObject]) isEqualToString:person.ou]) {
        person.ou = value;
    }
    if (![(value = [[dictionary objectForKey:@"title"] lastObject]) isEqualToString:person.jobTitle]) {
        person.jobTitle = value;
    }
    if (![(value = [[dictionary objectForKey:@"telephonenumber"] lastObject]) isEqualToString:person.telephonenumber]) {
        person.telephonenumber = value;
    }
    if (![(value = [[dictionary objectForKey:@"postaladdress"] lastObject]) isEqualToString:person.postaladdress]) {
        person.postaladdress = value;
    }
    if (![(value = [[dictionary objectForKey:@"givenname"] lastObject]) isEqualToString:person.givenname]) {
        person.givenname = value;
    }
    if (![(value = [[dictionary objectForKey:@"sn"] lastObject]) isEqualToString:person.sn]) {
        person.sn = value;
    }
    if (![(value = [[dictionary objectForKey:@"mail"] lastObject]) isEqualToString:person.mail]) {
        person.mail = value;
    }
    if (![(value = [[dictionary objectForKey:@"facsimiletelephonenumber"] lastObject]) isEqualToString:person.facsimiletelephonenumber]) {
        person.facsimiletelephonenumber = value;
    }
    return person;
}



- (NSString *)formattedValueForKey:(NSString *)key
{
    NSString *actualValue = [self valueForKey:key];
    NSString *formattedValue = nil;

    if (actualValue) {
        
        // Replace with the token used to join multiple values for storage in a PersonDetails field with line breaks.
        formattedValue = [actualValue stringByReplacingOccurrencesOfString:kPersonDetailsValueSeparatorToken withString:@"\n"];
        
        if ([key isEqualToString:@"sn"] || [key isEqualToString:@"givenname"] || [key isEqualToString:@"cn"])
        {
            // For names, use slashes instead of line breaks.
            formattedValue = [actualValue stringByReplacingOccurrencesOfString:kPersonDetailsValueSeparatorToken withString:@"/"];		
        }
        else if ([key isEqualToString:@"postaladdress"])
        {
            formattedValue = [[formattedValue stringByReplacingOccurrencesOfString:@"$" withString:@"\n"]				
                              stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        else if ([key isEqualToString:@"ou"])
        {
            formattedValue = [formattedValue stringByReplacingOccurrencesOfString:@"^" withString:@" / "];
        }
    }
    return formattedValue;
}

- (NSString *)displayNameForKey:(NSString *)key
{
    NSDictionary *lookup = nil;
    NSString *result = nil;
    
    if (lookup = [[PeopleRecentsData sharedData] displayFields]) {
        result = [lookup objectForKey:key];
    }
    
    if (result)
        return result;
    
    return key;
}

+ (NSString *)trimUID:(NSString *)theUID {
	if (theUID.length > kPersonUIDLength) {
		theUID = [theUID substringToIndex:kPersonUIDLength - 1];
	}
	return theUID;
}

+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key
{
    NSString *joinedValue = [[jsonDict objectForKey:key]
                             componentsJoinedByString:kPersonDetailsValueSeparatorToken];
    if ([key isEqualToString:@"telephonenumber"] || [key isEqualToString:@"facsimiletelephonenumber"] || [key isEqualToString:@"mail"])
        joinedValue = [joinedValue stringByReplacingOccurrencesOfString:@"\n" withString:kPersonDetailsValueSeparatorToken];

    return joinedValue;
}

// this is the counterpart of the above function, but grabs value for the instance.
// TODO: make the above function an instance method so the caller doesn't have to
// make an additional step to set the value
- (NSArray *)separatedValuesForKey:(NSString *)key {
    NSString *storedValue = [self valueForKey:key];
    return [storedValue componentsSeparatedByString:kPersonDetailsValueSeparatorToken];
}

@end
