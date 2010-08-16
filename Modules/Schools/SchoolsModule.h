#import <Foundation/Foundation.h>
#import "MITModule.h"

@class SchoolsViewController;

@interface SchoolsModule : MITModule {
    
    SchoolsViewController *schoolsVC;
}

@property (nonatomic, retain) SchoolsViewController *schoolsVC;

@end
