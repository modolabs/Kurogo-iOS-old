#import <UIKit/UIKit.h>

@class SpringboardViewController;
@class KGOModule;

@interface SpringboardIcon : UIButton {
    
    KGOModule *_module;

}

- (NSString *)moduleTag;

@property (nonatomic, retain) KGOModule *module;
@property (nonatomic, assign) SpringboardViewController *springboard;

@end
