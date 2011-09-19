//
//  VideoListViewController.m
//  Universitas
//

#import "VideoListViewController.h"
#import "Constants.h"
#import "VideoDetailViewController.h"
#import "CoreDataManager.h"
#import "VideoModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"

static const NSInteger kVideoListCellThumbnailTag = 0x78;

#pragma mark Private methods

@interface VideoListViewController (Private)

+ (NSString *)detailTextForVideo:(Video *)video;
- (void)updateThumbnailView:(MITThumbnailView *)thumbnailView 
                   forVideo:(Video *)video;
- (void)requestVideosForActiveSection;
- (void)removeAllThumbnailViews;

/*
#pragma mark Search UI
- (void)showSearchBar;
- (void)hideSearchBar; 
*/
@end

@implementation VideoListViewController (Private)

// TODO: this entire category could be done by subclassing the table view cells and removing
// unnecessary logic from this class (see MITThumbmailView delegation below)

+ (NSString *)detailTextForVideo:(Video *)video {
    return [NSString stringWithFormat:@"(%@) %@", [video durationString], video.videoDescription];
}

- (void)updateThumbnailView:(MITThumbnailView *)thumbnailView 
                   forVideo:(Video *)video {
    // Does this thumbnail view have the correct image loaded?
    if (![thumbnailView.imageURL isEqualToString:video.thumbnailURLString]) {
        // Update URL.
        thumbnailView.imageURL = video.thumbnailURLString;
        thumbnailView.imageData = nil;
    }
    // Load the image data if necessary.
    if (!(thumbnailView.imageData)) {
        if (video.thumbnailImageData) {
            thumbnailView.imageData = video.thumbnailImageData;
        }
        [thumbnailView loadImage];
    }
    [thumbnailView displayImage];
}

- (void)requestVideosForActiveSection { 
    if (self.videoSections.count > self.activeSectionIndex) {
        NSString *section = [[self.videoSections objectAtIndex:self.activeSectionIndex] objectForKey:@"value"];
        __block VideoListViewController *blockSelf = self;
        [self.dataManager requestVideosForSection:section
                                     thenRunBlock:^(id result) { 
             if ([result isKindOfClass:[NSArray class]]) {
                 blockSelf.videos = result;
                 [blockSelf.tableView reloadData];
             }
         }];
    }
}



- (void)removeAllThumbnailViews {
    NSInteger sections = [self.tableView numberOfSections];
    for (NSInteger section = 0; section < sections; ++section) {
        NSInteger rows = [self.tableView numberOfRowsInSection:section];
        for (NSInteger row = 0; row < rows; ++row) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            UIView *thumbnailView = [cell.contentView viewWithTag:kVideoListCellThumbnailTag];
            [thumbnailView removeFromSuperview];
        }
    }
}

@end


@implementation VideoListViewController

@synthesize dataManager;
@synthesize navScrollView;
@synthesize videos;
@synthesize videoSections;
@synthesize activeSectionIndex;
@synthesize theSearchBar;

#pragma mark NSObject

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
	if (self) {
        self.activeSectionIndex = 0;
	}
	return self;
}

- (void)dealloc {
    // Need to do this so that they don't live on and try to call this object, 
    // which is set as their delegate.
    [self removeAllThumbnailViews];
    
    //[searchController release];
    [theSearchBar release];
    [videoSections release];
    [videos release];
    [navScrollView release];
    [dataManager release];
    [super dealloc];
}

#pragma mark UIViewController

- (void)loadView {
    [super loadView];
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
    self.navScrollView = [[[KGOScrollingTabstrip alloc] initWithFrame:frame] autorelease];
    self.navScrollView.showsSearchButton = YES;
    self.navScrollView.delegate = self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 90.0f;
    
    __block VideoListViewController *blockSelf = self;
    [self.dataManager requestSectionsThenRunBlock:^(id result) {
        blockSelf.videoSections = (NSArray *)result;
        for (NSDictionary *sectionInfo in blockSelf.videoSections) {
            [blockSelf.navScrollView addButtonWithTitle:[sectionInfo objectForKey:@"title"]];
        }
        [blockSelf.navScrollView selectButtonAtIndex:blockSelf.activeSectionIndex];
        [blockSelf.navScrollView setNeedsLayout];
        [blockSelf requestVideosForActiveSection];
     }];
    self.navigationItem.title = [[KGO_SHARED_APP_DELEGATE() moduleForTag:self.dataManager.moduleTag] shortName];
}

