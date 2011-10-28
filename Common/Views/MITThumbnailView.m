#import "MITThumbnailView.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"

@implementation MITThumbnailView

@synthesize imageURL, connection, loadingView, imageView, delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        connection = nil;
        imageURL = nil;
        _imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (NSData *)imageData
{
    return _imageData;
}

- (void)setImageData:(NSData *)imageData
{
    if (![_imageData isEqualToData:imageData]) {
        [_imageData release];
        _imageData = [imageData retain];
        _didDisplayImage = NO;
    }
}

- (void)loadImage {
    // show cached image if available
    if (self.imageData) {
        [self displayImage];
    }
    // otherwise try to fetch the image from
    else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    if (_didDisplayImage) {
        return _didDisplayImage;
    }
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;
    
    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    // don't show imageView if imageData isn't actually a valid image
    if (image && image.size.width > 0 && image.size.height > 0) {
        if (!imageView) {
            imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
            [self addSubview:imageView];
            imageView.frame = self.bounds;
            imageView.contentMode = self.contentMode;
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        }
        
        imageView.image = image;
        imageView.hidden = NO;
        _didDisplayImage = YES;
        [imageView setNeedsLayout];
    }
    [self setNeedsLayout];
    
    [image release];
    return _didDisplayImage;
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection
    
    if ([self.connection isConnected]) {
        return;
    }
    
    if (!self.connection) {
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    }
    if ([self.connection requestDataFromURL:[NSURL URLWithString:self.imageURL] allowCachedResponse:YES]) {    
        [KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
    }
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.loadingView];
        loadingView.center = self.center;
    }
    imageView.hidden = YES;
    loadingView.hidden = NO;
    [loadingView startAnimating];
}

- (void)setPlaceholderImage:(UIImage *)image {
    self.backgroundColor = [UIColor colorWithPatternImage:image];
}
     
// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    NSString *connectionURL = [connection.urlConnection.currentRequest.URL absoluteString];
    if ([connectionURL isEqualToString:self.imageURL]) {
        self.imageData = data;
        BOOL validImage = [self displayImage];
        if (validImage) {
            [self.delegate thumbnail:self didLoadData:data];
        }
    }
    
    self.connection = nil;
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    self.imageData = nil;
    [self displayImage]; // will fail to load the image, displays placeholder thumbnail instead
    self.connection = nil;
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

- (void)dealloc {
	[connection cancel];
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    [connection release];
    connection = nil;

    self.imageData = nil;
    [loadingView release];
    [imageView release];
    [imageURL release];
    self.delegate = nil;
    [super dealloc];
}

@end

