#import <UIKit/UIKit.h>
#import "ModoNavigationBar.h"

@interface ModoNavigationController : UINavigationController {

    ModoNavigationBar *_modoNavBar;
}

- (void)updateNavBar;

@property (nonatomic, readonly) ModoNavigationBar *modoNavBar;

@end
