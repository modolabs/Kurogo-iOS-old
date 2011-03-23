#import <UIKit/UIKit.h>

@interface KGOHTMLTemplate : NSObject {

    NSString *template;
    NSURL *baseURL;
}

+ (KGOHTMLTemplate *)templateWithPathName:(NSString *)pathName;

- (id)initWithString:(NSString *)template baseURL:(NSURL *)baseURL;

- (NSString *)fillOutWithDictionary:(NSDictionary *)dict;

- (NSURL *)baseURL;
@end