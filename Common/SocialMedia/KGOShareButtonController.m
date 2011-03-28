#import "KGOShareButtonController.h"
#import "KGOAppDelegate.h"
#import "TwitterViewController.h"
#import "MITMailComposeController.h"

@implementation KGOShareButtonController

@synthesize delegate = _delegate;

- (id)initWithDelegate:(id<KGOShareButtonDelegate>)delegate {
    self = [super init];
    if (self) {
		_delegate = delegate;
	}
	return self;
}

#pragma mark Action Sheet

- (void)shareInView:(UIView *)view {
    UIActionSheet *shareSheet = nil;
    
    shareSheet = [[UIActionSheet alloc] initWithTitle:[self.delegate actionSheetTitle]
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                               destructiveButtonTitle:nil
                                    otherButtonTitles:nil];
	
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:KGOSocialMediaTypeEmail]) {
        [MITMailComposeController presentMailControllerWithEmail:nil
                                                         subject:[self.delegate emailSubject]
                                                            body:[self.delegate emailBody]];

	} else if ([buttonTitle isEqualToString:KGOSocialMediaTypeFacebook]) {
        [self showFacebookDialog];

	} else if ([buttonTitle isEqualToString:KGOSocialMediaTypeTwitter]) {
		TwitterViewController *twitterVC = [[[TwitterViewController alloc] initWithNibName:@"TwitterViewController" bundle:nil] autorelease];
        twitterVC.preCannedMessage = [self.delegate twitterTitle];
        twitterVC.longURL = [self.delegate twitterUrl];
		[KGO_SHARED_APP_DELEGATE() presentAppModalViewController:twitterVC animated:YES];
	}
}

#pragma mark - Facebook

- (void)showFacebookDialog {
	[[KGOSocialMediaController sharedController] shareOnFacebook:[self.delegate fbDialogAttachment]
                                                          prompt:[self.delegate fbDialogPrompt]];
}

#pragma mark -

- (void)dealloc {
	self.delegate = nil;
    [super dealloc];
}


@end
