/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "HarvardNavigationBar.h"

@interface HarvardNavigationController : UINavigationController {

    HarvardNavigationBar *_modoNavBar;
    NSArray *oldSubviews;
}

- (void)updateNavBar;
- (void)navigationBar:(HarvardNavigationBar *)navigationBar willHideSubviews:(NSArray *)subviews;

@property (nonatomic, readonly) HarvardNavigationBar *modoNavBar;

@end
