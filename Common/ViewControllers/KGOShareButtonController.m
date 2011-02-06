#import "KGOShareButtonController.h"
#import "MIT_MobileAppDelegate.h"
#import "TwitterViewController.h"
#import "JSONAPIRequest.h"
#import "MITMailComposeController.h"

@implementation KGOShareButtonController

@synthesize /*facebook,*/ delegate = _delegate;

- (id)initWithDelegate:(id<KGOShareButtonDelegate>)delegate {
	if (self = [super init]) {
		_delegate = delegate;
	}
	return self;
}

#pragma mark Action Sheet

// subclasses should make sure actionSheetTitle is set up before this gets called
// or call [super share:sender] at the end of this
// TODO: conditionally show facebook and twitter
- (void)shareInView:(UIView *)view {
    UIActionSheet *shareSheet = nil;
    
    shareSheet = [[UIActionSheet alloc] initWithTitle:[self.delegate actionSheetTitle]
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                               destructiveButtonTitle:nil
                                    otherButtonTitles:@"Email", @"Facebook", @"Twitter", nil];
	
	if ([[KGOSocialMediaController sharedController] supportsEmailSharing]) {
		[shareSheet addButtonWithTitle:KGOSocialMediaTypeEmail];
	}
	if ([[KGOSocialMediaController sharedController] supportsFacebookSharing]) {
		[shareSheet addButtonWithTitle:KGOSocialMediaTypeFacebook];
	}
	if ([[KGOSocialMediaController sharedController] supportsTwitterSharing]) {
		[shareSheet addButtonWithTitle:KGOSocialMediaTypeTwitter];
	}
    
	[shareSheet showInView:view];
    [shareSheet release];
}

// TODO: use button titles instead of button indexes
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:KGOSocialMediaTypeEmail]) {
        [MITMailComposeController presentMailControllerWithEmail:nil subject:[self.delegate emailSubject] body:[self.delegate emailBody]];

	} else if ([buttonTitle isEqualToString:KGOSocialMediaTypeFacebook]) {
		[[KGOSocialMediaController sharedController] loginFacebookWithDelegate:self];

	} else if ([buttonTitle isEqualToString:KGOSocialMediaTypeTwitter]) {
		UIViewController *twitterVC = [[[TwitterViewController alloc] initWithMessage:[self.delegate twitterTitle]
																				  url:[self.delegate twitterUrl]] autorelease];
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:twitterVC animated:YES];
	}
}

#pragma mark -
#pragma mark Facebook delegation
/*
- (void)loginToFacebook {
    if (!self.facebook) {
		NSString *facebookAppID = [[_preferences objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"AppID"];
        self.facebook = [[Facebook alloc] initWithAppId:facebookAppID];
    }
    // from sample code in facebook-for-ios DemoApp
    NSArray *permissions = [NSArray arrayWithObjects:@"read_stream", @"offline_access",nil];
    [self.facebook authorize:permissions delegate:self];
}

- (void)logoutFromFacebook {
    if (self.facebook) {
        [self.facebook logout:self];
    }
}
*/

- (void)facebookDidLogin {
    loggedIntoFacebook = YES;
    [self showFacebookDialog];
}

- (void)facebookDidLogout {
	;
}

- (void)facebookFailedToLogin {
	;
}

- (void)showFacebookDialog {
	[[KGOSocialMediaController sharedController] shareOnFacebook:[self.delegate fbDialogAttachment] prompt:[self.delegate fbDialogPrompt]];

	 /*
    NSString *attachment = [self.delegate fbDialogAttachment]; // json string
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:attachment forKey:@"attachment"];
    [params setObject:@"Share on Facebook" forKey:@"user_message_prompt"]; // TODO: make this another delegate method
    
    [self.facebook dialog:@"feed" andParams:params andDelegate:self];
	 */
}



#pragma mark -

- (void)dealloc {
    //self.facebook = nil;
	[[KGOSocialMediaController sharedController] setFacebookDelegate:nil];
	self.delegate = nil;
    [super dealloc];
}


@end
