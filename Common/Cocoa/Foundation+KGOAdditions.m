#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

KGOSign KGOGetIntegerSign(NSInteger x) {
    if (x > 0)
        return KGOSignPositive;
    return (x == 0) ? KGOSignZero : KGOSignNegative;
}


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
    
    NSString *defaultScheme = [KGO_SHARED_APP_DELEGATE() defaultURLScheme];
	if (defaultScheme) {
		url = [[[NSURL alloc] initWithScheme:defaultScheme host:tag path:path] autorelease];
	}
	
    return url;
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
        NSString *encodedKey = [[key stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        if ([value isKindOfClass:[NSString class]]) {        
            NSString *encodedValue = [[value stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [components addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];

        } else if ([value isKindOfClass:[NSDictionary class]]) {
            for (NSString *singleKey in [value allKeys]) {
                NSString *singleValue = [value stringForKey:singleKey nilIfEmpty:YES];
                if (singleValue) {
                    [components addObject:[NSString stringWithFormat:@"%@[%@]=%@", encodedKey, singleKey, singleValue]];
                }
            }
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            for (NSInteger i = 0; i < [value count]; i++) {
                NSString *singleValue = [value stringAtIndex:i];
                if (singleValue) {
                    [components addObject:[NSString stringWithFormat:@"%@[%d]=%@", encodedKey, i, singleValue]];
                }
            }
        }
        
    }];

	return [components componentsJoinedByString:@"&"];
}

+ (NSURL *)URLWithQueryParameters:(NSDictionary *)parameters baseURL:(NSURL *)baseURL {
    NSString *queryString = [NSString stringWithFormat:@"?%@", [NSURL queryStringWithParameters:parameters]];
    return [NSURL URLWithString:queryString relativeToURL:baseURL];
}

// TODO: create backwards equivalent of +queryStringWithParameters:
// so we can parse queries like ?blah[a]=2&blah[b]=3
+ (NSDictionary *)parametersFromQueryString:(NSString *)queryString {
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *aComponent in components) {
        NSArray *parts = [aComponent componentsSeparatedByString:@"="];
        [dictionary setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSDictionary *)queryParameters {
    return [NSURL parametersFromQueryString:[self query]];
}

@end


@implementation NSDate (KGOAdditions)

- (NSString *)agoString {
    NSString *result = nil;
    int seconds = -(int)[self timeIntervalSinceNow];
    int minutes = seconds / 60;
    if (minutes < 60) {
        if (minutes == 1) {
            result = [NSString stringWithFormat:@"%d %@", minutes, NSLocalizedString(@"minute ago", nil)];
        } else {
            result = [NSString stringWithFormat:@"%d %@", minutes, NSLocalizedString(@"minutes ago", nil)];
        }
    } else {
        int hours = minutes / 60;
        if (hours < 24) {
            if (hours == 1) {
                result = [NSString stringWithFormat:@"%d %@", hours, NSLocalizedString(@"hour ago", nil)];
            } else {
                result = [NSString stringWithFormat:@"%d %@", hours, NSLocalizedString(@"hours ago", nil)];
            }
        } else {
            int days = hours / 24;
            if (days < 7) {
                if (days == 1) {
                    result = [NSString stringWithFormat:@"%d %@", days, NSLocalizedString(@"day ago", nil)];
                } else {
                    result = [NSString stringWithFormat:@"%d %@", days, NSLocalizedString(@"days ago", nil)];
                }
            } else {
                static NSDateFormatter *shortFormatter = nil;
                if (shortFormatter == nil) {
                    shortFormatter = [[NSDateFormatter alloc] init];
                    [shortFormatter setDateStyle:NSDateFormatterShortStyle];
                }
                result = [shortFormatter stringFromDate:self];
            }
        }
    }
    return result;
}

@end



@implementation NSArray (KGOAdditions)

- (NSArray *)mappedArrayUsingBlock:(id (^)(id element))block
{
    NSMutableArray *queue = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [queue addObject:block(obj)];
    }];
    return [[queue copy] autorelease];
}

