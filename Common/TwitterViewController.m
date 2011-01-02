#import "TwitterViewController.h"
#import "MITUIConstants.h"
#import "Constants.h"
#import "MIT_MobileAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "MITLoadingActivityView.h"
#import "JSONAPIRequest.h"

static NSString * const TwitterRequestType = @"TwitterRequestType";
static NSString * const VerifyCredentials = @"VerifyCredentials";
static NSString * const SendTweet = @"SendTweet";
static NSString * const CredentialsKey = @"Credentials";
static NSString * const TwitterServiceName = @"Twitter";

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
	
	// close all connections to twitter (This is probably the ideal UI)
	// additionally we really dont have a choice since the twitterEngine has no way of setting delegate = nil
	if(authenticationRequestInProcess) {
		[twitterEngine cancelAccessTokenExchange];
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
	
	twitterEngine = [[XAuthTwitterEngine alloc] initXAuthWithDelegate:self];
	twitterEngine.consumerKey = TwitterOAuthConsumerKey;
	twitterEngine.consumerSecret = TwitterOAuthConsumerSecret;
	
	UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)] autorelease];
	navBar.barStyle= UIBarStyleBlack;
	navigationItem = [[[UINavigationItem alloc] initWithTitle:@"Twitter"] autorelease];
	navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissTwitterViewController)] autorelease];
	navBar.items = [NSArray arrayWithObject:navigationItem];
	
	self.view.opaque = YES;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	[self.view addSubview:navBar];
	[self updateTwitterSessionUI];
}

- (void) updateTwitterSessionUI {
	[self.contentView removeFromSuperview];
    self.contentView = nil;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey]) {
		// user has logged in
		navigationItem.title = @"Post to Twitter";
        if (!shortURL) {
            self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
            NSString *bitlyURLString = [NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&longURL=%@&format=json",
                                        BitlyUsername, BitlyAPIKey, longURL];
            NSURL *url = [NSURL URLWithString:bitlyURLString];
            [self.connection requestDataFromURL:url];
            [self showNetworkActivity];
            
            self.contentView = [[[MITLoadingActivityView alloc] initWithFrame:CGRectMake(0, 44.0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
            
        } else {
            [self loadMessageInputView];
            [messageField becomeFirstResponder];
            navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tweet" style:UIBarButtonItemStyleDone target:self action:@selector(sendTweet)] autorelease];
            [self updateMessageInputView];
        }
		
	} else {
		// user has not yet logged in, so show them the login view
		[self loadLoginView];
		navigationItem.title = @"Sign in to Twitter";
		navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign in" style:UIBarButtonItemStyleDone target:self action:@selector(loginTwitter)] autorelease];
		[usernameField becomeFirstResponder];
	}
	
	[self.view addSubview:self.contentView];
}
	
- (void) dismissTwitterViewController {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) loadMessageInputView {
    CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
    contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
    contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;
    
    UIView *messageInputView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
    
    signOutButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    UIImage *signOutImage = [UIImage imageNamed:@"global/twitter_signout.png"];
    UIImage *signOutImagePressed = [UIImage imageNamed:@"global/twitter_signout_pressed.png"];
    [signOutButton setImage:signOutImage forState:UIControlStateNormal];
    [signOutButton setImage:signOutImagePressed forState:(UIControlStateNormal | UIControlStateHighlighted)];
    signOutButton.frame = CGRectMake(USERNAME_MAX_WIDTH, MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, signOutImage.size.width, signOutImage.size.height);
    [signOutButton addTarget:self action:@selector(logoutTwitter) forControlEvents:UIControlEventTouchUpInside];
    [messageInputView addSubview:signOutButton];
    
    usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(MESSAGE_MARGIN, 
                                                              MESSAGE_HEIGHT+BOTTOM_SECTION_TOP,
                                                              USERNAME_MAX_WIDTH, 
                                                              BOTTOM_SECTION_HEIGHT)];
    usernameLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
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
    //messageField.delegate = [[MessageFieldDelegate alloc] initWithMessage:messageField.text counter:counterLabel];
    messageField.backgroundColor = [UIColor clearColor];
    messageField.font = [UIFont systemFontOfSize:17.0];
    [messageInputView addSubview:messageField];
    
    counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(contentFrame.size.width-MESSAGE_MARGIN-40, 
                                                             MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, 
                                                             40, 
                                                             BOTTOM_SECTION_HEIGHT)];
    counterLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
    counterLabel.backgroundColor = [UIColor clearColor];
    counterLabel.textColor = CELL_STANDARD_FONT_COLOR;
    counterLabel.textAlignment = UITextAlignmentRight;
    [messageInputView addSubview:counterLabel];
    
    self.contentView = messageInputView;
}

