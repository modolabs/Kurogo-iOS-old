/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

// UINavigationBar wrapper class.

#import <UIKit/UIKit.h>


@interface ModoNavigationBar : UINavigationBar /*<UINavigationBarDelegate>*/ {
    
    UINavigationBar *_navigationBar;

}

- (id)initWithNavigationBar:(UINavigationBar *)navigationBar;
- (void)update;

@property (nonatomic, retain) UINavigationBar *navigationBar;

@end
