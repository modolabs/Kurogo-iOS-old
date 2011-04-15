#import "TwitterViewController.h"
#import "KGOAppDelegate.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

#define TWEET_MAX_CHARS 140

@interface TwitterViewController (Private)

- (void)updateCounter:(NSString *)message delta:(NSInteger)deltaChars;

@end

@implementation TwitterViewController

@synthesize longURL, preCannedMessage, shortURL, delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tweet"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(tweetButtonPressed:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    self.title = NSLocalizedString(@"Twitter", nil);
    
    _loginHintLabel.text = NSLocalizedString(@"Sign into your Twitter account.", nil);
    
    UIImage *backgroundImage = [UIImage imageWithPathName:@"common/generic-button-background.png"];
    UIImage *backgroundImagePressed = [UIImage imageWithPathName:@"common/generic-button-background-pressed.png"];
    
    [_signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    [_signInButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [_signInButton setBackgroundImage:backgroundImagePressed forState:UIControlStateHighlighted];
    
    [_signOutButton setTitle:NSLocalizedString(@"Sign Out", nil) forState:UIControlStateNormal];
    [_signOutButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [_signOutButton setBackgroundImage:backgroundImagePressed forState:UIControlStateHighlighted];
    
    [_tweetButton setTitle:NSLocalizedString(@"Tweet", nil) forState:UIControlStateNormal];
    _usernameField.placeholder = NSLocalizedString(@"Username", nil);
    _passwordField.placeholder = NSLocalizedString(@"Password", nil);
    
    _messageView.layer.cornerRadius = 5.0;
    _messageView.layer.borderWidth = 2.0;
    _messageView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    if ([[KGOSocialMediaController sharedController] isTwitterLoggedIn]) {
        [self twitterDidLogin:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(twitterDidLogout:)
                                                     name:TwitterDidLogoutNotification
                                                   object:nil];

    } else {
        [self twitterDidLogout:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(twitterDidLogin:)
                                                     name:TwitterDidLoginNotification
                                                   object:nil];
    }
}

- (IBAction)signInButtonPressed:(UIButton *)sender
{
    [[KGOSocialMediaController sharedController] loginTwitterWithUsername:_usernameField.text password:_passwordField.text];
    _loadingView.hidden = NO;
}

- (IBAction)signOutButtonPressed:(UIButton *)sender
{
    [[KGOSocialMediaController sharedController] logoutTwitter];
    _loadingView.hidden = NO;
}

- (IBAction)tweetButtonPressed:(id)sender
{
    [[KGOSocialMediaController sharedController] postToTwitter:_messageView.text];
    _loadingView.hidden = NO;
}

- (void)twitterDidLogin:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TwitterDidLoginNotification object:nil];
    
    [self.delegate controllerDidLogin:self];
    
    self.title = NSLocalizedString(@"Post to Twitter", nil);
    _messageContainerView.hidden = NO;
    _loginContainerView.hidden = YES;
    
    if (self.longURL && !self.shortURL && [[KGOSocialMediaController sharedController] supportsBitlyURLShortening]) {
        _loadingView.hidden = NO;
        
		[[KGOSocialMediaController sharedController] getBitlyURLForLongURL:longURL delegate:self];

    } else {
        _loadingView.hidden = YES;

        NSMutableArray *messageParts = [NSMutableArray array];
        if (self.preCannedMessage) {
            [messageParts addObject:self.preCannedMessage];
        }
        if (self.shortURL) {
            [messageParts addObject:self.shortURL];
        } else if (self.longURL) {
            [messageParts addObject:self.longURL];
        }
        if (messageParts.count) {
            _messageView.text = [messageParts componentsJoinedByString:@"\n"];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitterDidLogout:)
                                                 name:TwitterDidLogoutNotification
                                               object:nil];
}


- (void)twitterDidLogout:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TwitterDidLogoutNotification object:nil];
    
    self.title = NSLocalizedString(@"Sign In to Twitter", nil);
    _loadingView.hidden = YES;
    _messageContainerView.hidden = YES;
    _loginContainerView.hidden = NO;
    [_usernameField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitterDidLogin:)
                                                 name:TwitterDidLoginNotification
                                               object:nil];
}


- (void) dealloc {
    self.shortURL = nil;
    self.longURL = nil;
    self.preCannedMessage = nil;

    [super dealloc];
}

#pragma mark communication with twitter

- (void)didGetBitlyURL:(NSString *)url {
    self.shortURL = url;
    _loadingView.hidden = NO;
}

#pragma mark Text field and Text view delegation

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _usernameField) {
        [textField resignFirstResponder];
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        [self signInButtonPressed:nil];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if (textView.text.length - range.length + text.length <= TWEET_MAX_CHARS) {
		[self updateCounter:textView.text delta:text.length-range.length];
		return YES;
	} else {
		return NO;
	}
}

- (void)updateCounter:(NSString *)aMessage delta:(NSInteger)deltaChars{
	_counterLabel.text = [NSString stringWithFormat:@"%i", TWEET_MAX_CHARS-[aMessage length]-deltaChars];
}

@end
