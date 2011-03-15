#import "FacebookPhotoDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "FacebookModel.h"

@implementation FacebookPhotoDetailViewController

@synthesize photo;
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

- (void)displayPost {
    _thumbnail.imageURL = self.photo.src;
    _thumbnail.imageData = self.photo.data;
    [_thumbnail loadImage];
    
    if (!self.photo.comments.count) {
        [self getCommentsForPost];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.post && !self.photo) {
        self.photo = (FacebookPhoto *)self.post;
    } else if (self.photo && !self.post) {
        self.post = self.photo;
    }
    
    if (self.post) {
        KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    }
    
    CGRect frame = self.view.bounds;
    frame.size.height = floor(frame.size.width * 9 / 16); // need to tweak this aspect ratio
    _thumbnail = [[MITThumbnailView alloc] initWithFrame:frame];
    _thumbnail.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    self.tableView.tableHeaderView = _thumbnail;
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

#pragma mark - Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.photo.title;
    //return [NSString stringWithFormat:@"x users like this"];
}

@end
