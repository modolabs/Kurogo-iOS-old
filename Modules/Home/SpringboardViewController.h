/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "IconGrid.h"
#import "KGOHomeScreenViewController.h"

@class KGOModule;
@class KGOSearchBar;

@interface SpringboardViewController : KGOHomeScreenViewController <IconGridDelegate> {

    UIScrollView *_scrollView;
    
    IconGrid *primaryGrid;
    IconGrid *secondGrid;
}

@end

