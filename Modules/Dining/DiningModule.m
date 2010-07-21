#import "DiningModule.h"
#import "DiningFirstViewController.h"
#import "HoursTableViewController.h"

@implementation DiningModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = DiningTag;
        self.shortName = @"Dining";
        self.longName = @"Harvard Dining";
        self.iconName = @"dining";
        self.isMovableTab = FALSE;
        
        DiningFirstViewController *aboutVC = [[[DiningFirstViewController alloc] init] autorelease];
        aboutVC.title = self.longName;

        self.viewControllers = [NSArray arrayWithObject:aboutVC];
		
    }
    return self;
}

@end