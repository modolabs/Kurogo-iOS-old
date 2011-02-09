#import <Foundation/Foundation.h>

@interface NSURL (MITAdditions)

//+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path;
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query;

@end


@interface NSMutableString (MITAdditions)

- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)options;

@end



@interface NSURL (KGOAdditions)

+ (NSString *)queryStringWithParameters:(NSDictionary *)parameters;
+ (NSURL *)URLWithQueryParameters:(NSDictionary *)parameters baseURL:(NSURL *)baseURL;
- (NSDictionary *)queryParameters;

@end



@interface NSMutableString (KGOAdditions)

+ (NSMutableString *)stringWithContentsOfTemplate:(NSString *)fileName searchStrings:(NSArray *)searchStrings replacements:(NSArray *)replacements;

@end



typedef NSComparisonResult (^ComparatorBlock)(id, id, void *);

@interface NSMutableArray (KGOAdditions)

- (void)sortUsingBlock:(ComparatorBlock)comparator context:(void *)context ;

@end


@interface NSArray (KGOAdditions)

- (NSArray *)sortedArrayUsingBlock:(ComparatorBlock)comparator context:(void *)context ;

@end