@end


@implementation NSArray (JSONParser)

- (NSString *)stringAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    if ([object isKindOfClass:[NSString class]])
        return (NSString *)object;
    
    return nil;
}

- (NSNumber *)numberAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    if ([object isKindOfClass:[NSNumber class]])
        return (NSNumber *)object;
    
    return nil;
}

- (NSArray *)arrayAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    if ([object isKindOfClass:[NSArray class]])
        return (NSArray *)object;

    return nil;
}

- (NSDate *)dateAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    if ([object isKindOfClass:[NSDate class]])
        return (NSDate *)object;

    return nil;
}

- (NSDate *)dateAtIndex:(NSInteger)index format:(NSString *)format {
    NSString *string = [self stringAtIndex:index];
    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
    [df setDateFormat:format];
    return [df dateFromString:string];
}

- (NSDictionary *)dictionaryAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    if ([object isKindOfClass:[NSDictionary class]])
        return (NSDictionary *)object;
    
    return nil;
}

- (BOOL)boolAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object boolValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object boolValue];
    
    return NO;
}

- (NSInteger)integerAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object integerValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object integerValue];
    
    return NSNotFound;
}

- (CGFloat)floatAtIndex:(NSInteger)index {
    id object = [self objectAtIndex:index];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object floatValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object floatValue];
    
    return NO;
}

- (CGFloat)floatAtIndex:(NSInteger)index defaultValue:(CGFloat)defaultValue {
    id object = [self objectAtIndex:index];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object floatValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object floatValue];
    
    return defaultValue;
}

@end


@implementation NSDictionary (JSONParser)

- (NSString *)stringForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    }
    return nil;
}

- (NSString *)nonemptyStringForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]] && [(NSString *)object length]) {
        return (NSString *)object;
    }
    return nil;
}

- (NSString *)forcedStringForKey:(NSString *)key {
    NSString *string = [self stringForKey:key];
    if (!string) {
        NSNumber *number = [self numberForKey:key];
        if (number) {
            string = [number description];
        }
    }
    return string;
}

- (NSString *)nonemptyForcedStringForKey:(NSString *)key {
    NSString *string = [self nonemptyStringForKey:key];
    if (!string) {
        NSNumber *number = [self numberForKey:key];
        if (number) {
            string = [number description];
        }
    }
    return string;
}

- (NSString *)stringForKey:(NSString *)key nilIfEmpty:(BOOL)nilIfEmpty {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        if (string.length || !nilIfEmpty)
            return string;
    }
    return nil;
}

- (NSNumber *)numberForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return (NSNumber *)object;
    
    return nil;
}

- (NSArray *)arrayForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSArray class]])
        return (NSArray *)object;
    
    return nil;
}

- (NSDate *)dateForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSDate class]])
        return (NSDate *)object;
    
    return nil;
}

- (NSDate *)dateForKey:(NSString *)key format:(NSString *)format {
    NSString *string = [self nonemptyStringForKey:key];
    if (string) {
        NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
        [df setDateFormat:format];
        return [df dateFromString:string];
    }
    return nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSDictionary class]])
        return (NSDictionary *)object;
    
    return nil;
}

- (BOOL)boolForKey:(NSString *)key {
    id object = [self objectForKey:key];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object boolValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object boolValue];
    
    return NO;
}

- (NSInteger)integerForKey:(NSString *)key {
    id object = [self objectForKey:key];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object integerValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object integerValue];
    
    return NSNotFound;
}

- (CGFloat)floatForKey:(NSString *)key {
    id object = [self objectForKey:key];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object floatValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object floatValue];
    
    return NO;
}

- (CGFloat)floatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue {
    id object = [self objectForKey:key];
    
    if ([object isKindOfClass:[NSNumber class]])
        return [(NSNumber *)object floatValue];
    
    if ([object isKindOfClass:[NSString class]])
        return [(NSString *)object floatValue];
    
    return defaultValue;
}

@end
