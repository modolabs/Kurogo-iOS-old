#import <UIKit/UIKit.h>

@class KGOHomeScreenViewController;
@class KGOModule;

@interface SpringboardIcon : UIButton {
    
    KGOModule *_module;

}

- (ModuleTag *)moduleTag;

@property (nonatomic, retain) KGOModule *module;
@property (nonatomic, assign) KGOHomeScreenViewController *springboard;
@property (nonatomic) BOOL compact; // true if labels show up below the image

@end
