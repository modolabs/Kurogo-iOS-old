#import <Foundation/Foundation.h>

// these strings appear as keys in Settings.plist
extern NSString * const KGOUserSettingKeyFont;
extern NSString * const KGOUserSettingKeyFontSize;
extern NSString * const KGOUserSettingKeyPrimaryModules;
extern NSString * const KGOUserSettingKeySecondaryModules;
extern NSString * const KGOUserSettingKeyModuleOrder;
// this string is independent from Settings.plist
extern NSString * const KGOUserSettingKeyLogin;

#ifdef DEBUG
extern NSString * const KGOUserSettingKeyServer;
#endif

@class KGOUserSetting;

@interface KGOUserSettingsManager : NSObject {
    
    NSMutableDictionary *_settings;
    NSDictionary *_primaryModuleData;
    NSDictionary *_secondaryModuleData;
}

+ (KGOUserSettingsManager *)sharedManager;

- (void)setModuleOrder:(NSArray *)order primary:(BOOL)primary;
- (BOOL)isModuleHidden:(ModuleTag *)tag primary:(BOOL)primary;
- (void)toggleModuleHidden:(ModuleTag *)tag primary:(BOOL)primary;
- (void)updateModuleSettingsFromConfig:(NSArray *)moduleConfig;

@property(nonatomic, retain) NSArray *moduleSortOrder;
@property(nonatomic, readonly) NSMutableDictionary *settings;

- (NSArray *)settingsKeys;
- (KGOUserSetting *)settingForKey:(NSString *)key;

- (NSDictionary *)selectedValueDictForSetting:(NSString *)key;
- (id)selectedValueForSetting:(NSString *)key;
- (void)selectOption:(NSUInteger)option forSetting:(NSString *)key;
- (void)selectValue:(id)selectedValue forSetting:(NSString *)key;

- (void)saveSettings;
- (void)wipeSettings;

@end
