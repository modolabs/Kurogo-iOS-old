#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOUserSettingsManager.h"
#import "KGOUserSetting.h"
#import "Foundation+KGOAdditions.h"
#import "KGOModule.h"

// NSUserDefaults
NSString * const KGOUserSettingPreferenceKey = @"KGOSettings";

// these strings appear as keys in Settings.plist
NSString * const KGOUserSettingKeyFont = @"Font";
NSString * const KGOUserSettingKeyFontSize = @"FontSize";
NSString * const KGOUserSettingKeyPrimaryModules = @"PrimaryModules";
NSString * const KGOUserSettingKeySecondaryModules = @"SecondaryModules";
// this string is independent from Settings.plist
NSString * const KGOUserSettingKeyLogin = @"Login";

#ifdef DEBUG
NSString * const KGOUserSettingKeyServer = @"ServerSelection";
#endif

@interface KGOUserSetting (Setters)

- (void)_setKey:(NSString *)key;
- (void)_setTitle:(NSString *)title;
- (void)_setDefaultValue:(id)defaultValue;
- (void)_setOptions:(NSArray *)options;
- (void)_setUnrestricted:(BOOL)unrestricted;

@end


@implementation KGOUserSetting (Setters)

- (void)_setKey:(NSString *)key
{
    [_key release];
    _key = [key retain];
}

- (void)_setTitle:(NSString *)title
{
    [_title release];
    _title = [title retain];
}

- (void)_setDefaultValue:(id)defaultValue
{
    if (_defaultValue != defaultValue) {
        [_defaultValue release];
        _defaultValue = [defaultValue retain];
    }
}

- (void)_setOptions:(NSArray *)options
{
    if (_options != options) {
        [_options release];
        _options = [options retain];
    }
}

- (void)_setUnrestricted:(BOOL)unrestricted
{
    _unrestricted = unrestricted;
}

@end



@implementation KGOUserSettingsManager

@synthesize moduleSortOrder, settings = _settings;

+ (KGOUserSettingsManager *)sharedManager {
	static KGOUserSettingsManager *s_sharedManager = nil;
	if (s_sharedManager == nil) {
		s_sharedManager = [[KGOUserSettingsManager alloc] init];
	}
	return s_sharedManager;
}

- (NSArray *)settingsKeys
{
    // TODO: determine a way to sort
    return [_settings allKeys];
}

- (KGOUserSetting *)settingForKey:(NSString *)key
{
    return [_settings objectForKey:key];
}

- (NSUInteger)selectedOptionForKey:(NSString *)key
{
    KGOUserSetting *setting = [self settingForKey:key];
    return [setting.options indexOfObject:[self selectedValueDictForSetting:key]];
}

- (NSDictionary *)selectedValueDictForSetting:(NSString *)key
{
    KGOUserSetting *setting = [self settingForKey:key];
    if (setting.selectedValue) {
        return setting.selectedValue;
    } else {
        return setting.defaultValue;
    }
}

- (NSString *)selectedValueForSetting:(NSString *)key
{
    NSDictionary *dict = [self selectedValueDictForSetting:key];
    return [dict objectForKey:@"id"];
}

- (void)selectOption:(NSUInteger)option forSetting:(NSString *)key
{
    KGOUserSetting *setting = [self settingForKey:key];
    if (option < setting.options.count) {
        setting.selectedValue = [setting.options objectAtIndex:option];
    }
}

- (void)selectValue:(id)selectedValue forSetting:(NSString *)key
{
    // TODO: make sure all selectedValues are plist-compatible
    KGOUserSetting *setting = [self settingForKey:key];
    if (setting.unrestricted || [setting.options containsObject:selectedValue]) {
        setting.selectedValue = selectedValue;
    }
}

