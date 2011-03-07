#import "TwitterViewController.h"
#import "Constants.h"
#import "KGOAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "MITLoadingActivityView.h"
#import "JSONAPIRequest.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

static NSString * const TwitterRequestType = @"TwitterRequestType";
static NSString * const VerifyCredentials = @"VerifyCredentials";
//static NSString * const SendTweet = @"SendTweet";
static NSString * const CredentialsKey = @"Credentials";

#define INPUT_FIELDS_MARGIN 10.0
#define INPUT_FIELDS_HEIGHT 32.0
#define INPUT_FIELDS_TOP 69.0
#define INPUT_FIELDS_FONT [UIFont systemFontOfSize:15];

#define INSTRUCTIONS_MARGIN 15.0
#define INSTRUCTIONS_HEIGHT 20.0
#define INSTRUCTIONS_TOP 30.0

#define MESSAGE_HEIGHT 157.0
#define MESSAGE_MARGIN 7.0

#define BOTTOM_SECTION_TOP 3.0
#define BOTTOM_SECTION_HEIGHT 30.0

#define USERNAME_MAX_WIDTH 150.0

@interface TwitterViewController (Private)

- (void) loadLoginView;
- (void) loadMessageInputView;
- (void) updateMessageInputView;
- (void) dismissTwitterViewController;
- (void) updateTwitterSessionUI;

- (void) logoutTwitter;
- (void) loginTwitter;
- (void) sendTweet;

- (void)updateCounter:(NSString *)message delta:(NSInteger)deltaChars;
- (void)hideNetworkActivity;
- (void)showNetworkActivity;

@end

@implementation TwitterViewController

@synthesize connection, contentView;

- (id) initWithMessage: (NSString *)aMessage url:(NSString *)aLongUrl {
	if(self = [super init]) {
		passwordField = nil;
		usernameField = nil;
		
		messageField = nil;	
		usernameLabel = nil;
		signOutButton = nil;
		
		self.contentView = nil;
		navigationItem = nil;
		
		message = [aMessage retain];
		longURL = [aLongUrl retain];
		
		twitterEngine = nil;
		
		authenticationRequestInProcess = NO;
	}
	return self;
}

- (void) dealloc {
	usernameField.delegate = nil;
	passwordField.delegate = nil;
	messageField.delegate = nil;
	
	[messageField release];
	[usernameLabel release];
	[signOutButton release];

    self.contentView = nil;
	[usernameField release];
	[passwordField release];
	
	[message release];
	[longURL release];
    [shortURL release];
    [counterLabel release];
    
    [token release];
    token = nil;
	
	// close all connections to twitter (This is probably the ideal UI)
	// additionally we really dont have a choice since the twitterEngine has no way of setting delegate = nil
	if(authenticationRequestInProcess) {
        [self hideNetworkActivity];
	}
	
	for(NSString *identifier in [twitterEngine connectionIdentifiers]) {
		[twitterEngine closeConnection:identifier];
        [self hideNetworkActivity];
	}
	[twitterEngine release];
    [super dealloc];
}

#pragma mark UI

- (void) loadView {
	[super loadView];
    
    self.title = @"Twitter";
	
    /*
	UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)] autorelease];
	navBar.barStyle= UIBarStyleBlack;
	navigationItem = [[[UINavigationItem alloc] initWithTitle:@"Twitter"] autorelease];
	navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissTwitterViewController)] autorelease];
	navBar.items = [NSArray arrayWithObject:navigationItem];
	*/
	self.view.opaque = YES;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	//[self.view addSubview:navBar];
	[[KGOSocialMediaController sharedController] loginTwitterWithDelegate:self];
}

- (void)showLoginScreen {
	[self.contentView removeFromSuperview];
    self.contentView = nil;
	
	[self loadLoginView];
	navigationItem.title = @"Sign in to Twitter";
	navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign in" style:UIBarButtonItemStyleDone target:self action:@selector(loginTwitter)] autorelease];
	[usernameField becomeFirstResponder];
	
	[self.view addSubview:self.contentView];
}

