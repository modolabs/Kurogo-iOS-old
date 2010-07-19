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
        return [actualValue stringByReplacingOccurrencesOfString:@"$" withString:@"\n"];
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
	if (uid.length > 8) {
		uid = [uid substringToIndex:8];
	}
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uid = %@)", uid];
	NSArray *results = [CoreDataManager objectsForEntity:PersonDetailsEntityName matchingPredicate:pred];
    
	if ([results count] == 0)
		return [PeopleRecentsData createFromSearchResult:selectedResult];
	else 
		return [results objectAtIndex:0];
}

+ (NSArray *)realValuesFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key {
    NSArray *values = [[jsonDict objectForKey:key] objectForKey:@"Values"];
    if ([values isKindOfClass:[NSArray class]]) {
        return values;
    }
    else {
        return [NSArray array];
    }
}

+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key
{
    return [[PersonDetails realValuesFromPersonDetailsJSONDict:jsonDict forKey:key] 
            componentsJoinedByString:@","];
}

@end
