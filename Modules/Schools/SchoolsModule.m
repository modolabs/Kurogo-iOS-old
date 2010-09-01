
/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "SchoolsModule.h"
#import "SchoolsViewController.h"

@implementation SchoolsModule

@synthesize schoolsVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = SchoolsTag;
        self.shortName = @"Schools";
        self.longName = @"Schools";
        self.iconName = @"schools";
        self.canBecomeDefault = FALSE;
        
        self.schoolsVC = [[[SchoolsViewController alloc] init] autorelease];
        self.viewControllers = [NSArray arrayWithObject:self.schoolsVC];
    }
    return self;
}

@end
