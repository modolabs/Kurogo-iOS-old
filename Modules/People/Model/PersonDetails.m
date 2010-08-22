#import "PersonDetails.h"
#import "CoreDataManager.h"
#import "PeopleRecentsData.h"

#define kPersonUIDLength 44

NSString * const kPersonDetailsValueSeparatorToken = @"%/%";

@implementation PersonDetails 

@dynamic lastUpdate;
@dynamic mail;
@dynamic cn;
@dynamic uid;
@dynamic facsimiletelephonenumber;
@dynamic title;
@dynamic telephonenumber;
@dynamic sn;
@dynamic postaladdress;
@dynamic ou;
@dynamic givenname;

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

// figure out if we already have this person in Favorites
// (CoreDataManager.h does not do selecting by criteria yet)
// this creates an insertedObject that needs to be committed or rolled back in results view
+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult
{
	NSString *uidString = [selectedResult objectForKey:@"uid"];
        
	uidString = [PersonDetails trimUID:uidString];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uid == %@)", uidString];
	NSArray *results = [CoreDataManager objectsForEntity:PersonDetailsEntityName matchingPredicate:pred];
    
	if ([results count] == 0)
		return [PeopleRecentsData createFromSearchResult:selectedResult];
	else 
		return [results objectAtIndex:0];
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
