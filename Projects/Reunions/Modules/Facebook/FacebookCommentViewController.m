#import "FacebookCommentViewController.h"
#import "FacebookPost.h"
#import "FacebookComment.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOSocialMediaController.h"
#import "KGOAppDelegate.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"

@implementation FacebookCommentViewController

@synthesize post, delegate;
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (IBAction)submitButtonPressed:(UIButton *)sender {
    [[KGOSocialMediaController sharedController] addComment:_textView.text 
                                             toFacebookPost:self.post
                                                   receiver:self
                                                   callback:@selector(didPostComment:)];
    _loadingViewContainer.hidden = NO;
    [_spinner startAnimating];
}

- (void)didPostComment:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSString *identifier = [result stringForKey:@"id" nilIfEmpty:YES];
        FacebookComment *aComment = [FacebookComment commentWithID:identifier];
        aComment.text = _textView.text;
        [self.delegate didPostComment:aComment];
        [_spinner stopAnimating];
        [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] dismissAppModalViewControllerAnimated:YES];
    }
}

- (void)didFailToPostComment:(NSError *)error {
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    
    [_submitButton setTitle:NSLocalizedString(@"Comment", nil) forState:UIControlStateNormal];
    
    _textView.layer.cornerRadius = 5.0;
    _textView.layer.borderColor = [[UIColor blackColor] CGColor];
    _textView.layer.borderWidth = 2.0;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITextView

@end
