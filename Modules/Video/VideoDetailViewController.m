//
//  VideoDetailViewController.m
//  Universitas
//
//  Created by Jim Kang on 4/5/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "VideoDetailViewController.h"
#import "VideoWebViewController.h"
#import "UIKit+KGOAdditions.h"

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

- (void)launchWebViewWithVideo;

#pragma mark Tap actions
- (void)videoImageTapped:(UIGestureRecognizer *)recognizer;

#pragma mark Subview setup
- (void)makeAndAddVideoImageViewToView:(UIView *)parentView;


@end

@implementation VideoDetailViewController (Private)

- (void)launchWebViewWithVideo {
    VideoWebViewController *webViewController = 
    [[VideoWebViewController alloc] initWithURL:[NSURL URLWithString:self.video.url]];
    webViewController.navigationItem.title = self.video.title; 
    [self.navigationController pushViewController:webViewController animated:YES];
    [webViewController release];
}

#pragma mark Tap actions
- (void)videoImageTapped:(UIGestureRecognizer *)recognizer {
    [self launchWebViewWithVideo];
}

#pragma mark Subview setup
- (void)makeAndAddVideoImageViewToView:(UIView *)parentView
{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.video.stillFrameImageURLString]]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
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
    UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage];
    CGRect overlayFrame = overlayView.frame;
    overlayFrame.origin.x = 
    parentView.frame.size.width / 2 - overlayFrame.size.width / 2;
    overlayFrame.origin.y = 
    imageViewFrame.size.height / 2 - overlayFrame.size.height / 2;
    overlayView.frame = overlayFrame;
    [imageView addSubview:overlayView];
    
    [parentView addSubview:imageView];
    [imageView release];
    [overlayView release];
}
@end



@implementation VideoDetailViewController

@synthesize video;
@synthesize player;
@synthesize dataManager;
@synthesize section;
@synthesize scrollView;
@synthesize headerView = _headerView;

UILabel *titleLabel;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithVideo:(Video *)aVideo andSection:(NSString *)videoSection{
    
    self.dataManager = [[[VideoDataManager alloc] init] autorelease];
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization.
        self.video = aVideo;
        self.section = videoSection;
        
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    _shareController = [[KGOShareButtonController alloc] initWithContentsController:self];
    _shareController.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook | KGOShareControllerShareTypeTwitter;
    
    
    [self requestVideoForDetailView];
    
    NSAutoreleasePool *loadViewPool = [[NSAutoreleasePool alloc] init];
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    
    titleLabel = 
    [[UILabel alloc] initWithFrame:
     CGRectMake(kVideoDetailMargin, 
                0, 
                self.view.frame.size.width - 2 * kVideoDetailMargin, 
                kVideoTitleLabelHeight)];
    titleLabel.tag = kVideoDetailTitleLabelTag;
    titleLabel.numberOfLines = 0;
    titleLabel.font = [UIFont fontWithName:@"Georgia" size:22.0f];
    titleLabel.text = video.title;
    titleLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:titleLabel];
    
    //add sharing and bookmark buttons
    bookmarkSharingView = [self viewForTableHeader];
    [scrollView addSubview:bookmarkSharingView];
    
    // TODO: When non-YouTube feeds are worked in, if they have streams
    // playable in MPMoviePlayerController, put an embedded player here conditionally.
    [self makeAndAddVideoImageViewToView:scrollView];
    
    [titleLabel release];
    [loadViewPool release];
}

- (void)requestVideoForDetailView{
        [self.dataManager requestVideoForDetailSection:self.section andVideoID:(NSString *)self.video.videoID 
                                      thenRunBlock:^(id result) { 
                                          if ([result isKindOfClass:[NSArray class]]) {                                              
                                              NSArray *videoArray = result; 
                                              Video *temp = [videoArray objectAtIndex:0];
                                              self.video.videoDescription = temp.videoDescription; 
                                              [self setDescription];
                                          }
                                      }];
}

- (void) setDescription{
    CGSize descriptionSize = [video.videoDescription sizeWithFont:[UIFont systemFontOfSize:15.0f] constrainedToSize:CGSizeMake(300.0f, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    
    UIView *videoImageView = [scrollView viewWithTag:kVideoDetailImageViewTag];
    UILabel *descriptionLabel = 
    [[UILabel alloc] initWithFrame:
     CGRectMake(kVideoDetailMargin, 
                kVideoDetailMargin * 3 + kVideoTitleLabelHeight 
             + videoImageView.frame.size.height + bookmarkSharingView.frame.size.height,
                self.view.frame.size.width - 2 * kVideoDetailMargin, 
                descriptionSize.height)];
    descriptionLabel.tag = kVideoDetailDescriptionTag;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.text = video.videoDescription;
    descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    descriptionLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:descriptionLabel];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, (titleLabel.frame.size.height + videoImageView.frame.size.height + descriptionSize.height + extraScrollViewHeight));
    scrollView.tag = kVideoDetailScrollViewTag;
    scrollView.scrollEnabled = YES;
    [self.view addSubview:scrollView];
    
    [descriptionLabel release];
    [scrollView release];
}

- (UIView *)viewForTableHeader
{
    if (!self.headerView) {
        self.headerView = [[[KGODetailPageHeaderView alloc] initWithFrame:CGRectMake(0, kVideoTitleLabelHeight-10, self.view.bounds.size.width, 30)] autorelease];
        self.headerView.delegate = self;
        self.headerView.showsBookmarkButton = YES;
        
    }
    self.headerView.showsShareButton = YES;
    self.headerView.showsCalendarButton = NO;
    
    return self.headerView;
}

- (void)headerView:(KGODetailPageHeaderView *)headerVw shareButtonPressed:(id)sender
{
    _shareController.actionSheetTitle = @"Share this event";
    _shareController.shareTitle = video.title;
    //_shareController.shareBody = video.videoDescription;
       _shareController.shareURL = video.url;
    
    [_shareController shareInView:self.view];

}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {  
    self.navigationItem.title = @"View Video"; 
    
    [super viewDidLoad];
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
    [super dealloc];
}


@end
