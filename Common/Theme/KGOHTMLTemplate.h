#import <UIKit/UIKit.h>

@interface KGOHTMLTemplate : NSObject {
    
}

@property(nonatomic, retain) NSURL *baseURL;
@property(nonatomic, retain) NSString *templateString;

+ (KGOHTMLTemplate *)templateWithPathName:(NSString *)pathName;

- (NSString *)stringWithReplacements:(NSDictionary *)replacementDict;
- (NSString *)stringWithMultiReplacements:(NSArray *)replacements;

@end