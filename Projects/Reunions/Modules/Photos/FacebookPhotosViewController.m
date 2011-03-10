#import "FacebookPhotosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"

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
    
    [[KGOSocialMediaController sharedController] loginFacebookWithDelegate:self];
    
    _iconGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width - 10, self.view.bounds.size.height - 10)] autorelease];
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
        
        NSArray *data = [result objectForKey:@"data"];
        for (id aGroup in data) {
            if ([[aGroup objectForKey:@"name"] isEqualToString:@"H35th-1975"]) {
                _gid = [[aGroup objectForKey:@"id"] retain];
                
                NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", _gid];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
                _photosRequest = [[[KGOSocialMediaController sharedController] facebook] requestWithMethodName:@"fql.query"
                                                                                                     andParams:params
                                                                                                 andHttpMethod:@"GET"
                                                                                                   andDelegate:self];
            }
        }
        
        _groupsRequest = nil;
        
    } else if (request == _photosRequest) {
        _photosRequest = nil;
        
        if ([result isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *info in result) {
                NSString *pid = [info objectForKey:@"pid"];
                DLog(@"received photo id %@", pid);
                NSString *query = [NSString stringWithFormat:@"SELECT src_small, src_small_height, src_small_width, caption FROM photo WHERE pid=%@", pid];
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
        
        DLog(@"info for photo: %@", [result description]);
        if ([result isKindOfClass:[NSArray class]]) {
            NSDictionary *photoInfo = [result lastObject];
            NSString *caption = [photoInfo objectForKey:@"caption"];
            NSString *src = [photoInfo objectForKey:@"src_small"];
            CGFloat width = [[photoInfo objectForKey:@"src_small_width"] floatValue];
            CGFloat height = [[photoInfo objectForKey:@"src_small_height"] floatValue];
            
            UIView *wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height + 20)] autorelease];
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, height, width, 20)] autorelease];
            label.text = caption;
            [wrapperView addSubview:label];
            
            MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, width, height)] autorelease];
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
