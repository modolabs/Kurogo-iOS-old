#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "TwitterViewController.h"
#import "JSONAPIRequest.h"

@implementation ShareDetailViewController

@synthesize fbSession, shareDelegate, connection;

/*
- (id)init
{
	if (self = [super init]) {
		actionSheetTitle = nil;
		emailSubject = nil;
		emailBody = nil;
	}
	return self;
}
*/

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    shortURL = nil;
    
    self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    NSString *bitlyURLString = [NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&longURL=%@&format=json",
                                BitlyUsername, BitlyAPIKey, [self.shareDelegate twitterUrl]];
    NSURL *url = [NSURL URLWithString:bitlyURLString];
    [self.connection requestDataFromURL:url];
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    id jsonObj = [JSONAPIRequest objectWithJSONData:data];
    if (jsonObj && [jsonObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *urlData = nil;
        if (urlData = [(NSDictionary *)jsonObj objectForKey:@"data"]) {
            shortURL = [[urlData objectForKey:@"url"] retain];
        }
    }
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
    self.connection = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
    self.connection = nil;
}

#pragma mark Action Sheet

// subclasses should make sure actionSheetTitle is set up before this gets called
// or call [super share:sender] at the end of this
- (void)share:(id)sender {
    UIActionSheet *shareSheet = nil;
    
    if (shortURL) {
        shareSheet = [[UIActionSheet alloc] initWithTitle:[self.shareDelegate actionSheetTitle]
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:@"Email", @"Facebook", @"Twitter", nil];
    } else {
        shareSheet = [[UIActionSheet alloc] initWithTitle:[self.shareDelegate actionSheetTitle]
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:@"Email", @"Facebook", nil];
    }
    
    [shareSheet showInView:self.view];
    [shareSheet release];
}

- (void)sendEmailWithSubject:(NSString *)emailSubject body:(NSString *)emailBody
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
		aController.mailComposeDelegate = self;
		
		[aController setSubject:emailSubject];
		
		[aController setMessageBody:emailBody isHTML:NO];
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:aController animated:YES];
		[aController release];
		
	} else {
		NSString *mailtoString = [NSString stringWithFormat:@"mailto://?subject=%@&body=%@", 
								  [emailSubject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
								  [emailBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
		NSURL *externURL = [NSURL URLWithString:mailtoString];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
}

// subclasses should make sure emailBody and emailSubject are set up before this gets called
// or call [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex] at the end of this
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// Email
        [self sendEmailWithSubject:[self.shareDelegate emailSubject]
							  body:[self.shareDelegate emailBody]];
	}
    else if (buttonIndex == 1) {
		// Facebook session
		[self showFacebookDialog];
	}
	else if (buttonIndex == 2) {
		[self showTwitterView];
	}
}

#pragma mark -
#pragma mark MFMailComposeViewController delegation

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Facebook delegation

- (void)showFacebookDialog {
	BOOL resuming = NO;
	if (!self.fbSession && !(self.fbSession = [FBSession session])) {
		self.fbSession = [FBSession sessionForApplication:FacebookAPIKey secret:FacebookAPISecret delegate:self];
		resuming = [self.fbSession resume];
	}
	
	if (!self.fbSession.isConnected) {
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:self.fbSession] autorelease];
		[dialog show];
	} else if (!resuming) {
		[self postItemToFacebook];
	}
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	[self postItemToFacebook];
}

- (void)postItemToFacebook {
	FBStreamDialog* dialog = [[[FBStreamDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.userMessagePrompt = [self.shareDelegate fbDialogPrompt];
	dialog.attachment = [self.shareDelegate fbDialogAttachment];
	[dialog show];
}

#pragma mark -
#pragma mark Share by Twitter

- (void)showTwitterView {
	UIViewController *twitterVC = [[TwitterViewController alloc] initWithMessage:[self.shareDelegate twitterTitle]
																			 url:shortURL];	
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
    [fbSession release];
    [shortURL release];
    [super dealloc];
}


@end
