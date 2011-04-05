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
static const CGFloat kVideoDescriptionLabelHeight = 64.0f;

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
    UIImage *image = 
    [UIImage imageWithData:
     [NSData dataWithContentsOfURL:[NSURL URLWithString:
                                    self.video.stillFrameImage]]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = kVideoDetailImageViewTag;
    CGRect imageViewFrame = imageView.frame;
    imageViewFrame.origin.x = kVideoDetailMargin;
    imageViewFrame.origin.y = kVideoDetailMargin * 2 + kVideoTitleLabelHeight;
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

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithVideo:(Video *)aVideo {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization.
        self.video = aVideo;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    NSAutoreleasePool *loadViewPool = [[NSAutoreleasePool alloc] init];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1000);
    scrollView.tag = kVideoDetailScrollViewTag;
    scrollView.scrollEnabled = YES;
    [self.view addSubview:scrollView];
    
    UILabel *titleLabel = 
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

    // TODO: When non-YouTube feeds are worked in, if they have streams
    // playable in MPMoviePlayerController, put an embedded player here conditionally.
    [self makeAndAddVideoImageViewToView:scrollView];
    
    UIView *videoImageView = [scrollView viewWithTag:kVideoDetailImageViewTag];
        
    UILabel *descriptionLabel = 
    [[UILabel alloc] initWithFrame:
     CGRectMake(kVideoDetailMargin, 
                kVideoDetailMargin * 3 + kVideoTitleLabelHeight 
                + videoImageView.frame.size.height,
                self.view.frame.size.width - 2 * kVideoDetailMargin, 
                kVideoDescriptionLabelHeight)];
    descriptionLabel.tag = kVideoDetailDescriptionTag;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    descriptionLabel.text = video.videoDescription;
    descriptionLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:descriptionLabel];

    [titleLabel release];
    [descriptionLabel release];
    [scrollView release];
    
    [loadViewPool release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
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
    [player release];
    [video release];
    [super dealloc];
}


@end
