#import "Foundation+KGOAdditions.h"

@implementation NSURL (MITAdditions)
/*
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path {
    return [NSURL internalURLWithModuleTag:tag path:path query:nil];
}
*/
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query {
	NSURL *url = nil;
	
    if ([path rangeOfString:@"/"].location != 0) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    if ([query length] > 0) {
        path = [path stringByAppendingFormat:@"?%@", query];
    }
	
	NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
	if ([urlTypes count]) {
		NSArray *urlSchemes = [[urlTypes objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"];
		NSString *defaultScheme = [urlSchemes objectAtIndex:0];
		url = [[[NSURL alloc] initWithScheme:defaultScheme host:tag path:path] autorelease];
	}
	
    return url;
}

@end


@implementation NSMutableString (MITAdditions)

- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)options {
    assert([targets count] == [replacements count]);
    NSInteger i = 0;
    for (NSString *target in targets) {
        [self replaceOccurrencesOfString:target withString:[replacements objectAtIndex:i] options:options range:NSMakeRange(0, [self length])];
        i++;
    }
}

@end



@implementation NSURL (KGOAdditions)


// modified version of internal URL building method from MIT.
// an internal url with query params would be built as:
// NSURL *url = [NSURL URLWithQueryParameters:queryParameters baseURL:[NSURL internalURLWithModuleTag:moduleTag path:nil]];
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path {
	NSURL *url = nil;
	
	NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
	if ([urlTypes count]) {
		NSArray *urlSchemes = [[urlTypes objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"];
		NSString *defaultScheme = [urlSchemes objectAtIndex:0];
        
        if (defaultScheme) {
            if ([path rangeOfString:@"/"].location != 0) {
                path = [NSString stringWithFormat:@"/%@", path];
            }
            url = [[[NSURL alloc] initWithScheme:defaultScheme host:tag path:path] autorelease];
        }
	}
	
    return url;
}

// http://www.faqs.org/rfcs/rfc1738.html
+ (NSString *)queryStringWithParameters:(NSDictionary *)parameters {
	NSMutableArray *components = [NSMutableArray arrayWithCapacity:[parameters count]];

    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *encodedKey = [[key stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = [[value stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        encodedKey = [encodedKey stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        encodedValue = [encodedValue stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }];

	return [components componentsJoinedByString:@"&"];
}

+ (NSURL *)URLWithQueryParameters:(NSDictionary *)parameters baseURL:(NSURL *)baseURL {
    NSString *queryString = [NSString stringWithFormat:@"?%@", [NSURL queryStringWithParameters:parameters]];
    return [NSURL URLWithString:queryString relativeToURL:baseURL];
}

- (NSDictionary *)queryParameters {
    NSArray *components = [[self query] componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *aComponent in components) {
        NSArray *parts = [aComponent componentsSeparatedByString:@"="];
        [dictionary setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end


@implementation NSMutableString (KGOAdditions)

+ (NSMutableString *)stringWithContentsOfTemplate:(NSString *)fileName searchStrings:(NSArray *)searchStrings replacements:(NSArray *)replacements {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:fileName relativeToURL:baseURL];
	NSError *error = nil;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		DLog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}
	[target replaceOccurrencesOfStrings:searchStrings 
							withStrings:replacements
								options:NSLiteralSearch];
	return target;
}

@end



typedef struct {
    ComparatorBlock comparator;
    void *userData;
} ComparatorInfo;

static NSComparisonResult sortWithBlock(id a, id b, void *context) {
    ComparatorInfo *info = (ComparatorInfo *)context;
    ComparatorBlock comparator = info->comparator;
    void *userData = info->userData;
    return comparator(a, b, userData);
}


@implementation NSMutableArray (KGOAdditions)

- (void)sortUsingBlock:(ComparatorBlock)comparator context:(void *)context {
    ComparatorInfo info;
    info.comparator = comparator;
    info.userData = context;
    [self sortUsingFunction:sortWithBlock context:&info];
}

@end


@implementation NSArray (KGOAdditions)

- (NSArray *)sortedArrayUsingBlock:(ComparatorBlock)comparator context:(void *)context {
    ComparatorInfo info;
    info.comparator = comparator;
    info.userData = context;
    return [self sortedArrayUsingFunction:sortWithBlock context:&info];
}

@end