- (void)viewWillAppear:(BOOL)animated {
    BOOL bookmarksExist = [self.dataManager bookmarkedVideos].count > 0;
    if(bookmarksExist){
        [self.navScrollView setShowsBookmarkButton:YES]; 
    }
    else 
        [self.navScrollView setShowsBookmarkButton:NO]; 
    
    
    [self.navScrollView setNeedsLayout];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Save whatever thumbnail data we've downloaded.
    [[CoreDataManager sharedManager] saveData];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.videos.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                       reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        cell.detailTextLabel.numberOfLines = 2;
        cell.indentationLevel = 1;
        cell.indentationWidth = 120;
        
        MITThumbnailView *thumbnailView = [[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 120, 90)];
        thumbnailView.tag = kVideoListCellThumbnailTag;
        thumbnailView.delegate = self;
        [cell.contentView addSubview:thumbnailView];
        [thumbnailView release];
    }
    
    // Configure the cell...
    if (self.videos.count > indexPath.row) {
        NSAutoreleasePool *cellConfigPool = [[NSAutoreleasePool alloc] init];
        
        Video *video = [self.videos objectAtIndex:indexPath.row];
        cell.textLabel.text = video.title;
        cell.detailTextLabel.text = [[self class] detailTextForVideo:video];
                
        MITThumbnailView *thumbnailView = (MITThumbnailView *)[cell.contentView viewWithTag:kVideoListCellThumbnailTag];        
        [self updateThumbnailView:thumbnailView forVideo:video];//this line places thumbnail image
        
        [cellConfigPool release];
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (self.videos.count > indexPath.row) {
        NSString *section = [[self.videoSections objectAtIndex:self.activeSectionIndex] objectForKey:@"value"];
        Video *video = [self.videos objectAtIndex:indexPath.row];
        // FIXME: call appDelegate showPage here, don't assume a nav controller exists
        VideoDetailViewController *detailViewController = 
        [[VideoDetailViewController alloc] initWithVideo:video andSection:section];
        [self.navigationController pushViewController:detailViewController 
                                             animated:YES];
        [detailViewController release];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.navScrollView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.navScrollView.frame.size.height;
}

#pragma mark MITThumbnailDelegate
- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    // Store the loaded thumbnail so that it doesn't have to be loaded again.
    Video *video = (Video *)[[CoreDataManager sharedManager] 
                             uniqueObjectForEntity:@"Video" 
                             attribute:@"thumbnailURLString"
                             value:thumbnail.imageURL];
    video.thumbnailImageData = data;
}

#pragma mark KGOScrollingTabstripDelegate

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index {
    self.activeSectionIndex = index;
    [self requestVideosForActiveSection];
    if (self.videoSections.count > self.activeSectionIndex) {
        VideoModule *module = (VideoModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:self.dataManager.moduleTag];
        module.searchSection = [[self.videoSections objectAtIndex:self.activeSectionIndex] objectForKey:@"value"];
    }
}

- (void)tabstripBookmarkButtonPressed:(id)sender {
    showingBookmarks = YES;
    self.videos = [self.dataManager bookmarkedVideos];
    [self.tableView reloadData];
}

- (BOOL)tabstripShouldShowSearchDisplayController:(KGOScrollingTabstrip *)tabstrip
{
    return YES;
}

- (UIViewController *)viewControllerForTabstrip:(KGOScrollingTabstrip *)tabstrip
{
    return self;
}

#pragma mark KGOSearchDisplayDelegate
- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return NO;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:self.dataManager.moduleTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return self.dataManager.moduleTag;
}

// FIXME
- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder 
      didSelectResult:(id<KGOSearchResult>)aResult {
    
    NSString *section = [[self.videoSections objectAtIndex:self.activeSectionIndex] objectForKey:@"value"];
    
    if ([aResult isKindOfClass:[Video class]]) {
        VideoDetailViewController *detailViewController = [[VideoDetailViewController alloc] initWithVideo:(Video *)aResult andSection:section];
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];    
    }
}

- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    [self.navScrollView hideSearchBar];
    [self.navScrollView selectButtonAtIndex:self.activeSectionIndex];
}

@end
