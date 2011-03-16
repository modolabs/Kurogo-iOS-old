#import "FacebookVideoDetailViewController.h"
#import "FacebookVideo.h"
#import "UIKit+KGOAdditions.h"

@implementation FacebookVideoDetailViewController

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

- (void)displayPost {
    if (!_thumbnail) {
        
        CGRect frame = self.view.bounds;
        frame.size.height = floor(frame.size.width * 9 / 16); // need to tweak this aspect ratio
        _thumbnail = [[MITThumbnailView alloc] initWithFrame:frame];
        _thumbnail.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        self.tableView.tableHeaderView = _thumbnail;
    }
    
    _thumbnail.imageURL = self.video.thumbSrc;
    _thumbnail.imageData = self.video.thumbData;
    [_thumbnail loadImage];
    
    if (!self.video.comments.count) {
        [self getCommentsForPost];
    }
}

- (void)setVideo:(FacebookVideo *)video {
    self.post = video;
}

- (FacebookVideo *)video {
    return (FacebookVideo *)self.post;
}

- (void)playVideo:(id)sender {
    NSString *urlString = nil;
    if ([self.video.src rangeOfString:@"fbcdn.net"].location != NSNotFound) {
        urlString = self.video.src;
    } else {
        urlString = self.video.link;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Video";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageWithPathName:@"common/arrow-white-right"] forState:UIControlStateNormal];
    button.frame = CGRectMake(120, 80, 80, 60);
    [button addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [_thumbnail addSubview:button];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.video.name;
}

@end
