#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "TwitterViewController.h"
#import "JSONAPIRequest.h"
#import "MITMailComposeController.h"

@implementation ShareDetailViewController

@synthesize facebook, shareDelegate;

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark Action Sheet

// subclasses should make sure actionSheetTitle is set up before this gets called
// or call [super share:sender] at the end of this
// TODO: conditionally show facebook and twitter
- (void)share:(id)sender {
    UIActionSheet *shareSheet = nil;
    
    shareSheet = [[UIActionSheet alloc] initWithTitle:[self.shareDelegate actionSheetTitle]
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                               destructiveButtonTitle:nil
                                    otherButtonTitles:@"Email", @"Facebook", @"Twitter", nil];
    
    [shareSheet showInView:self.view];
    [shareSheet release];
}

// subclasses should make sure emailBody and emailSubject are set up before this gets called
// or call [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex] at the end of this
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// Email
        [MITMailComposeController presentMailControllerWithEmail:nil subject:[self.shareDelegate emailSubject] body:[self.shareDelegate emailBody]];
	}
    else if (buttonIndex == 1) {
		// Facebook session
        if (loggedIntoFacebook) {
            [self showFacebookDialog];
        } else {
            [self loginToFacebook];
        }
	}
	else if (buttonIndex == 2) {
		[self showTwitterView];
	}
}

#pragma mark -
#pragma mark Facebook delegation

- (void)loginToFacebook {
    if (!self.facebook) {
        self.facebook = [[Facebook alloc] initWithAppId:FacebookAppID];
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

- (void)showFacebookDialog {
    NSString *attachment = [self.shareDelegate fbDialogAttachment]; // json string
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:attachment forKey:@"attachment"];
    [params setObject:@"Share on Facebook" forKey:@"user_message_prompt"]; // TODO: make this another delegate method
    
    // if we want to add an arbitrary list of links, do something like the following:
    /*
     NSDictionary* actionLinks = [NSArray arrayWithObjects:
     [NSDictionary dictionaryWithObjectsAndKeys:@"Always Running",@"text",@"http://itsti.me/",@"href", nil],
     nil];
     [params setObject:actionLinks forKey:@"action_links"];
     */    
    
    [self.facebook dialog:@"feed" andParams:params andDelegate:self];
}

/**
 * Called when the user has logged in successfully.
 */
- (void)fbDidLogin {
    loggedIntoFacebook = YES;
    [self showFacebookDialog];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"failed to log in to facebook");
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fbDidLogout {
    DLog(@"logged out of facebook");
}

// FBRequestDelegate

/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"received response");
};

/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on the format of the API response.
 * If you need access to the raw response, use
 * (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response.
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    DLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSArray class]]) {
        result = [result objectAtIndex:0];
    }
};

/**
 * Called when an error prevents the Facebook API request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    DLog(@"%@", [error description]);
};

// FBDialogDelegate

/**
 * Called when a UIServer Dialog successfully return.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    DLog(@"published successfully");
}


#pragma mark -
#pragma mark Share by Twitter

- (void)showTwitterView {
	UIViewController *twitterVC = [[TwitterViewController alloc] initWithMessage:[self.shareDelegate twitterTitle]
																			 url:[self.shareDelegate twitterUrl]];	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate presentAppModalViewController:twitterVC animated:YES];
	[twitterVC release];
}


#pragma mark -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.facebook = nil;
    [super dealloc];
}


@end
