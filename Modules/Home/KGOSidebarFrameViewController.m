#import "KGOSidebarFrameViewController.h"
#import "SpringboardIcon.h"

@implementation KGOSidebarFrameViewController

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

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    _sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, self.view.bounds.size.height)];
    [self.view addSubview:_sidebar];
    [self setupSidebarIcons];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -

- (void)setupSidebarIcons {
    NSArray *primaryIcons = [self iconsForPrimaryModules:YES];
    CGRect frame;
    CGFloat currentY = 0;
    for (SpringboardIcon *anIcon in primaryIcons) {
        frame = anIcon.frame;
        frame.origin.y = currentY;
        anIcon.frame = frame;
        [_sidebar addSubview:anIcon];
        currentY += frame.size.height + 10;
    }
}

@end
