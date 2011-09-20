#import "VideoDetailViewController.h"
#import "VideoWebViewController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOLabel.h"
#import "KGOAppDelegate+ModuleAdditions.h"

typedef enum {
    kVideoDetailTitleLabelTag = 0x1890,
    kVideoDetailPlayerTag,
    kVideoDetailImageViewTag,
    kVideoDetailDescriptionTag,
    kVideoDetailImageOverlayTag
}
VideoDetailSubviewTags;

static const CGFloat kVideoDetailMargin = 10.0f;
static const CGFloat kVideoTitleLabelHeight = 80.0f;
static const CGFloat extraScrollViewHeight = 100.0f;

#pragma mark Private methods

@interface VideoDetailViewController (Private)

#pragma mark Tap actions
- (void)videoImageTapped:(UIGestureRecognizer *)recognizer;

#pragma mark Subview setup
- (void)makeAndAddVideoImageViewToView:(UIView *)parentView;


@end

@implementation VideoDetailViewController (Private)

#pragma mark Tap actions
- (void)videoImageTapped:(UIGestureRecognizer *)recognizer
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.video, @"video", nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameWebViewDetail forModuleTag:self.video.moduleTag params:params];
}

#pragma mark Subview setup
// TODO: this function is only used once with parentView being self.scrollView
// don't code this to look like it's causing side effects somewhere else.
- (void)makeAndAddVideoImageViewToView:(UIView *)parentView
{
    // Scale frame to fit in view.
    CGFloat idealFrameWidth = parentView.frame.size.width - 2 * kVideoDetailMargin;

    // we will adjust the height after the image comes in
    CGFloat probableHeight = floor(idealFrameWidth * 0.75);
    CGFloat y = [self viewForTableHeader].frame.size.height + kVideoDetailMargin * 2;
    CGRect imageFrame = CGRectMake(kVideoDetailMargin,
                                   y,
                                   //kVideoDetailMargin * 2 + kVideoTitleLabelHeight + bookmarkSharingView.frame.size.height, 
                                   idealFrameWidth,
                                   probableHeight);
    MITThumbnailView *imageView = [[[MITThumbnailView alloc] initWithFrame:imageFrame] autorelease];
    imageView.delegate = self;
    imageView.tag = kVideoDetailImageViewTag;
    imageView.imageURL = self.video.stillFrameImageURLString;
    
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = nil;
    
    recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector(videoImageTapped:)] autorelease];
    recognizer.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:recognizer];
    [imageView loadImage];
    
    UIImage *overlayImage = [UIImage imageWithPathName:@"modules/video/playoverlay"];
    UIImageView *overlayView = [[[UIImageView alloc] initWithImage:overlayImage] autorelease];
    overlayView.tag = kVideoDetailImageOverlayTag;
    overlayView.center = CGPointMake(floor(imageView.bounds.size.width / 2),
                                     floor(imageView.bounds.size.height / 2));

    [imageView addSubview:overlayView];
    
    [parentView addSubview:imageView];
}

@end



@implementation VideoDetailViewController

@synthesize video;
@synthesize player;
@synthesize dataManager;
@synthesize section;
@synthesize scrollView;
@synthesize headerView = _headerView;

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    CGRect frame = thumbnail.frame;
    CGSize imageSize = thumbnail.imageView.image.size;
    frame.size.height = floor(thumbnail.frame.size.width * imageSize.height / imageSize.width);
    thumbnail.frame = frame;
    UIView *overlayView = [thumbnail viewWithTag:kVideoDetailImageOverlayTag];
    overlayView.center = CGPointMake(floor(thumbnail.bounds.size.width / 2),
                                     floor(thumbnail.bounds.size.height / 2));
    [thumbnail bringSubviewToFront:overlayView];
    [self setDescription];
}

