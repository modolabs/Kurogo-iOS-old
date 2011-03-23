#import <UIKit/UIKit.h>

typedef enum {
    KGOLayoutGravityTopLeft,
    KGOLayoutGravityTopRight,
    //KGOLayoutGravityCenterLeft,
    //KGOLayoutGravityCenterRight,
    KGOLayoutGravityBottomLeft,
    KGOLayoutGravityBottomRight
} KGOLayoutGravity;

@class KGOModule;

@interface KGOHomeScreenWidget : UIControl {
    
    BOOL _behavesAsIcon;

}

@property (nonatomic) KGOLayoutGravity gravity;
@property (nonatomic) BOOL behavesAsIcon;
@property (nonatomic) BOOL overlaps;
@property (nonatomic, assign) KGOModule *module;

- (void)customTapAction:(KGOHomeScreenWidget *)sender; // non-default home screen behavior, called only if behavesAsIcon == NO

@end