- (void)saveSettings
{
    NSMutableDictionary *plistSettings = [NSMutableDictionary dictionary];
    [_settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KGOUserSetting *userSetting = (KGOUserSetting *)obj;
        if (userSetting.selectedValue) {
            [plistSettings setObject:userSetting.selectedValue forKey:key];
        }
    }];

    [[NSUserDefaults standardUserDefaults] setObject:plistSettings forKey:KGOUserSettingPreferenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)wipeSettings
{
    [_settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(KGOUserSetting *)obj setSelectedValue:nil];
    }];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KGOUserSettingPreferenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setModuleOrder:(NSArray *)order primary:(BOOL)primary
{
    // remove all modules in incoming array and move to the end
    // since primary and secondary are processed separately
    NSMutableArray *oldOrder = [[self.moduleSortOrder mutableCopy] autorelease];
    for (NSDictionary *moduleData in order) {
        ModuleTag *moduleTag = [moduleData objectForKey:@"tag"];
        [oldOrder removeObject:moduleTag];
        [oldOrder addObject:moduleTag];
    }
    self.moduleSortOrder = oldOrder;
    DLog(@"%@", self.moduleSortOrder);
    
    KGOUserSetting *setting = nil;
    if (primary) {
        setting = [self settingForKey:KGOUserSettingKeyPrimaryModules];
    } else {
        setting = [self settingForKey:KGOUserSettingKeySecondaryModules];
    }
    [setting _setOptions:order];
}

- (BOOL)isModuleHidden:(ModuleTag *)tag primary:(BOOL)primary
{
    NSString *settingKey = primary ? KGOUserSettingKeyPrimaryModules : KGOUserSettingKeySecondaryModules;

    KGOUserSetting *setting = [self settingForKey:settingKey];
    for (NSDictionary *moduleDict in setting.options) {
        if ([tag isEqualToString:[moduleDict stringForKey:@"tag"]]) {
            return [moduleDict boolForKey:@"hidden"];
        }
    }
    return NO;
}

