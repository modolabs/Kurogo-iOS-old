//
//  VideoListViewController.m
//  Universitas
//

#import "VideoListViewController.h"
#import "Constants.h"
#import "Video.h"
#import "VideoDetailViewController.h"
#import "CoreDataManager.h"

static const NSInteger kVideoListCellThumbnailTag = 0x78;

#pragma mark Private methods

@interface VideoListViewController (Private)

+ (NSString *)detailTextForVideo:(Video *)video;
- (void)updateThumbnailView:(MITThumbnailView *)thumbnailView 
                   forVideo:(Video *)video;
- (void)requestVideosForActiveSection;

@end

@implementation VideoListViewController (Private)

+ (NSString *)detailTextForVideo:(Video *)video {
    return [NSString stringWithFormat:@"(%@) %@", 
            [video durationString], video.videoDescription];
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
        [self.dataManager 
         requestVideosForSection:
         [[self.videoSections objectAtIndex:self.activeSectionIndex] 
          objectForKey:@"value"]
         thenRunBlock:^(id result) { 
             if ([result isKindOfClass:[NSArray class]])
             {
                 self.videos = result;
                 [self.tableView reloadData];
             }
         }];
    }
}    

@end


@implementation VideoListViewController

@synthesize dataManager;
@synthesize moduleTag;
@synthesize navScrollView;
@synthesize videos;
@synthesize videoSections;
@synthesize activeSectionIndex;

#pragma mark NSObject

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
	if (self)
	{
        self.dataManager = [[[VideoDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = moduleTag = VideoModuleTag;
        self.activeSectionIndex = 0;
	}
	return self;
}

- (void)dealloc {
    [videoSections release];
    [videos release];
    [navScrollView release];
    [dataManager release];
    [moduleTag release];
    [super dealloc];
}

#pragma mark UIViewController

- (void)loadView {
    [super loadView];
    
    self.navScrollView =
    [[[KGOScrollingTabstrip alloc] 
      initWithFrame:CGRectMake(0, 
                               0, 
                               [UIScreen mainScreen].applicationFrame.size.width, 
                               44)]
     autorelease];
    self.navScrollView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 90.0f;
    
    [self.dataManager requestSectionsThenRunBlock:
     ^(id result) {
         if ([result isKindOfClass:[NSArray class]]) {
             self.videoSections = result;
             for (NSDictionary *sectionInfo in videoSections) {
                 [self.navScrollView addButtonWithTitle:
                  [sectionInfo objectForKey:@"title"]];
             }
             [self.navScrollView selectButtonAtIndex:self.activeSectionIndex];
             [self.navScrollView setNeedsLayout];
             [self requestVideosForActiveSection];
         }
     }];
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             CellIdentifier];
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
        
        MITThumbnailView *thumbnailView = 
        [[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 120, 90)];
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
                
        MITThumbnailView *thumbnailView = 
        (MITThumbnailView *)[cell.contentView viewWithTag:kVideoListCellThumbnailTag];        
        [self updateThumbnailView:thumbnailView forVideo:video];
        
        [cellConfigPool release];
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.videos.count > indexPath.row) {
        Video *video = [self.videos objectAtIndex:indexPath.row];
        VideoDetailViewController *detailViewController = 
        [[VideoDetailViewController alloc] initWithVideo:video];
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
                             getObjectForEntity:@"Video" 
                             attribute:@"thumbnailURLString"
                             value:thumbnail.imageURL];
    video.thumbnailImageData = data;
}

#pragma mark KGOScrollingTabstripDelegate
- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index {
    self.activeSectionIndex = index;
    [self requestVideosForActiveSection];
}

@end
