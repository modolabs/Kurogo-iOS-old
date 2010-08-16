#import "SchoolsModule.h"
#import "SchoolsViewController.h"

@implementation SchoolsModule

@synthesize schoolsVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = MobileWebTag;
        self.shortName = @"Schools";
        self.longName = @"Schools";
        self.iconName = @"full-website";
        self.canBecomeDefault = FALSE;
        
        self.schoolsVC = [[[SchoolsViewController alloc] init] autorelease];
        self.viewControllers = [NSArray arrayWithObject:self.schoolsVC];
    }
    return self;
}

@end
