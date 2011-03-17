#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookVideo.h"
#import "FacebookUser.h"
#import "FacebookModule.h"

@implementation FacebookVideosViewController

- (void)getGroupVideos {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookGroupReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookFeedDidUpdateNotification object:nil];
    
    FacebookModule *fbModule = (FacebookModule *)[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] moduleForTag:@"facebook"];
    if (fbModule.groupID) {
        if (fbModule.latestFeedPosts) {
            for (NSDictionary *aPost in fbModule.latestFeedPosts) {
                NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
                if ([type isEqualToString:@"video"]) {
                    NSLog(@"video data: %@", [aPost description]);
                    FacebookVideo *aVideo = [FacebookVideo videoWithDictionary:aPost];
                    if (aVideo && ![_videoIDs containsObject:aVideo.identifier]) {
                        NSLog(@"created video %@", [aVideo description]);
                        [_videos addObject:aVideo];
                        [_videoIDs addObject:aVideo.identifier];
                    }
                }
            }
            [_tableView reloadData];
            
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getGroupVideos)
                                                         name:FacebookGroupReceivedNotification
                                                       object:nil];
        }
        
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getGroupVideos)
                                                     name:FacebookFeedDidUpdateNotification
                                                   object:nil];
    }
}

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
    
    self.title = @"Videos";
    
    CGRect frame = _scrollView.frame;
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _tableView.tableHeaderView = _signedInUserView;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 72;
    [self.view insertSubview:_tableView aboveSubview:_scrollView];
    [_scrollView removeFromSuperview];
    
    _videos = [[NSMutableArray alloc] init];
    _videoIDs = [[NSMutableSet alloc] init];
    
    [self getGroupVideos];
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
    [super dealloc];
}

#pragma mark Facebook callbacks
/*
- (void)didReceiveFeed:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    for (NSDictionary *aPost in data) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"video"]) {
            NSLog(@"video data: %@", [aPost description]);
            FacebookVideo *aVideo = [FacebookVideo videoWithDictionary:aPost];
            if (aVideo && ![_videoIDs containsObject:aVideo.identifier]) {
                NSLog(@"created video %@", [aVideo description]);
                [_videos addObject:aVideo];
                [_videoIDs addObject:aVideo.identifier];
            }
        }
    }
    [_tableView reloadData];
}
*/
#pragma mark table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FacebookVideo *aVideo = [_videos objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger thumbnailTag = 80;
    NSInteger titleTag = 81;
    NSInteger subtitleTag = 82;
    
    MITThumbnailView *thumbnail = (MITThumbnailView *)[cell.contentView viewWithTag:thumbnailTag];
    if (!thumbnail) {
        thumbnail = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(1, 1, 70, 70)] autorelease];
        thumbnail.tag = thumbnailTag;
    }
    thumbnail.imageURL = aVideo.thumbSrc;
    [thumbnail loadImage];
    [cell.contentView addSubview:thumbnail];
    
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:titleTag];
    if (!titleLabel) {
        UIFont *titleFont = [UIFont systemFontOfSize:13];
        titleLabel = [UILabel multilineLabelWithText:aVideo.name
                                                font:titleFont
                                               width:tableView.frame.size.width - 80];
        CGRect frame = titleLabel.frame;
        frame.origin.x = 80;
        frame.origin.y = 10;
        titleLabel.frame = frame;
    } else {
        titleLabel.text = aVideo.name;
    }
    [cell.contentView addSubview:titleLabel];
    
    UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:subtitleTag];
    if (!subtitleLabel) {
        UIFont *titleFont = [UIFont systemFontOfSize:13];
        titleLabel = [UILabel multilineLabelWithText:aVideo.owner.name
                                                font:titleFont
                                               width:tableView.frame.size.width - 80];
        CGRect frame = subtitleLabel.frame;
        frame.origin.x = 80;
        frame.origin.y = 40;
        subtitleLabel.frame = frame;
    } else {
        subtitleLabel.text = aVideo.owner.name;
    }
    [cell.contentView addSubview:subtitleLabel];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacebookVideo *aVideo = [_videos objectAtIndex:indexPath.row];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_videos, @"videos", aVideo, @"video", nil];
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:VideoTag params:params];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
