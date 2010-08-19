#import "StoryImageView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImageRep.h"
#import "NewsImage.h"

@implementation StoryImageView

@synthesize delegate, image, imageData, loadingView, imageView;

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        connection = nil;
        image = nil;
        imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setImage:(NewsImage *)newImage {
    if (![newImage isEqual:image]) {
        [image release];
        image = [newImage retain];
        imageView.image = nil;
        imageView.hidden = YES;
        if ([connection isConnected]) {
            [connection cancel];
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate hideNetworkActivityIndicator];
        }
        if (self.loadingView) {
            [self.loadingView stopAnimating];
            self.loadingView.hidden = YES;
        }
    }
}

- (void)loadImage {
    // show cached image if available
    if (image.data) {
        self.imageData = image.data;
        [self displayImage];
        // otherwise try to fetch the image from
    } else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    BOOL wasSuccessful = NO;
    
    UIImage *anImage = [[UIImage alloc] initWithData:self.imageData];
    
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
        [self addSubview:imageView];
        imageView.frame = self.bounds;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight);
    }
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;
    
    // don't show imageView if imageData isn't actually a valid image
    if (anImage) {
        imageView.image = anImage;
        imageView.hidden = NO;
        wasSuccessful = YES;
    }
    
    if ([self.delegate respondsToSelector:@selector(storyImageViewDidDisplayImage:)]) {
        [self.delegate storyImageViewDidDisplayImage:self];
    }
    
    [anImage release];
    return wasSuccessful;
}

- (void)layoutSubviews {
    imageView.frame = self.bounds;
    if (self.loadingView) {
        loadingView.center = CGPointMake(self.center.x - loadingView.frame.size.width / 2, self.center.y - loadingView.frame.size.height / 2);
    }
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection
    
    if ([[image.url pathExtension] length] == 0) {
        return;
    }
    
    if ([connection isConnected]) {
        return;
    }
    
    if (!connection) {
        connection = [[ConnectionWrapper alloc] initWithDelegate:self];
    }
    [connection requestDataFromURL:[NSURL URLWithString:image.url] allowCachedResponse:YES];
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.loadingView];
        loadingView.center = CGPointMake(self.center.x - loadingView.frame.size.width / 2, self.center.y - loadingView.frame.size.height / 2);
    }
    imageView.hidden = YES;
    loadingView.hidden = NO;
    [loadingView startAnimating];
}

// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    self.imageData = data;
    BOOL validImage = [self displayImage];
    if (validImage) {
        image.data = data;
        [CoreDataManager saveData];
    }
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

- (BOOL)connection:(ConnectionWrapper *)wrapper shouldDisplayAlertForError:(NSError *)error {
    return NO;
}

- (void)dealloc {
	[connection cancel];
    [connection release];
    connection = nil;
    [imageData release];
    imageData = nil;
    [loadingView release];
    [imageView release];
    [super dealloc];
}

@end
