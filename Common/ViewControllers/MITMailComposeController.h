#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

// TODO: add protocol for classes to do things after the controller is dismissed

@interface UIViewController (MITMailComposeController)

- (void)presentMailControllerWithEmail:(NSString *)email
                               subject:(NSString *)subject
                                  body:(NSString *)body
                              delegate:(id<MFMailComposeViewControllerDelegate>)delegate;

- (void)presentMailControllerWithEmail:(NSString *)email
                               subject:(NSString *)subject
                                  body:(NSString *)body
                              delegate:(id<MFMailComposeViewControllerDelegate>)delegate
                                isHTML:(BOOL)isHTML;

@end

