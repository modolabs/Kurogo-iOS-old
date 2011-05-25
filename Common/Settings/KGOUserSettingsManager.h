#import <Foundation/Foundation.h>

@class KGOUserSetting;

@interface KGOUserSettingsManager : NSObject {
    
    NSMutableDictionary *_settings;
    
}

+ (KGOUserSettingsManager *)sharedManager;

- (NSArray *)settingsKeys;
- (KGOUserSetting *)settingForKey:(NSString *)key;

- (id)selectedValueForSetting:(NSString *)key;
- (void)selectOption:(NSUInteger)option forSetting:(NSString *)key;
- (void)selectValue:(id)selectedValue forSetting:(NSString *)key;

- (void)saveSettings;
- (void)wipeSettings;

@end
