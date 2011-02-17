#import <UIKit/UIKit.h>

typedef enum {
    KGOLayoutGravityTopLeft,
    KGOLayoutGravityTopRight,
    //KGOLayoutGravityCenterLeft,
    //KGOLayoutGravityCenterRight,
    KGOLayoutGravityBottomLeft,
    KGOLayoutGravityBottomRight
} KGOLayoutGravity;

@interface KGOHomeScreenWidget : UIView {

}

@property (nonatomic) KGOLayoutGravity gravity;
@property (nonatomic) BOOL behavesAsIcon;
@property (nonatomic) BOOL overlaps;

- (void)tapped; // non-default home screen behavior, implement only if behavesAsIcon == NO

@end
