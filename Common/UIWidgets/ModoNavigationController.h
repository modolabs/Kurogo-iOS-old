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
    NSArray *oldSubviews;
}

- (void)updateNavBar;
- (void)navigationBar:(ModoNavigationBar *)navigationBar willHideSubviews:(NSArray *)subviews;

@property (nonatomic, readonly) ModoNavigationBar *modoNavBar;

@end
