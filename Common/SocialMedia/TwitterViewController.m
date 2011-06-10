#import "TwitterViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

#define TWEET_MAX_CHARS 140

@interface TwitterViewController (Private)

- (void)updateCounter:(NSString *)message delta:(NSInteger)deltaChars;
- (void)refreshNavBarItems;
- (void)populateMessageView;

@end

@implementation TwitterViewController

@synthesize longURL, preCannedMessage, shortURL, delegate;

- (void)refreshNavBarItems
{
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(dismissModalViewControllerAnimated:)] autorelease];

    if ([[KGOSocialMediaController twitterService] isSignedIn]) {
        NSString *title = NSLocalizedString(@"Tweet", nil);
        self.title = title;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:title
                                                                                   style:UIBarButtonItemStyleDone
                                                                                  target:self
                                                                                  action:@selector(tweetButtonPressed:)] autorelease];
        self.navigationItem.leftBarButtonItem = cancelButton;
    } else {
        self.title = NSLocalizedString(@"Sign in to Twitter", nil);
        self.navigationItem.rightBarButtonItem = cancelButton;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self refreshNavBarItems];
    
    _loginHintLabel.text = NSLocalizedString(@"Sign into your Twitter account.", nil);
    
    UIImage *backgroundImage = [[UIImage imageWithPathName:@"common/generic-button-background.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    UIImage *backgroundImagePressed = [[UIImage imageWithPathName:@"common/generic-button-background-pressed.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];

    [_signInButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [_signInButton setBackgroundImage:backgroundImagePressed forState:UIControlStateHighlighted];
    
    _messageView.layer.cornerRadius = 5.0;
    _messageView.layer.borderWidth = 2.0;
    _messageView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    if ([[KGOSocialMediaController twitterService] isSignedIn]) {
        [self twitterDidLogin:nil];

    } else {
        [self twitterDidLogout:nil];
    }
}

- (IBAction)signInButtonPressed:(UIButton *)sender
{
    if ([[KGOSocialMediaController twitterService] isSignedIn]) {
        [[KGOSocialMediaController twitterService] signout];
    } else {
        [[KGOSocialMediaController twitterService] loginTwitterWithUsername:_usernameField.text password:_passwordField.text];
        _loadingView.hidden = NO;
    }
}

- (IBAction)tweetButtonPressed:(id)sender
{
    [[KGOSocialMediaController twitterService] postToTwitter:_messageView.text
                                                      target:self
                                                     success:@selector(tweetDidSucceed)
                                                     failure:@selector(tweetDidFail)];
    _loadingView.hidden = NO;
}

- (void)tweetDidSucceed
{
    if ([self.delegate respondsToSelector:@selector(controllerDidPostTweet:)]) {
        [self.delegate controllerDidPostTweet:self];
    }
}

- (void)tweetDidFail
{
    if ([self.delegate respondsToSelector:@selector(controllerFailedToTweet:)]) {
        [self.delegate controllerFailedToTweet:self];
    }
}

- (void)twitterDidLogin:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TwitterDidLoginNotification object:nil];
    [self refreshNavBarItems];

    _signInButton.hidden = YES;
    
    if ([self.delegate respondsToSelector:@selector(controllerDidLogin:)]) {
        [self.delegate controllerDidLogin:self];
    }
    
    _messageContainerView.hidden = NO;
    _loginContainerView.hidden = YES;
    _usernameLabel.text = [[KGOSocialMediaController twitterService] userDisplayName];
    
    if (self.longURL && !self.shortURL && [[KGOSocialMediaController sharedController] supportsBitlyURLShortening]) {
        _loadingView.hidden = NO;
        
		[[KGOSocialMediaController sharedController] getBitlyURLForLongURL:longURL delegate:self];

    } else {
        [self populateMessageView];
    }
    
    [_messageView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitterDidLogout:)
                                                 name:TwitterDidLogoutNotification
                                               object:nil];
}

- (void)populateMessageView
{
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
        [self updateCounter:_messageView.text delta:0];
    }
}

- (void)twitterDidLogout:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TwitterDidLogoutNotification object:nil];
    [_signInButton setTitle:NSLocalizedString(@"Sign in", nil) forState:UIControlStateNormal];
    _signInButton.hidden = NO;
    [self refreshNavBarItems];
    
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
    [self populateMessageView];
}

- (void)failedToGetBitlyURL
{
    [self populateMessageView];
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

- (void)updateCounter:(NSString *)aMessage delta:(NSInteger)deltaChars {
	_counterLabel.text = [NSString stringWithFormat:@"%i", TWEET_MAX_CHARS - [aMessage length] - deltaChars];
}

@end
