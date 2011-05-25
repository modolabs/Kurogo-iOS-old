//  VideoWebViewController.m
//  Universitas
//

#import "VideoWebViewController.h"


@implementation VideoWebViewController

@synthesize URL;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithURL:(NSURL *)theURL {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization.
        self.URL = theURL;
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view = webView;
    [webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
    [webView release];
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
    [URL release];
    [super dealloc];
}


@end
