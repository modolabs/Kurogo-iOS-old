#import "Foundation+MITAdditions.h"

@implementation NSURL (MITAdditions)

+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path {
    return [NSURL internalURLWithModuleTag:tag path:path query:nil];
}

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