- (void)showMessageScreen {
	[self.contentView removeFromSuperview];
    self.contentView = nil;
	
	navigationItem.rightBarButtonItem.enabled = YES;
	authenticationRequestInProcess = NO;
	
	navigationItem.title = @"Post to Twitter";
	if (longURL && !shortURL) {            
		self.contentView = [[[MITLoadingActivityView alloc] initWithFrame:CGRectMake(0, 44.0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
		[[KGOSocialMediaController sharedController] getBitlyURLForLongURL:longURL delegate:self];
		
	} else {
		[self loadMessageInputView];
		[messageField becomeFirstResponder];
		navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tweet" style:UIBarButtonItemStyleDone target:self action:@selector(sendTweet)] autorelease];
		[self updateMessageInputView];
	}
	
	[self.view addSubview:self.contentView];
}

- (void)promptForTwitterLogin {
	[self showLoginScreen];
}

- (void)twitterDidLogout {
	[self showLoginScreen];
}

- (void)twitterFailedToLogin {
	;
}

- (void)twitterDidLogin {
	[self showMessageScreen];
}

- (void)twitterRequestSucceeded:(NSString *)connectionIdentifier {
	;
}

- (void) dismissTwitterViewController {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) loadMessageInputView {
    //CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
    //contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
    //contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;

    CGRect contentFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    UIView *messageInputView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
    
    signOutButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    UIImage *signOutImage = [UIImage imageWithPathName:@"common/twitter_signout.png"];
    UIImage *signOutImagePressed = [UIImage imageWithPathName:@"common/twitter_signout_pressed.png"];
    [signOutButton setImage:signOutImage forState:UIControlStateNormal];
    [signOutButton setImage:signOutImagePressed forState:(UIControlStateNormal | UIControlStateHighlighted)];
    signOutButton.frame = CGRectMake(USERNAME_MAX_WIDTH, MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, signOutImage.size.width, signOutImage.size.height);
    [signOutButton addTarget:self action:@selector(logoutTwitter) forControlEvents:UIControlEventTouchUpInside];
    [messageInputView addSubview:signOutButton];
    
    usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(MESSAGE_MARGIN, 
                                                              MESSAGE_HEIGHT+BOTTOM_SECTION_TOP,
                                                              USERNAME_MAX_WIDTH, 
                                                              BOTTOM_SECTION_HEIGHT)];
    usernameLabel.font = [[KGOTheme sharedTheme] fontForBodyText];
    usernameLabel.backgroundColor = [UIColor clearColor];
    usernameLabel.textColor = [UIColor blackColor];
    [messageInputView addSubview:usernameLabel];
    
    CGRect messageFrame = CGRectMake(MESSAGE_MARGIN,
                                     MESSAGE_MARGIN, 
                                     contentFrame.size.width - 2 * MESSAGE_MARGIN,
                                     MESSAGE_HEIGHT - 2 * MESSAGE_MARGIN);
    
    // we use a UITextField to give the the UITextView
    // the same appearance as a UITextField, but
    // we keep it behind the the UITextView, because we
    // want the multiple line functionality of a UITextView
    UITextField *fakeMessageField = [[[UITextField alloc] initWithFrame:messageFrame] autorelease];
    fakeMessageField.borderStyle = UITextBorderStyleRoundedRect;
    fakeMessageField.enabled = NO;
    [messageInputView addSubview:fakeMessageField];
    
    messageField = [[UITextView alloc] initWithFrame:CGRectInset(messageFrame, MESSAGE_MARGIN, MESSAGE_MARGIN)];
    messageField.text = [NSString stringWithFormat:@"%@:\n%@", message, shortURL];
    messageField.delegate = self;
    messageField.backgroundColor = [UIColor clearColor];
    messageField.font = [UIFont systemFontOfSize:17.0];
    [messageInputView addSubview:messageField];
    
    counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(contentFrame.size.width-MESSAGE_MARGIN-40, 
                                                             MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, 
                                                             40, 
                                                             BOTTOM_SECTION_HEIGHT)];
	// TODO: this is not a cell, use a different theme
    counterLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleDefault];
    counterLabel.backgroundColor = [UIColor clearColor];
    counterLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellTitleWithStyle:KGOTableCellStyleDefault];
    counterLabel.textAlignment = UITextAlignmentRight;
    [messageInputView addSubview:counterLabel];
    
    self.contentView = messageInputView;
}