- (void)toggleModuleHidden:(ModuleTag *)tag primary:(BOOL)primary
{
    NSString *settingKey = primary ? KGOUserSettingKeyPrimaryModules : KGOUserSettingKeySecondaryModules;
    
    KGOUserSetting *setting = [self settingForKey:settingKey];
    NSInteger numOptions = setting.options.count;
    for (NSInteger i = 0; i < numOptions; i++) {
        NSDictionary *moduleDict = [setting.options dictionaryAtIndex:i];
        if ([tag isEqualToString:[moduleDict stringForKey:@"tag"]]) {
            BOOL hiddenNow = ![moduleDict boolForKey:@"hidden"];

            KGOModule *module = [KGO_SHARED_APP_DELEGATE() moduleForTag:tag];
            module.hidden = hiddenNow;
            
            NSMutableDictionary *mutableDict = [[moduleDict mutableCopy] autorelease];
            [mutableDict setObject:[NSNumber numberWithBool:hiddenNow] forKey:@"hidden"];
            NSMutableArray *mutableOptions = [[setting.options mutableCopy] autorelease];
            [mutableOptions removeObjectAtIndex:i];
            [mutableOptions insertObject:mutableDict atIndex:i];
            [setting _setOptions:mutableOptions];
            
            return;
        }
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        _settings = [[NSMutableDictionary alloc] init];
        NSString *filename = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        NSDictionary *availableSettings = [NSDictionary dictionaryWithContentsOfFile:filename];
        NSDictionary *savedSettings = [[NSUserDefaults standardUserDefaults] objectForKey:KGOUserSettingPreferenceKey];

        DLog(@"available settings %@", availableSettings);
        DLog(@"saved user settings %@", savedSettings);

        NSArray *stringSettings = [NSArray arrayWithObjects:KGOUserSettingKeyFont, KGOUserSettingKeyFontSize, nil];
        for (NSString *key in stringSettings) {
            NSDictionary *settingData = [availableSettings dictionaryForKey:key];
            if (settingData) {
                KGOUserSetting *aSetting = [[[KGOUserSetting alloc] init] autorelease];
                [aSetting _setKey:key];
                [aSetting _setTitle:[settingData objectForKey:@"title"]];
                [aSetting _setOptions:[settingData objectForKey:@"options"]];
                for (NSDictionary *optionData in aSetting.options) {
                    NSNumber *isDefault = [optionData objectForKey:@"default"];
                    if (isDefault && [isDefault boolValue]) {
                        [aSetting _setDefaultValue:optionData];
                        break;
                    }
                }
                
                id savedSetting = [savedSettings objectForKey:key];
                if (savedSetting) {
                    aSetting.selectedValue = savedSetting;
                } else {
                    aSetting.selectedValue = aSetting.defaultValue;
                }
                
                [_settings setObject:aSetting forKey:key];
            }
        }

        NSDictionary *primaryModuleData = [availableSettings dictionaryForKey:KGOUserSettingKeyPrimaryModules];
        NSDictionary *secondaryModuleData = [availableSettings dictionaryForKey:KGOUserSettingKeySecondaryModules];
        
        __block NSMutableArray *moduleOrder = [NSMutableArray array];
        __block NSArray *moduleConfig = [[KGO_SHARED_APP_DELEGATE() appConfig] arrayForKey:KGOAppConfigKeyModules];

        KGOUserSetting* (^prepareModules)(NSString *, NSDictionary *, BOOL) 
            = ^(NSString *settingKey, NSDictionary *defaultData, BOOL isSecondary)
        {
            KGOUserSetting *aSetting = [[[KGOUserSetting alloc] init] autorelease];
            if (defaultData) {
                [aSetting _setKey:settingKey];
                [aSetting _setTitle:[defaultData objectForKey:@"title"]];
                
                NSArray *moduleSettings = [savedSettings arrayForKey:settingKey];
                
                if (!moduleSettings) {
                    NSMutableArray *tempSettings = [NSMutableArray array];
                    
                    for (NSDictionary *moduleData in moduleConfig) {
                        ModuleTag *tag = [moduleData nonemptyStringForKey:@"tag"];
                        if ([tag isEqualToString:HomeTag]) {
                            continue;
                        }
                        
                        NSString *moduleId = [moduleData nonemptyStringForKey:@"id"];
                        if (moduleId && tag) {
                            if (isSecondary == [moduleData boolForKey:@"secondary"]) {
                                [tempSettings addObject:moduleData];
                                [moduleOrder addObject:tag];
                            }
                        }
                    }
                    
                    moduleSettings = tempSettings;
                    
                } else {
                    for (NSDictionary *moduleData in moduleSettings) {
                        ModuleTag *tag = [moduleData nonemptyStringForKey:@"tag"];
                        [moduleOrder addObject:tag];
                    }
                }

                [aSetting _setOptions:moduleSettings];
            }
            return aSetting;
        };
        
        [self.settings setObject:prepareModules(KGOUserSettingKeyPrimaryModules, primaryModuleData, NO)
                          forKey:KGOUserSettingKeyPrimaryModules];

        [self.settings setObject:prepareModules(KGOUserSettingKeySecondaryModules, secondaryModuleData, YES)
                          forKey:KGOUserSettingKeySecondaryModules];
        
        self.moduleSortOrder = [NSArray arrayWithArray:moduleOrder];

#ifdef DEBUG
        KGOUserSetting *serverSetting = [[[KGOUserSetting alloc] init] autorelease];
        [serverSetting _setKey:KGOUserSettingKeyServer];
        [serverSetting _setTitle:NSLocalizedString(@"Server", @"heading for server selection in settings")];
        [serverSetting _setUnrestricted:NO];
        
        NSArray *configTitles = [NSArray arrayWithObjects:
                                 @"Development", @"Testing", @"Staging", @"Production", nil];
        NSDictionary *configDict = [KGO_SHARED_APP_DELEGATE() appConfig];
        NSDictionary *servers = [configDict dictionaryForKey:KGOAppConfigKeyServers];
        
        NSMutableArray *options = [NSMutableArray array];
        
        for (NSString *configTitle in configTitles) {
            NSString *host = [[servers dictionaryForKey:configTitle] nonemptyStringForKey:@"Host"];
            if (host) {
                [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    configTitle, @"id",
                                    configTitle, @"title",
                                    host, @"subtitle", nil]];
            }
        }

        [serverSetting _setOptions:options];

        // default to prod server (most likely to be up on first build?)
        [serverSetting _setDefaultValue:[options objectAtIndex:0]];
        
        id savedSetting = [savedSettings objectForKey:KGOUserSettingKeyServer];
        if (savedSetting) {
            serverSetting.selectedValue = savedSetting;
        }
        
        [_settings setObject:serverSetting forKey:KGOUserSettingKeyServer];
#endif
    }
    return self;
}

- (void)dealloc
{
    [_settings release];
    [super dealloc];
}

@end
