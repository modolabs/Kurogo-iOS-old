#import <Foundation/Foundation.h>

@class TwitterViewController;

@protocol TwitterViewControllerDelegate <NSObject>

- (BOOL)controllerShouldContinueToMessageScreen:(TwitterViewController *)controller;

@optional

- (void)controllerDidLogin:(TwitterViewController *)controller;
- (void)controllerDidPostTweet:(TwitterViewController *)controller;
- (void)controllerFailedToTweet:(TwitterViewController *)controller;

@end
