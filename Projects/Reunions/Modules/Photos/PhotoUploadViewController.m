#import "PhotoUploadViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookPhotosViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation PhotoUploadViewController

@synthesize photo, profile, parentVC;

- (IBAction)submitButtonPressed:(UIButton *)sender {
    _loadingView.hidden = NO;
    
    [[KGOSocialMediaController sharedController] uploadPhoto:self.photo
                                           toFacebookProfile:self.profile
                                                     message:_textView.text
                                                    delegate:self.parentVC];
    
    
}

- (void)cancelButtonPressed:(id)sender {
    
}

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // UIImagePickerController comes with a translucent nav bar, which causes
    // the nav bar to overlap the view
    if (self.navigationController && self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent) {
        CGFloat offsetHeight = self.navigationController.navigationBar.frame.size.height;
        CGRect frame;
        for (UIView *aView in self.view.subviews) {
            frame = aView.frame;
            frame.origin.y += offsetHeight;
            aView.frame = frame;
        }
    }
    
    _textView.layer.cornerRadius = 5.0;
    _textView.layer.borderColor = [[UIColor blackColor] CGColor];
    _textView.layer.borderWidth = 1.0;
    
    _imageView.image = self.photo;
    
    [_submitButton setTitle:NSLocalizedString(@"Upload", nil) forState:UIControlStateNormal];
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

@end
