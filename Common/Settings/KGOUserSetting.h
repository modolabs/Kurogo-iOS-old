#import <Foundation/Foundation.h>

@interface KGOUserSetting : NSObject {
    
    BOOL _unrestricted;
    NSString *_key;
    NSString *_title;
    NSArray *_options;
    id _defaultValue;
    
}

@property (nonatomic, readonly) BOOL unrestricted;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, retain) id selectedValue;   // must be plist compatible
@property (nonatomic, readonly) NSDictionary *defaultValue;
@property (nonatomic, readonly) NSArray *options; // may be nil if range is arbitrary

@end
