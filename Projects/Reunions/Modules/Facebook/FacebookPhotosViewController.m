#import "FacebookPhotosViewController.h"


@implementation FacebookPhotosViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)loadView {
	[super loadView];
    
    [[KGOSocialMediaController sharedController] loginFacebookWithDelegate:self];
    
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark FacebookWrapperDelegate

- (void)facebookDidLogin {
    [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:@"me/groups" andDelegate:self];

}


- (void)facebookFailedToLogin {
    
}


- (void)facebookDidLogout {
    
}

#pragma mark FBRequestDelegate

- (void)request:(FBRequest *)request didLoad:(id)result {
    DLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSArray *data = [result objectForKey:@"data"];
        for (id aGroup in data) {
            NSLog(@"%@", aGroup);
        }
    }
}

@end
