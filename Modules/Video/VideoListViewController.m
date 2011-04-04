//
//  VideoListViewController.m
//  Universitas
//

#import "VideoListViewController.h"
#import "Constants.h"
#import "Video.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    if (self.videos.count > indexPath.row) {
//        Video *video = [self.videos objectAtIndex:indexPath.row];
        NSDictionary *info = [self.videos objectAtIndex:indexPath.row];
        cell.textLabel.text = [info objectForKey:@"title"];
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.navScrollView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.navScrollView.frame.size.height;
}

@end
