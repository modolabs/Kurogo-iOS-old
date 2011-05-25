#import "KGOUserSetting.h"

@implementation KGOUserSetting

@synthesize key = _key, title = _title, selectedValue, defaultValue = _defaultValue, options = _options, unrestricted = _unrestricted;

- (void)dealloc
{
    [_key release];
    [_title release];
    [_options release];
    [_defaultValue release];
    [selectedValue release];
    
    [super dealloc];
}

@end
