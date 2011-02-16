#import "KGOHomeScreenTableViewController.h"
#import "KGOModule.h"

@implementation KGOHomeScreenTableViewController


#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    [super loadView];
    
    CGFloat searchBarHeight = 0;
    if (_searchBar) {
        searchBarHeight = _searchBar.frame.size.height;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, searchBarHeight,
                                                               self.view.bounds.size.width,
                                                               self.view.bounds.size.height - searchBarHeight)
                                              style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger num = 0;
    
    if ([self.primaryModules count])
        num++;
    if ([self.secondaryModules count])
        num++;

    return num;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [self.primaryModules count]) {
        return self.primaryModules.count;

    } else {
        return self.secondaryModules.count;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    KGOModule *aModule;
    
    if (indexPath.section == 0 && [self.primaryModules count]) {
        aModule = [self.primaryModules objectAtIndex:indexPath.row];
        
    } else {
        aModule = [self.secondaryModules objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = aModule.longName;
    cell.imageView.image = [aModule iconImage];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    KGOModule *aModule;
    if (indexPath.section == 0 && [self.primaryModules count]) {
        aModule = [self.primaryModules objectAtIndex:indexPath.row];
        
    } else {
        aModule = [self.secondaryModules objectAtIndex:indexPath.row];
    }

	if ([aModule.tag isEqualToString:FullWebTag]) {
        NSString * file = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
        NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:file];
        NSString *urlString = [infoDict objectForKey:@"FullWebURL"];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
		return;
	}
    
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameHome forModuleTag:aModule.tag params:nil];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

