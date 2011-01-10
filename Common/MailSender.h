//
//  MailSender.h
//  Harvard Mobile
//
//  Created by Jim Kang on 1/10/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MailSender : NSObject {
	
}

// Uses the MFMailComposer in a modal view to send the mail if it is available, 
// otherwise, has the system handle a mailto: url with subject and body.
+ (void)sendEmailWithSubject:(NSString *)emailSubject body:(NSString *)emailBody 
					delegate:(id<MFMailComposeViewControllerDelegate>)delegate;

@end
