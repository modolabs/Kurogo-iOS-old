#import "KGOHTMLTemplate.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOHTMLTemplate 

@synthesize templateString, baseURL;

+ (KGOHTMLTemplate *)templateWithPathName:(NSString *)pathName {
    
    KGOHTMLTemplate *aTemplate = [[[KGOHTMLTemplate alloc] init] autorelease];

    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSURL *fileURL;
    NSError *error = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        aTemplate.baseURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/ipad", resourcePath] isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:aTemplate.baseURL];
        aTemplate.templateString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    if (!aTemplate.templateString) { 
        aTemplate.baseURL = [NSURL fileURLWithPath:resourcePath isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:aTemplate.baseURL];
        aTemplate.templateString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    if (!aTemplate.templateString) {
        aTemplate.baseURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/kurogo", resourcePath] isDirectory:YES];
        fileURL = [NSURL URLWithString:pathName relativeToURL:aTemplate.baseURL];
        aTemplate.templateString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }

    NSAssert(aTemplate.templateString != nil, @"could not find template for path name %@", pathName);
    return aTemplate;
}

- (void)dealloc {
    self.templateString = nil;
    self.baseURL = nil;
    [super dealloc];
}

- (NSString *)stringWithReplacements:(NSDictionary *)replacementDict
{
    NSMutableString *output = [NSMutableString stringWithString:self.templateString];
    [replacementDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *keyPattern = [NSString stringWithFormat:@"__%@__", key];
        [output replaceOccurrencesOfString:keyPattern withString:obj options:NSLiteralSearch range:NSMakeRange(0, output.length)];
    }];
    return output;
}

- (NSString *)stringWithMultiReplacements:(NSArray *)replacements
{
    NSMutableString *output = [NSMutableString string];
    
    [replacements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSString *string = [self stringWithReplacements:obj];
            if (string) {
                [output appendString:string];
            }
        }
    }];
    
    return output;
}

@end