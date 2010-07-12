#import <UIKit/UIKit.h>
#import "ModoNavigationBar.h"

@interface ModoNavigationController : UINavigationController {

    ModoNavigationBar *_modoNavBar;
}

@property (nonatomic, readonly) ModoNavigationBar *modoNavBar;

@end
