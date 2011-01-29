/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>
#import "MITModule.h"

@class SchoolsViewController;

@interface SchoolsModule : MITModule {
    
    SchoolsViewController *schoolsVC;
}

@property (nonatomic, retain) SchoolsViewController *schoolsVC;

@end
