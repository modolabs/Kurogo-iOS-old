#import <Foundation/Foundation.h>

@class TwitterViewController;

@protocol TwitterViewControllerDelegate <NSObject>

- (BOOL)controllerShouldContineToMessageScreen:(TwitterViewController *)controller;
- (void)controllerDidLogin:(TwitterViewController *)controller;

@end
