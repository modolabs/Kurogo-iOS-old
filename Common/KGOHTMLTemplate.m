#import "KGOHTMLTemplate.h"
#import "Foundation+KGOAdditions.h"
@implementation KGOHTMLTemplate 

+ (KGOHTMLTemplate *)templateWithPathName:(NSString *)pathName {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSURL *baseURL;
    [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSString *template = nil;
    NSURL *fileURL;
    NSError *error = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        baseURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/ipad", resourcePath] isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:baseURL];
        template = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    if (!template) { 
        baseURL = [NSURL fileURLWithPath:resourcePath isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:baseURL];
        template = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    if (!template) {
        baseURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/kurogo", resourcePath] isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:baseURL];
        template = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    NSAssert((template != nil), ([NSString stringWithFormat:@"failed to find template for %@", pathName]));
    return [[[KGOHTMLTemplate alloc] initWithString:template baseURL:baseURL] autorelease];
}

- (id)initWithString:(NSString *)aTemplate baseURL:(NSURL *)aBaseURL {
    if ((self = [super init])) {
        template = [aTemplate retain];
        baseURL = [aBaseURL retain];
    }
    return self;
}

- (void)dealloc {
    [template release];
    [baseURL release];
    [super dealloc];
}

- (NSString *)fillOutWithDictionary:(NSDictionary *)dict {
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:[dict count]];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:[dict count]];
    
    for (NSString *key in [dict keyEnumerator]) {
        [keys addObject:[NSString stringWithFormat:@"__%@__", key]];
        [values addObject:[dict objectForKey:key]];
    }
    
    NSMutableString *output = [NSMutableString stringWithString:template];
    [output replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    return output;
}

- (NSURL *)baseURL {
    return baseURL;
}
@end