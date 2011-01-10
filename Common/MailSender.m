//
//  MailSender.m
//  Harvard Mobile
//
//  Created by Jim Kang on 1/10/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "MailSender.h"
#import "MIT_MobileAppDelegate.h"

@implementation MailSender

+ (void)sendEmailWithSubject:(NSString *)emailSubject body:(NSString *)emailBody 
					delegate:(id<MFMailComposeViewControllerDelegate>)delegate
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = 
		[[MFMailComposeViewController alloc] init];
		
		aController.mailComposeDelegate = delegate;    
		[aController setSubject:emailSubject];    
		[aController setMessageBody:emailBody isHTML:NO];
		
		MIT_MobileAppDelegate *appDelegate = 
		(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:aController animated:YES];
		[aController release];
		
	} else {
		NSString *mailtoString = 
		[NSString stringWithFormat:@"mailto://?subject=%@&body=%@", 
		 [emailSubject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
		 [emailBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
		NSURL *externURL = [NSURL URLWithString:mailtoString];
		if ([[UIApplication sharedApplication] canOpenURL:externURL]) {      
			[[UIApplication sharedApplication] openURL:externURL];
		}
	}
}

@end
