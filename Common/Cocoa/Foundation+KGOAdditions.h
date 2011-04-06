#import <Foundation/Foundation.h>

@interface NSURL (MITAdditions)

//+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path;
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query;

@end


@interface NSURL (KGOAdditions)

+ (NSString *)queryStringWithParameters:(NSDictionary *)parameters;
+ (NSURL *)URLWithQueryParameters:(NSDictionary *)parameters baseURL:(NSURL *)baseURL;
+ (NSDictionary *)parametersFromQueryString:(NSString *)queryString;
- (NSDictionary *)queryParameters;

@end



@interface NSDate (KGOAdditions)

- (NSString *)agoString;

@end


@interface NSArray (JSONParser)

// returns nil on failure
- (NSString *)stringAtIndex:(NSInteger)index;
- (NSNumber *)numberAtIndex:(NSInteger)index;
- (NSArray *)arrayAtIndex:(NSInteger)index;
- (NSDate *)dateAtIndex:(NSInteger)index;
- (NSDate *)dateAtIndex:(NSInteger)index format:(NSString *)format;
- (NSDictionary *)dictionaryAtIndex:(NSInteger)index;

// returns false on failure
- (BOOL)boolAtIndex:(NSInteger)index;

// returns NSNotFound on failure
- (NSInteger)integerAtIndex:(NSInteger)index;

// returns 0.0 on failure
- (CGFloat)floatAtIndex:(NSInteger)index;

// returns defaultValue on failure
- (CGFloat)floatAtIndex:(NSInteger)index defaultValue:(CGFloat)defaultValue;

@end


@interface NSDictionary (JSONParser)

// returns nil on type failure
- (NSString *)stringForKey:(NSString *)key nilIfEmpty:(BOOL)nilIfEmpty;
- (NSNumber *)numberForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSDate *)dateForKey:(NSString *)key;
- (NSDate *)dateForKey:(NSString *)key format:(NSString *)format;
- (NSDictionary *)dictionaryForKey:(NSString *)key;

// returns false on failure
- (BOOL)boolForKey:(NSString *)key;

// returns NSNotFound on failure
- (NSInteger)integerForKey:(NSString *)key;

// returns 0.0 on failure
- (CGFloat)floatForKey:(NSString *)key;

// returns defaultValue on failure
- (CGFloat)floatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue;


@end

