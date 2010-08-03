#import "PersonDetails+Methods.h"
#import "CoreDataManager.h"
#import "PeopleRecentsData.h"
#import "PersonDetail.h"

@implementation PersonDetails (Methods)

- (id)actualValueForKey:(NSString *)key
{
    id valueObject = [self valueForKey:key];
    if ([valueObject isKindOfClass:[PersonDetail class]]) {
        return [valueObject Value];
    }
    return valueObject;   
}

- (NSString *)formattedValueForKey:(NSString *)key
{
    id actualValue = [self actualValueForKey:key];
    
    if (![actualValue isKindOfClass:[NSString class]])
    {
        NSAssert(FALSE, @"I don't know how to format this value."); 
        return nil;
    }
                
    if ([key isEqualToString:@"postaladdress"])
    {
        return [[actualValue stringByReplacingOccurrencesOfString:@"$" withString:@"\n"]				
				stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    else if ([key isEqualToString:@"title"])
    {
        return [actualValue stringByReplacingOccurrencesOfString:kPersonDetailsValueSeparatorToken withString:@"\n"];		
    }
    else if ([key isEqualToString:@"ou"])
    {
        return [[actualValue stringByReplacingOccurrencesOfString:kPersonDetailsValueSeparatorToken withString:@"\n"]
				stringByReplacingOccurrencesOfString:@"^" withString:@" / "];
    }
	
    return actualValue;
}

- (NSString *)displayNameForKey:(NSString *)key
{
    id detailObject = [self valueForKey:key];
    if ([detailObject isKindOfClass:[PersonDetail class]]) {
        return [detailObject DisplayName];
    }
    // There is no display name for this. Just give use the key.
    return key;    
}

// figure out if we already have this person in Favorites
// (CoreDataManager.h does not do selecting by criteria yet)
// this creates an insertedObject that needs to be committed or rolled back in results view
+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult
{
	NSString *uid = [PersonDetails joinedValueFromPersonDetailsJSONDict:selectedResult 
                                                                 forKey:@"uid"];
	uid = [PersonDetails trimUID:uid];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uid.Value == %@)", uid];
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

+ (NSArray *)realValuesFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key {
	id detailObject = [jsonDict objectForKey:key];
	if ([detailObject respondsToSelector:@selector(objectForKey:)])
	{
		NSArray *values = [detailObject objectForKey:@"Values"];
		if ([values isKindOfClass:[NSArray class]]) {
			return values;
		}
	}
	return [NSArray array];
}

+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key
{
    return [[PersonDetails realValuesFromPersonDetailsJSONDict:jsonDict forKey:key] 
            componentsJoinedByString:kPersonDetailsValueSeparatorToken];
}

@end
