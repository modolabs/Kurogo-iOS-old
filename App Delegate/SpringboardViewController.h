#import <UIKit/UIKit.h>
#import "MITModule.h"
#import "ModoNavigationController.h"
#import "ModoNavigationBar.h"

@interface SpringboardViewController : UIViewController {

    UIView *containingView;
    MITModule *activeModule;
    ModoNavigationController *navigationController;
    ModoNavigationBar *navigationBar;

    NSMutableArray *_icons;
    NSMutableArray *editedIcons;
    NSMutableArray *tempIcons;
    UIButton *selectedIcon;
    UIButton *dummyIcon;
    NSInteger dummyIconIndex;
    UIView *transparentOverlay;
    
    CGPoint topLeft;
    CGPoint bottomRight;
    CGPoint startingPoint;
    
    BOOL editing;
}

- (void)layoutIcons:(NSArray *)icons;

@end



@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
}

@property (nonatomic, retain) NSString *moduleTag;

@end
