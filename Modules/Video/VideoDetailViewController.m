#import "VideoDetailViewController.h"
#import "VideoWebViewController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOLabel.h"
#import "KGOAppDelegate+ModuleAdditions.h"

typedef enum {
    kVideoDetailScrollViewTag = 0x1890,
    kVideoDetailTitleLabelTag,
    kVideoDetailPlayerTag,
    kVideoDetailImageViewTag,
    kVideoDetailDescriptionTag
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
    // TODO: we should be able to use MITThumbnailView to do this.
    // no need to use a synchronous request.
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.video.stillFrameImageURLString]]];
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    imageView.tag = kVideoDetailImageViewTag;
    CGRect imageViewFrame = imageView.frame;
    imageViewFrame.origin.x = kVideoDetailMargin;
    imageViewFrame.origin.y = kVideoDetailMargin * 2 + kVideoTitleLabelHeight + bookmarkSharingView.frame.size.height;
    
    // Scale frame to fit in view.
    CGFloat idealFrameWidth = parentView.frame.size.width - 2 * kVideoDetailMargin;
    if (imageViewFrame.size.width > idealFrameWidth) {
        CGFloat idealToActualWidthProportion = idealFrameWidth / imageViewFrame.size.width;
        imageViewFrame.size.width = idealFrameWidth;
        imageViewFrame.size.height *= idealToActualWidthProportion;
    }
    imageView.frame = imageViewFrame;
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = 
    [[UITapGestureRecognizer alloc] initWithTarget:self 
                                         action:@selector(videoImageTapped:)];
    recognizer.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:recognizer];
    [recognizer release];
    
    UIImage *overlayImage = [UIImage imageWithPathName:@"modules/video/playoverlay"];
    UIImageView *overlayView = [[[UIImageView alloc] initWithImage:overlayImage] autorelease];
    overlayView.center = CGPointMake(floor(imageView.bounds.size.width / 2),
                                     floor(imageView.bounds.size.height / 2));

    /*
    CGRect overlayFrame = overlayView.frame;
    overlayFrame.origin.x = 
    parentView.frame.size.width / 2 - overlayFrame.size.width / 2;
    overlayFrame.origin.y = 
    imageViewFrame.size.height / 2 - overlayFrame.size.height / 2;
    overlayView.frame = overlayFrame;
     */
    [imageView addSubview:overlayView];
    
    [parentView addSubview:imageView];
    //[imageView release];
    //[overlayView release];
}
@end



@implementation VideoDetailViewController

@synthesize video;
@synthesize player;
@synthesize dataManager;
@synthesize section;
@synthesize scrollView;
@synthesize headerView = _headerView;

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

    CGFloat width = self.view.bounds.size.width - 2 * kVideoDetailMargin;
    UILabel *titleLabel = [KGOLabel multilineLabelWithText:self.video.title
                                                      font:[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle]
                                                     width:width];
    titleLabel.frame = CGRectMake(kVideoDetailMargin,
                                  kVideoDetailMargin,
                                  titleLabel.frame.size.width,
                                  kVideoTitleLabelHeight); // we're fixing the height despite setting numberOfLines to 0?
    titleLabel.tag = kVideoDetailTitleLabelTag;
    [scrollView addSubview:titleLabel];
    
    //add sharing and bookmark buttons
    bookmarkSharingView = [self viewForTableHeader];
    [scrollView addSubview:bookmarkSharingView];
    
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
                                          //blockSelf.video.videoDescription = [(Video *)result videoDescription];
                                          [blockSelf setDescription];
                                      }];
}

- (void)setDescription
{
    UIView *videoImageView = [scrollView viewWithTag:kVideoDetailImageViewTag];
    CGFloat width = self.view.bounds.size.width - 2 * kVideoDetailMargin;
    CGFloat y = kVideoDetailMargin * 3 + kVideoTitleLabelHeight + videoImageView.frame.size.height + bookmarkSharingView.frame.size.height;
    UILabel *descriptionLabel = [KGOLabel multilineLabelWithText:video.videoDescription
                                                            font:[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText]
                                                           width:width];
    descriptionLabel.frame = CGRectMake(kVideoDetailMargin, y, width, descriptionLabel.frame.size.height);
    descriptionLabel.tag = kVideoDetailDescriptionTag;
    descriptionLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:descriptionLabel];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, y + descriptionLabel.frame.size.height);
    scrollView.tag = kVideoDetailScrollViewTag;
    scrollView.scrollEnabled = YES;
}

- (UIView *)viewForTableHeader
{
    if (!self.headerView) {
        self.headerView = [[[VideoDetailHeaderView alloc] initWithFrame:CGRectMake(0,
                                                                                   kVideoTitleLabelHeight-10,
                                                                                   self.view.bounds.size.width,
                                                                                   30)] autorelease];
        self.headerView.video = self.video; 
        self.headerView.delegate = self;
        self.headerView.showsBookmarkButton = YES;
        
    }
    self.headerView.showsShareButton = YES;
    
    return self.headerView;
}

- (void)headerView:(VideoDetailHeaderView *)headerView shareButtonPressed:(id)sender
{
    _shareController.actionSheetTitle = NSLocalizedString(@"Share Video", nil);
    _shareController.shareTitle = video.title;
    //_shareController.shareBody = video.videoDescription;
    _shareController.shareURL = video.url;
    
    [_shareController shareInView:self.view];

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
