#import "FacebookPhotosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"

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

- (void)loadView {
	[super loadView];
    
    _photoIDs = [[NSMutableSet alloc] init];
    
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
    if (_photosRequest) {
        _photosRequest.delegate = nil;
    }
    if (_feedRequest) {
        _feedRequest.delegate = nil;
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

#pragma mark FacebookWrapperDelegate

- (void)facebookDidLogin {
    _fbRequestQueue = [[NSMutableArray alloc] init];
    
    _groupsRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:@"me/groups" andDelegate:self];
    //[_fbRequestQueue addObject:request];
}


- (void)facebookFailedToLogin {
    
}


- (void)facebookDidLogout {
    
}

#pragma mark FBRequestDelegate

- (void)request:(FBRequest *)request didLoad:(id)result {
    NSLog(@"%@", [request.url description]);
    NSLog(@"%@", [request.params description]);
    NSLog(@"%@", [result description]);
    if (request == _groupsRequest) {
        
        NSArray *data = [result arrayForKey:@"data"];
        for (id aGroup in data) {
            if ([[aGroup objectForKey:@"name"] isEqualToString:@"Modo Labs UX"]) {
                _gid = [[aGroup objectForKey:@"id"] retain];
                
                NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", _gid];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
                _photosRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithMethodName:@"fql.query"
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
            if ([type isEqualToString:@"photo"]) {
                NSString *pid = [aPost stringForKey:@"object_id" nilIfEmpty:YES];
                if (pid && ![_photoIDs containsObject:pid]) {
                    [_photoIDs addObject:pid];
                    DLog(@"requesting graph info for photo %@", pid);
                    FBRequest *aRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithGraphPath:pid
                                                                                                           andDelegate:self];
                    [_fbRequestQueue addObject:aRequest];
                }
            }
        }
        
    } else if (request == _photosRequest) {
        _photosRequest = nil;
        
        if ([result isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *info in result) {
                NSString *pid = [info objectForKey:@"pid"];
                if (pid && ![_photoIDs containsObject:pid]) {
                    DLog(@"received fql info for photo %@", pid);
                    NSString *query = [NSString stringWithFormat:@"SELECT src_small, src_small_height, src_small_width, caption FROM photo WHERE pid=%@", pid];
                    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
                    FBRequest *aRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithMethodName:@"fql.query"
                                                                                                              andParams:params
                                                                                                          andHttpMethod:@"GET"
                                                                                                            andDelegate:self];
                    [_fbRequestQueue addObject:aRequest];
                }
            }
        }
        
    } else { // individual photos
        [_fbRequestQueue removeObject:request];
        
        DLog(@"info for photo: %@", [result description]);
        NSString *src = nil;
        NSString *caption = nil;
        CGFloat width = 0;
        CGFloat height = 0;
        // TODO: check these requests against their origin rather than just checking type
        if ([result isKindOfClass:[NSDictionary class]]) {
            // request came from graph api
            src = [result stringForKey:@"source" nilIfEmpty:YES];
            caption = [result stringForKey:@"name" nilIfEmpty:YES];
            width = [result floatForKey:@"width"];
            height = [result floatForKey:@"height"];
            
        } else if ([result isKindOfClass:[NSArray class]]) {
            // request came from fql
            NSDictionary *photoInfo = [result lastObject];
            src = [photoInfo objectForKey:@"src_small"];
            width = [[photoInfo objectForKey:@"src_small_width"] floatValue];
            height = [[photoInfo objectForKey:@"src_small_height"] floatValue];
            caption = [photoInfo objectForKey:@"caption"];
        }

        if (src) {
            if (width > 90) {
                height = floor(height * 90 / width);
                width = 90;
            }
            if (height > 90) {
                width = floor(width * 90 / height);
                height = 90;
            }
            
            UIView *wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 130)] autorelease];
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 90, 90, 40)] autorelease];
            label.text = caption;
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor whiteColor];
            label.numberOfLines = 3;
            label.font = [UIFont systemFontOfSize:10];
            [wrapperView addSubview:label];
            
            MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(floor((90 - width) / 2),
                                                                                              floor((90 - height) / 2),
                                                                                              width,
                                                                                              height)] autorelease];
            thumbView.imageURL = src;
            [thumbView loadImage];
            
            [wrapperView addSubview:thumbView];
            
            [_icons addObject:wrapperView];
            _iconGrid.icons = _icons;
            [_iconGrid setNeedsLayout];
        }
    }
}

@end
