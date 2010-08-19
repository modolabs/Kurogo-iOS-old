#import <CoreData/CoreData.h>

extern NSString * const kPersonDetailsValueSeparatorToken;

@interface PersonDetails :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSString * cn;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * facsimiletelephonenumber;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * telephonenumber;
@property (nonatomic, retain) NSString * sn;
@property (nonatomic, retain) NSString * postaladdress;
@property (nonatomic, retain) NSString * ou;
@property (nonatomic, retain) NSString * givenname;

// "Actual" value as in not a PersonDetail object, but rather the value it contains if in fact
// a PersonDetail object is stored with the given key.
- (NSString *)formattedValueForKey:(NSString *)key;
- (NSString *)displayNameForKey:(NSString *)key;
+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult;
+ (NSString *)trimUID:(NSString *)theUID;
+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key;

@end



