#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = _scrollView.frame;
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _tableView.tableHeaderView = _signedInUserView;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view insertSubview:_tableView aboveSubview:_scrollView];
    [_scrollView removeFromSuperview];
    
    _videos = [[NSMutableArray alloc] init];
    _videoIDs = [[NSMutableSet alloc] init];
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
    [_tableView release];
    [_videos release];
    [_videoIDs release];
    [_gid release];
    [super dealloc];
}

#pragma mark FacebookWrapperDelegate

- (void)didReceiveFeed:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    for (NSDictionary *aPost in data) {
        NSLog(@"%@", [aPost description]);
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"video"]) {
            [_videos addObject:aPost];
        }
    }
}

#pragma mark table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *videoData = [_videos objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger thumbnailTag = 80;
    NSInteger titleTag = 81;
    //NSInteger subtitleTag = 82;
    
    MITThumbnailView *thumbnail = (MITThumbnailView *)[cell.contentView viewWithTag:thumbnailTag];
    if (!thumbnail) {
        thumbnail = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 100, 75)] autorelease];
        thumbnail.tag = thumbnailTag;
    }
    thumbnail.imageURL = [videoData stringForKey:@"picture" nilIfEmpty:YES];
    [thumbnail loadImage];
    [cell.contentView addSubview:thumbnail];
    
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:titleTag];
    if (!titleLabel) {
        UIFont *titleFont = [UIFont systemFontOfSize:13];
        titleLabel = [UILabel multilineLabelWithText:[videoData stringForKey:@"name" nilIfEmpty:YES]
                                                font:titleFont
                                               width:tableView.frame.size.width - 110];
        CGRect frame = titleLabel.frame;
        frame.origin.x = 115;
        frame.origin.y = 10;
        titleLabel.frame = frame;
    } else {
        titleLabel.text = [videoData stringForKey:@"name" nilIfEmpty:YES];
    }
    [cell.contentView addSubview:titleLabel];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

/*
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
*/
@end
