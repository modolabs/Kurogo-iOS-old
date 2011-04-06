//
//  VideoListViewController.m
//  Universitas
//

#import "VideoListViewController.h"
#import "Constants.h"
#import "Video.h"
#import "VideoDetailViewController.h"
#import "MITThumbnailView.h"

#pragma mark Private methods

@interface VideoListViewController (Private)

+ (NSString *)detailTextForVideo:(Video *)video;
- (UIImage *)thumbnailForURLString:(NSString *)urlString;

@end

@implementation VideoListViewController (Private)

+ (NSString *)detailTextForVideo:(Video *)video {
    return [NSString stringWithFormat:@"(%@) %@", 
            [video durationString], video.videoDescription];
}

- (UIImage *)thumbnailForURLString:(NSString *)urlString {
    UIImage *thumbnail = [self.thumbnailCache objectForKey:urlString];
    if (!thumbnail) {
        thumbnail = [UIImage imageWithData:
                     [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]]];
        [self.thumbnailCache setObject:thumbnail forKey:urlString];
    }
    return thumbnail;
}

@end


@implementation VideoListViewController

@synthesize dataManager;
@synthesize moduleTag;
@synthesize navScrollView;
@synthesize videos;
@synthesize videoSections;
@synthesize activeSectionIndex;
@synthesize thumbnailCache;

#pragma mark NSObject

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
	if (self)
	{
        self.dataManager = [[[VideoDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = moduleTag = VideoModuleTag;
        self.activeSectionIndex = 0;
        self.thumbnailCache = [NSMutableDictionary dictionaryWithCapacity:20];
	}
	return self;
}

- (void)dealloc {
    [thumbnailCache release];
    [videoSections release];
    [videos release];
    [navScrollView release];
    [dataManager release];
    [moduleTag release];
    [super dealloc];
}

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 80.0f;
    
    [self.dataManager requestSectionsThenRunBlock:
     ^(id result)
     {
         if ([result isKindOfClass:[NSArray class]])
         {
             NSLog(@"Retrieved sections. There are %d of them.", [result count]);
             self.videoSections = result;
             [self.dataManager 
              requestVideosForSection:
              [[self.videoSections objectAtIndex:self.activeSectionIndex] 
               objectForKey:@"value"]
              thenRunBlock:
              ^(id result)
              {
                  if ([result isKindOfClass:[NSArray class]])
                  {
                      self.videos = result;
                      [self.tableView reloadData];
                  }
              }];
         }
     }];
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
    }
    
    // Configure the cell...
    if (self.videos.count > indexPath.row) {
        NSAutoreleasePool *cellConfigPool = [[NSAutoreleasePool alloc] init];
        Video *video = [self.videos objectAtIndex:indexPath.row];
        cell.textLabel.text = video.title;
        cell.detailTextLabel.text = [[self class] detailTextForVideo:video];
        cell.imageView.image = [self thumbnailForURLString:video.imageURLString];
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
        [self.navigationController pushViewController:detailViewController animated:YES];
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

@end
