#import "FacebookPhotosViewController.h"
#import "IconGrid.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation FacebookPhotosViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photoIDs = [[NSMutableSet alloc] init];

    CGRect frame = _scrollView.frame;
    frame.origin.y += _signedInUserView.frame.size.height;
    frame.size.height -= _signedInUserView.frame.size.height;
    _iconGrid = [[IconGrid alloc] initWithFrame:frame];
    _iconGrid.spacing = GridSpacingMake(10, 10);
    _iconGrid.padding = GridPaddingMake(10, 10, 10, 10);
    _iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _iconGrid.backgroundColor = [UIColor clearColor];
    
    [_scrollView addSubview:_iconGrid];
    
    _icons = [[NSMutableArray alloc] init];
    _photosByThumbSrc = [[NSMutableDictionary alloc] init];
    
    [self loadThumbnailsFromCache];
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
    [[KGOSocialMediaController sharedController] disconnectFacebookRequests:self];

    [_gid release];
    [_iconGrid release];
    [_icons release];
    [_photosByThumbSrc release];
    [_photoIDs release];
    [super dealloc];
}

#pragma mark When we already have photos

- (void)loadThumbnailsFromCache {
    // TODO: sort by date or whatever
    NSArray *photos = [[CoreDataManager sharedManager] objectsForEntity:FacebookPhotoEntityName matchingPredicate:nil];
    for (FacebookPhoto *aPhoto in photos) {
        [_photoIDs addObject:aPhoto.identifier];
        NSLog(@"found cached photo %@", aPhoto.identifier);
        [self displayPhoto:aPhoto];
    }
}

- (void)displayPhoto:(FacebookPhoto *)photo
{
    if (photo.thumbSrc || photo.thumbData) {
        FacebookThumbnail *thumbnail = [[[FacebookThumbnail alloc] initWithFrame:CGRectMake(0, 0, 90, 130)] autorelease];
        thumbnail.photo = photo;
        thumbnail.rotationAngle = (_icons.count % 2 == 0) ? 0.3 : -0.3;
        [thumbnail addTarget:self action:@selector(thumbnailTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_icons addObject:thumbnail];
        _iconGrid.icons = _icons;
        [_iconGrid setNeedsLayout];
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    FacebookPhoto *photo = [_photosByThumbSrc objectForKey:thumbnail.imageURL];
    if (photo) {
        photo.thumbData = data;
    }
    [[CoreDataManager sharedManager] saveData];
}

- (void)thumbnailTapped:(FacebookThumbnail *)sender {
    FacebookPhoto *photo = sender.photo;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:photo, @"photo", nil];
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:FBPhotosTag params:params];
}

#pragma mark Facebook request callbacks

- (void)didReceiveGroups:(id)result {
    
    NSArray *data = [result arrayForKey:@"data"];
    for (id aGroup in data) {
        if ([[aGroup objectForKey:@"name"] isEqualToString:@"Modo Labs UX"]) {
            _gid = [[aGroup objectForKey:@"id"] retain];

            // fql for photos
            NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", _gid];
            [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotoList:)];

            // grou feed
            NSString *feedPath = [NSString stringWithFormat:@"%@/feed", _gid];
            [[KGOSocialMediaController sharedController] requestFacebookGraphPath:feedPath receiver:self callback:@selector(didReceiveFeed:)];
        }
    }

}

- (void)didReceivePhotoList:(id)result {
    
    if ([result isKindOfClass:[NSArray class]]) {
        
        for (NSDictionary *info in result) {
            NSString *pid = [info objectForKey:@"pid"];
            if (pid && ![_photoIDs containsObject:pid]) {
                DLog(@"received fql info for photo %@", pid);
                NSString *query = [NSString stringWithFormat:@"SELECT object_id, "
                                   "src_small, src_small_width, src_small_height, "
                                   "src, src_width, src_height, "
                                   "owner, caption, created "
                                   "FROM photo WHERE pid=%@", pid];
                
                [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhoto:)];
            }
        }
    }
}

- (void)didReceivePhoto:(id)result {
    DLog(@"info for photo: %@", [result description]);
    
    NSDictionary *photoInfo = nil;
    
    // TODO: check these requests against their origin rather than just checking type
    if ([result isKindOfClass:[NSDictionary class]]) {
        photoInfo = (NSDictionary *)result;
        
    } else if ([result isKindOfClass:[NSArray class]]) {
        // request came from fql
        photoInfo = [result lastObject];
    }
    
    FacebookPhoto *photo = [FacebookPhoto photoWithDictionary:photoInfo];
    NSLog(@"created photo %@ thumbnail: %@", [photo description], photo.thumbSrc);
    if (photo) {
        NSLog(@"displaying photo %@", [photo description]);
        [self displayPhoto:photo];
    }
}

- (void)didReceiveFeed:(id)result {
    
    NSArray *data = [result arrayForKey:@"data"];
    for (NSDictionary *aPost in data) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"photo"]) {
            NSString *pid = [aPost stringForKey:@"object_id" nilIfEmpty:YES];
            if (pid && ![_photoIDs containsObject:pid]) {
                [_photoIDs addObject:pid];
                DLog(@"requesting graph info for photo %@", pid);
                FBRequest *aRequest = [[KGOSocialMediaController sharedController] requestFacebookGraphPath:pid receiver:self callback:@selector(didReceivePhotos)];
                [_fbRequestQueue addObject:aRequest];
            }
        }
    }
}

@end

@implementation FacebookThumbnail

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 90, 40)];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor whiteColor];
        _label.numberOfLines = 3;
        _label.font = [UIFont systemFontOfSize:10];
        _label.userInteractionEnabled = NO;
        
        _thumbnail = [[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnail.userInteractionEnabled = NO;

        [self addSubview:_label];
        [self addSubview:_thumbnail];
    }
    return self;
}

- (FacebookPhoto *)photo {
    return _photo;
}

- (void)setPhoto:(FacebookPhoto *)photo {
    _label.text = photo.title;
    if (photo.thumbData) {
        _thumbnail.imageData = photo.thumbData;
    } else if (photo.thumbSrc) {
        _thumbnail.imageURL = photo.thumbSrc;
    }
    [_thumbnail loadImage];
}

- (CGFloat)rotationAngle {
    return _rotationAngle;
}

- (void)setRotationAngle:(CGFloat)rotationAngle {
    _rotationAngle = rotationAngle;
    _thumbnail.transform = CGAffineTransformMakeRotation(rotationAngle);
}

@end
