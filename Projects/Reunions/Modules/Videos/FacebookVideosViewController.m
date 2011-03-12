#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"

@interface ControlWithURL : UIControl

@property (nonatomic, retain) NSString *url;

@end

@implementation ControlWithURL

@synthesize url;

@end




@implementation FacebookVideosViewController

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

- (void)loadView {
	[super loadView];
    
    [[KGOSocialMediaController sharedController] loginFacebookWithDelegate:self];
    
    _iconGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width - 10, self.view.bounds.size.height - 10)] autorelease];
    _iconGrid.spacing = GridSpacingMake(10, 10);
    _iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:_iconGrid];
    
    _icons = [[NSMutableArray alloc] init];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

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
    if (_groupsRequest) {
        _groupsRequest.delegate = nil;
    }
    if (_videosRequest) {
        _videosRequest.delegate = nil;
    }
    if (_fbRequestQueue) {
        for (FBRequest *aRequest in _fbRequestQueue) {
            aRequest.delegate = nil;
        }
    }
    [_fbRequestQueue release];
    [_gid release];
    [super dealloc];
}

- (UIView *)thumbnailWithSource:(NSString *)src caption:(NSString *)caption link:(NSString *)link {
    
    ControlWithURL *wrapperView = [[[ControlWithURL alloc] initWithFrame:CGRectMake(0, 0, 90, 130)] autorelease];
    wrapperView.url = link;
    
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 90, 90, 40)] autorelease];
    label.text = caption;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 3;
    label.font = [UIFont systemFontOfSize:10];
    [wrapperView addSubview:label];
    
    MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)] autorelease];
    thumbView.userInteractionEnabled = NO;
    thumbView.imageURL = src;
    [thumbView loadImage];

    [wrapperView addTarget:self action:@selector(openVideo:) forControlEvents:UIControlEventTouchUpInside];
    [wrapperView addSubview:thumbView];
    
    return wrapperView;
}

- (void)openVideo:(id)sender {
    if ([sender isKindOfClass:[ControlWithURL class]]) {
        NSString *urlString = [(ControlWithURL *)sender url];
        NSURL *url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark FacebookWrapperDelegate

- (void)facebookDidLogin {
    _fbRequestQueue = [[NSMutableArray alloc] init];
    
    _groupsRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:@"me/groups" andDelegate:self];
    //[_fbRequestQueue addObject:request];
    
    _videoIDs = [[NSMutableSet alloc] init];
}


- (void)facebookFailedToLogin {
    
}


- (void)facebookDidLogout {
    
}

#pragma mark FBRequestDelegate

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@", [error description]);
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    NSLog(@"%@", [request.url description]);
    NSLog(@"%@", [request.params description]);
    NSLog(@"%@", [result description]);
    
    //NSSet *groupNames = [NSSet setWithObjects:@"H10th-2001", @"H35th-1975", @"H50th-1960", @"H25th-1985", nil];
    NSSet *groupNames = [NSSet setWithObjects:@"H10th-2001", nil];
    
    if (request == _groupsRequest) {
        
        NSArray *data = [result objectForKey:@"data"];
        for (id aGroup in data) {
            if ([groupNames containsObject:[aGroup objectForKey:@"name"]]) {
                _gid = [[aGroup objectForKey:@"id"] retain];
                NSLog(@"%@", _gid);
                
                NSString *query = [NSString stringWithFormat:@"SELECT vid FROM video_tag WHERE subject=%@", _gid];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
                _videosRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithMethodName:@"fql.query"
                                                                                                     andParams:params
                                                                                                 andHttpMethod:@"GET"
                                                                                                   andDelegate:self];
                
                NSString *feedPath = [NSString stringWithFormat:@"%@/feed", _gid];
                params = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"25", @"limit", nil];
                _feedRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:feedPath
                                                                                                  andParams:params
                                                                                                andDelegate:self];
            }
        }
        
        _groupsRequest = nil;
        
    } else if (request == _feedRequest) {
        _feedRequest = nil;
        
        NSArray *data = [result arrayForKey:@"data"];
        for (NSDictionary *aPost in data) {
            NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
            if ([type isEqualToString:@"video"]) {
                NSString *vid = [aPost stringForKey:@"id" nilIfEmpty:YES];
                if (vid && ![_videoIDs containsObject:vid]) {
                    [_videoIDs addObject:vid];
                    DLog(@"requesting graph info for video %@", vid);
                    FBRequest *aRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:vid
                                                                                                           andDelegate:self];
                    [_fbRequestQueue addObject:aRequest];
                }
                NSString *thumb = [aPost stringForKey:@"picture" nilIfEmpty:YES];
                NSString *name = [aPost stringForKey:@"name" nilIfEmpty:YES];
                NSString *link = [aPost stringForKey:@"source" nilIfEmpty:YES];
                if (thumb) {
                    [_icons addObject:[self thumbnailWithSource:thumb caption:name link:link]];
                    _iconGrid.icons = _icons;
                    [_iconGrid setNeedsLayout];
                }
            }
        }
        
    } else if (request == _videosRequest) {
        _videosRequest = nil;

        if ([result isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *info in result) {
                NSString *vid = [info objectForKey:@"vid"];
                DLog(@"received video id %@", vid);
                NSString *query = [NSString stringWithFormat:@"SELECT title, description, thumbnail_link, src FROM video WHERE vid=%@", vid];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
                FBRequest *aRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithMethodName:@"fql.query"
                                                                                                          andParams:params
                                                                                                      andHttpMethod:@"GET"
                                                                                                        andDelegate:self];
                [_fbRequestQueue addObject:aRequest];
            }
        }
        
    } else { // individual photos
        [_fbRequestQueue removeObject:request];
        
        DLog(@"info for video: %@", [result description]);
        if ([result isKindOfClass:[NSDictionary class]]) {
            
            
        } else if ([result isKindOfClass:[NSArray class]]) {
            NSDictionary *photoInfo = [result lastObject];
            NSString *title = [photoInfo objectForKey:@"title"];
            NSString *thumb = [photoInfo objectForKey:@"thumbnail_link"];
            NSString *link = [photoInfo objectForKey:@"src"];
            
            [_icons addObject:[self thumbnailWithSource:thumb caption:title link:link]];
            _iconGrid.icons = _icons;
            [_iconGrid setNeedsLayout];
        }
    }
}

@end