- (id)initWithVideo:(Video *)aVideo andSection:(NSString *)videoSection
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.video = aVideo;
        self.section = videoSection;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    _shareController = [[KGOShareButtonController alloc] initWithContentsController:self];
    _shareController.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook | KGOShareControllerShareTypeTwitter;
    
    if (self.section) {
        [self requestVideoForDetailView];
    }
    
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIView *headerView = [self viewForTableHeader];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:headerView];
    
    // TODO: When non-YouTube feeds are worked in, if they have streams
    // playable in MPMoviePlayerController, put an embedded player here conditionally.
    [self makeAndAddVideoImageViewToView:scrollView];
    
    [self setDescription];

    // when coming from federated search we don't know which section we're in
    if (self.section) {
        // TODO: don't request this every time we're loaded
        [self requestVideoForDetailView];
    }
    
    [self.view addSubview:scrollView];
}

- (void)requestVideoForDetailView {
    __block VideoDetailViewController *blockSelf = self;
    [self.dataManager requestVideoForDetailSection:self.section
                                        andVideoID:(NSString *)self.video.videoID 
                                      thenRunBlock:^(id result) {
                                          [blockSelf setDescription];
                                      }];
}

- (void)setDescription
{
    UIView *videoImageView = [scrollView viewWithTag:kVideoDetailImageViewTag];
    CGFloat width = self.view.bounds.size.width - 2 * kVideoDetailMargin;
    CGFloat y = kVideoDetailMargin + videoImageView.frame.origin.y + videoImageView.frame.size.height;

    UILabel *descriptionLabel = (UILabel *)[scrollView viewWithTag:kVideoDetailDescriptionTag];
    UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
    if (!descriptionLabel) {
        descriptionLabel = [KGOLabel multilineLabelWithText:video.videoDescription
                                                       font:font
                                                      width:width];
        descriptionLabel.tag = kVideoDetailDescriptionTag;
        [scrollView addSubview:descriptionLabel];

    } else {
        descriptionLabel.text = video.videoDescription;
        CGRect rect = descriptionLabel.frame;
        rect.size.height = [descriptionLabel.text sizeWithFont:font
                                             constrainedToSize:CGSizeMake(rect.size.width, 10000)
                                                 lineBreakMode:UILineBreakModeWordWrap].height;
        descriptionLabel.frame = rect;
    }
    descriptionLabel.frame = CGRectMake(kVideoDetailMargin, y, width, descriptionLabel.frame.size.height);
    
    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width,
                                        y + kVideoDetailMargin + descriptionLabel.frame.size.height);
    scrollView.scrollEnabled = YES;
}

- (UIView *)viewForTableHeader
{
    if (!self.headerView) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 30);
        self.headerView = [[[KGODetailPageHeaderView alloc] initWithFrame:frame] autorelease];
        self.headerView.delegate = self;
        self.headerView.showsBookmarkButton = YES;
        self.headerView.showsShareButton = YES;
        self.headerView.showsSubtitle = NO;
        // TODO: this will be broken if we add pageup/pagedown to this view
        self.headerView.detailItem = self.video; 
    }
    
    return self.headerView;
}

- (void)headerView:(KGODetailPageHeaderView *)headerView shareButtonPressed:(id)sender
{
    _shareController.actionSheetTitle = NSLocalizedString(@"Share Video", nil);
    _shareController.shareTitle = video.title;
    //_shareController.shareBody = video.videoDescription;
    _shareController.shareURL = video.url;
    
    [_shareController shareInView:self.view];
}

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    CGFloat y = [self viewForTableHeader].frame.size.height + kVideoDetailMargin * 2;
    UIView *videoImageView = [scrollView viewWithTag:kVideoDetailImageViewTag];
    CGRect frame = videoImageView.frame;
    frame.origin.y = y;
    videoImageView.frame = frame;
    [self setDescription];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {  
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"View Video", nil);
    
    [self.player play];
}

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
    [dataManager release];
    [player release];
    [video release];
    self.scrollView = nil;
    [super dealloc];
}


@end
