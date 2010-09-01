/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "ModoNavigationBar.h"

@interface ModoNavigationController : UINavigationController {

    ModoNavigationBar *_modoNavBar;
}

- (void)updateNavBar;

@property (nonatomic, readonly) ModoNavigationBar *modoNavBar;

@end
