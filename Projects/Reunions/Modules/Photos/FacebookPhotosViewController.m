#import "FacebookPhotosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>

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
    [super dealloc];
}

#pragma mark Facebook request callbacks

- (void)didReceiveGroups:(id)result {
    
    NSArray *data = [result arrayForKey:@"data"];
    for (id aGroup in data) {
        if ([[aGroup objectForKey:@"name"] isEqualToString:@"Modo Labs UX"]) {
            _gid = [[aGroup objectForKey:@"id"] retain];
            
            NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", _gid];
            
            _photosRequest = [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotoList:)];
            
            NSString *feedPath = [NSString stringWithFormat:@"%@/feed", _gid];
            _feedRequest = [[KGOSocialMediaController sharedController] requestFacebookGraphPath:feedPath receiver:self callback:@selector(didReceiveFeed:)];
        }
    }

}

- (void)didReceivePhotoList:(id)result {
    
    if ([result isKindOfClass:[NSArray class]]) {
        
        for (NSDictionary *info in result) {
            NSString *pid = [info objectForKey:@"pid"];
            if (pid && ![_photoIDs containsObject:pid]) {
                DLog(@"received fql info for photo %@", pid);
                //NSString *query = [NSString stringWithFormat:@"SELECT src_small, src_small_height, src_small_width, caption FROM photo WHERE pid=%@", pid];
                NSString *query = [NSString stringWithFormat:@"SELECT object_id, "
                                   "src_small, src_small_width, src_small_height, "
                                   "src, src_width, src_height, "
                                   "owner, caption, created "
                                   "FROM photo WHERE pid=%@", pid];
                
                [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotos:)];
            }
        }
    }
}

- (void)didReceivePhotos:(id)result {
    
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
    if (photo.thumbSrc) {
        
        UIView *wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 130)] autorelease];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 90, 90, 40)] autorelease];
        label.text = photo.title;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 3;
        label.font = [UIFont systemFontOfSize:10];
        [wrapperView addSubview:label];
        
        MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)] autorelease];
        thumbView.imageURL = photo.thumbSrc;
        [thumbView loadImage];
        
        [wrapperView addSubview:thumbView];
        
        CGFloat rotationAngle = 0.3 - 0.6 * (_icons.count % 2);
        wrapperView.transform = CGAffineTransformMakeRotation(rotationAngle);
        
        [_icons addObject:wrapperView];
        _iconGrid.icons = _icons;
        [_iconGrid setNeedsLayout];
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