- (void) updateMessageInputView {
	NSString *username = [[KGOSocialMediaController sharedController] twitterUsername];
	usernameLabel.text = username;	
	// make sure sign out button is aligned directly left of username
	CGRect frame = signOutButton.frame;
	frame.origin.x = 2*MESSAGE_MARGIN + [username sizeWithFont:usernameLabel.font].width;
	signOutButton.frame = frame;
}

- (void) loadLoginView {
    //CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
    //contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
    //contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;
    
    CGRect contentFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

    UIView *loginView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
    
    UILabel *instructionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                           INSTRUCTIONS_MARGIN, 
                                                                           INSTRUCTIONS_TOP,
                                                                           contentFrame.size.width - 2 * INSTRUCTIONS_MARGIN,																  
                                                                           INSTRUCTIONS_HEIGHT
                                                                           )] autorelease];
    instructionLabel.numberOfLines = 0;
    instructionLabel.textAlignment = UITextAlignmentCenter;
    instructionLabel.text = @"Please sign into your Twitter account.";
    instructionLabel.font = [UIFont systemFontOfSize:17.0];
    instructionLabel.backgroundColor = [UIColor clearColor];
    
    CGFloat fieldWidth = contentFrame.size.width - 2 * INPUT_FIELDS_MARGIN;
    
    passwordField = [[UITextField alloc] initWithFrame:CGRectMake(
                                                                  INPUT_FIELDS_MARGIN, 
                                                                  INPUT_FIELDS_TOP+INPUT_FIELDS_HEIGHT+INPUT_FIELDS_MARGIN,
                                                                  fieldWidth, 
                                                                  INPUT_FIELDS_HEIGHT)];
    passwordField.borderStyle = UITextBorderStyleRoundedRect;
    passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    passwordField.font = INPUT_FIELDS_FONT;
    passwordField.placeholder = @"Password";
    passwordField.secureTextEntry = YES;
    passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordField.returnKeyType = UIReturnKeyGo;
    passwordField.delegate = self;
	
    usernameField = [[UITextField alloc] initWithFrame:CGRectMake(INPUT_FIELDS_MARGIN, INPUT_FIELDS_TOP, fieldWidth, INPUT_FIELDS_HEIGHT)];
    usernameField.borderStyle = UITextBorderStyleRoundedRect;
    usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    usernameField.font = INPUT_FIELDS_FONT;
    usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameField.placeholder = @"Username";
    usernameField.returnKeyType = UIReturnKeyNext;
    usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameField.delegate = self;
	
    [loginView addSubview:instructionLabel];
    [loginView addSubview:usernameField];
    [loginView addSubview:passwordField];
    
    self.contentView = loginView;
}

- (void)hideNetworkActivity {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

- (void)showNetworkActivity {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
}

#pragma mark communication with twitter

- (void) logoutTwitter {
	[[KGOSocialMediaController sharedController] logoutTwitter];
}
	
- (void) loginTwitter {
	[[KGOSocialMediaController sharedController] loginTwitterWithUsername:usernameField.text password:passwordField.text];
	authenticationRequestInProcess = YES;
	navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) sendTweet {
	[[KGOSocialMediaController sharedController] postToTwitter:messageField.text];
}

- (void)didGetBitlyURL:(NSString *)url {
	[shortURL release];
	shortURL = [url retain];
	[self showMessageScreen];
}

#pragma mark Text field and Text view delegation

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == usernameField) {
        [textField resignFirstResponder];
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        [self loginTwitter];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if(textView.text.length - range.length + text.length <= 140) {
		[self updateCounter:textView.text delta:text.length-range.length];
		return YES;
	} else {
		return NO;
	}
}

- (void)updateCounter:(NSString *)aMessage delta:(NSInteger)deltaChars{
	counterLabel.text = [NSString stringWithFormat:@"%i", 140-[aMessage length]-deltaChars];
}


@end