- (void) updateMessageInputView {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	usernameLabel.text = username;	
	// make sure sign out button is aligned directly left of username
	CGRect frame = signOutButton.frame;
	frame.origin.x = 2*MESSAGE_MARGIN + [username sizeWithFont:usernameLabel.font].width;
	signOutButton.frame = frame;
}

- (void) loadLoginView {
    CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
    contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
    contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;
    
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
    instructionLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];
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
	[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

- (void)showNetworkActivity {
	[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
}

#pragma mark communication with twitter

- (void) logoutTwitter {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:TwitterShareUsernameKey];
	
	NSError *error = nil;
	[SFHFKeychainUtils deleteItemForUsername:username andServiceName:TwitterServiceName error:&error];

	[self updateTwitterSessionUI];
}
	
- (void) loginTwitter {
	[twitterEngine exchangeAccessTokenForUsername:usernameField.text password:passwordField.text];
	authenticationRequestInProcess = YES;
	navigationItem.rightBarButtonItem.enabled = NO;
    [self showNetworkActivity];
}

- (void) sendTweet {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	[twitterEngine setUsername:username password:nil];

	[twitterEngine sendUpdate:messageField.text];
	
    [self showNetworkActivity];
}
	
- (NSString *) cachedTwitterXAuthAccessTokenStringForUsername: (NSString *)username {
	NSError *error = nil;
	NSString *accessToken = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:TwitterServiceName error:&error];
	if (error) {
		DLog(@"something went wrong looking up access token, error=%@", error);
		return nil;
	} else {
		return accessToken;
	}
}

#pragma mark ConnectionWrapper

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
    [self updateTwitterSessionUI];
}

- (BOOL)connection:(ConnectionWrapper *)connection shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
    self.connection = nil;
}

#pragma mark XAuthTwitterEngineDelegate

- (void)storeCachedTwitterXAuthAccessTokenString:(NSString *)accessToken forUsername:(NSString *)username {
	[[NSUserDefaults standardUserDefaults] setObject:username forKey:TwitterShareUsernameKey];
	NSError *error = nil;
	[SFHFKeychainUtils storeUsername:username andPassword:accessToken forServiceName:TwitterServiceName updateExisting:YES error:&error];
	
	navigationItem.rightBarButtonItem.enabled = YES;
	authenticationRequestInProcess = NO;
	[self hideNetworkActivity];
	
	if (!error) {
		[self updateTwitterSessionUI];
	} else {
		DLog(@"error on saving token=%@",error);
	}
}
	
- (void)twitterXAuthConnectionDidFailWithError:(NSError *)error {
	NSString *errorMsg;
	if(error.code == -1012) {
		errorMsg = NSLocalizedString(@"Twitter was unable to authenticate your username and/or password", nil);
	} else if (error.code == -1009) {
		errorMsg = NSLocalizedString(@"Failed to connect to the twitter server", nil);
	} else	{
		errorMsg = NSLocalizedString(@"Something went wrong while trying to authenicate your twitter account", nil);
		DLog(@"unusual error=%@", error);
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Twitter Failure", nil)
		message:errorMsg 
		delegate:nil 
		cancelButtonTitle:@"OK" 
		otherButtonTitles:nil];
	[alertView show];
	[alertView release];
	navigationItem.rightBarButtonItem.enabled = YES;
	authenticationRequestInProcess = NO;
	[self hideNetworkActivity];
}

#pragma mark MGTwitterEngineDelegate
	
- (void)requestSucceeded:(NSString *)connectionIdentifier {
	[self hideNetworkActivity];
	[self dismissTwitterViewController];
}
					 
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
	[self hideNetworkActivity];
	
	NSString *errorTitle;
	NSString *errorMessage;
	
	if (error.code == 401) {
		errorTitle = @"Login failed";
		errorMessage = @"Twitter username and password is not recognized";
		[self logoutTwitter];
	} else {
		errorTitle = @"Network failed";
		errorMessage = @"Failure connecting to Twitter";
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] 
							  initWithTitle:errorTitle 
							  message:errorMessage
							  delegate:nil 
							  cancelButtonTitle:@"Cancel" 
							  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
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
