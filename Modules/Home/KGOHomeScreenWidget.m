#import "KGOHomeScreenWidget.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"

@implementation KGOHomeScreenWidget

@synthesize gravity, overlaps, module;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.behavesAsIcon = YES;
        self.overlaps = NO;
    }
    return self;
}

- (BOOL)behavesAsIcon {
    return _behavesAsIcon;
}

- (void)setBehavesAsIcon:(BOOL)behavesAsIcon {
    if (_behavesAsIcon != behavesAsIcon) {
        _behavesAsIcon = behavesAsIcon;
        if (_behavesAsIcon) {
            [self removeTarget:self action:@selector(customTapAction:) forControlEvents:UIControlEventTouchUpInside];
            [self addTarget:self action:@selector(defaultTapAction:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self removeTarget:self action:@selector(defaultTapAction:) forControlEvents:UIControlEventTouchUpInside];
            [self addTarget:self action:@selector(customTapAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)customTapAction:(KGOHomeScreenWidget *)sender {
    ;
}

- (void)defaultTapAction:(KGOHomeScreenWidget *)sender {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameHome
                                                                forModuleTag:self.module.tag
                                                                      params:nil];
}
             
- (void)dealloc {
    [super dealloc];
}


@end
