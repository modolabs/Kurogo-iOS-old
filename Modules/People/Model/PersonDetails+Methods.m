#import "PersonDetails+Methods.h"
#import "CoreDataManager.h"
#import "PeopleRecentsData.h"

@implementation PersonDetails (Methods)

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

+ (id)realValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key
{
    return [[jsonDict objectForKey:key] objectForKey:@"value"];
}

+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key
{
    return [[PersonDetails realValueFromPersonDetailsJSONDict:jsonDict forKey:key] 
            componentsJoinedByString:@","];
}
@end
