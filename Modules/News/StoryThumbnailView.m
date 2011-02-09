#import "StoryThumbnailView.h"
#import "KGOAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImage.h"

@interface StoryThumbnailView (Private)

- (UIImage *)placeholderImage;

@end


@implementation StoryThumbnailView

@synthesize image, connection, imageData, loadingView, imageView, placeholderImageName;

- (UIImage *)placeholderImage {
    if (!self.placeholderImageName) {
        return [UIImage imageNamed:@"news/news-placeholder.png"];
    } else {
        return [UIImage imageNamed:self.placeholderImageName];
    }
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        connection = nil;
        image = nil;
        imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.placeholderImageName = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithPatternImage:[self placeholderImage]];
    }
    return self;
}

- (void)setImage:(NewsImage *)newImage {
    if (![newImage isEqual:image]) {
        [image release];
        image = [newImage retain];
        imageView.image = nil;
        imageView.hidden = YES;
        if ([self.connection isConnected]) {
            [self.connection cancel];
            KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate hideNetworkActivityIndicator];
        }
        if (self.loadingView) {
            [self.loadingView stopAnimating];
            self.loadingView.hidden = YES;
        }
        if (image) {
            self.backgroundColor = [UIColor colorWithWhite:0.60 alpha:1.0];
        } else {
            self.backgroundColor = [UIColor colorWithPatternImage:[self placeholderImage]];
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
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;

    UIImage *anImage = [[UIImage alloc] initWithData:self.imageData];
    
    // don't show imageView if imageData isn't actually a valid image
    if (anImage && anImage.size.width > 0 && anImage.size.height > 0) {
        if (!imageView) {
            imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
            [self addSubview:imageView];
            imageView.frame = self.bounds;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight);
        }

        imageView.image = anImage;
        imageView.hidden = NO;
        wasSuccessful = YES;
        [imageView setNeedsLayout];
    } else {
        self.backgroundColor = [UIColor colorWithPatternImage:[self placeholderImage]];
    }
    [self setNeedsLayout];
    
    [anImage release];
    return wasSuccessful;
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection

    // temporary fix to prevent loading of directories as images
    // need news office to improve feed
    // 
    // in the future, should spin off thumbnail as its own Core Data entity with an "not a valid image" flag
    if ([[image.url pathExtension] length] == 0) {
        self.backgroundColor = [UIColor colorWithPatternImage:[self placeholderImage]];
        return;
    }
    
    if ([self.connection isConnected]) {
        return;
    }
    
    if (!self.connection) {
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    }
    [self.connection requestDataFromURL:[NSURL URLWithString:image.url] allowCachedResponse:YES];

    KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];

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

// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    self.imageData = data;
    BOOL validImage = [self displayImage];
    if (validImage) {
        image.data = data;
        [[CoreDataManager sharedManager] saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }

    self.connection = nil;
    
    KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

- (BOOL)connection:(ConnectionWrapper *)wrapper shouldDisplayAlertForError:(NSError *)error {
    return NO;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    self.imageData = nil;
    [self displayImage]; // will fail to load the image, displays placeholder thumbnail instead
    self.connection = nil;
}

- (void)dealloc {
	[connection cancel];
    [connection release];
    connection = nil;
    [imageData release];
    imageData = nil;
    [loadingView release];
    [imageView release];
    self.placeholderImageName = nil;
    [super dealloc];
}

@end
