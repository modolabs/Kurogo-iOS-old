#import "FederatedSearchTableView.h"
#import "MITModule.h"
#import "SpringboardViewController.h"
#import "UIKit+MITAdditions.h"

@implementation FederatedSearchTableView

@synthesize searchableModules, query;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}



#pragma mark UITableView datasource

// TODO: don't waste space with modules that return no results
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.searchableModules count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    MITModule *aModule = [self.searchableModules objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    if (aModule.searchProgress == 1.0) {
        cell.imageView.image = nil;
		
        if (indexPath.row == MAX_FEDERATED_SEARCH_RESULTS) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"See all %d matches", [aModule totalSearchResults]];
            cell.detailTextLabel.text = nil;
            
        } else if (![aModule.searchResults count]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No matches found.";
            cell.detailTextLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
        } else {
            id aResult = [aModule.searchResults objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = [aModule titleForSearchResult:aResult];
            cell.detailTextLabel.text = [aModule subtitleForSearchResult:aResult];
        }
		
    } else {
        
        // indeterminate loading indicator
        cell.textLabel.text = @"Searching...";
        cell.detailTextLabel.text = nil;
        
		[cell.imageView showLoadingIndicator];
        
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 1;
    MITModule *aModule = [self.searchableModules objectAtIndex:section];
    if (aModule.searchProgress == 1.0) {
        num = [aModule.searchResults count];
        if (num > MAX_FEDERATED_SEARCH_RESULTS) {
            num = MAX_FEDERATED_SEARCH_RESULTS + 1; // one extra row for "more"
        } else if (num == 0) {
            num = 1;
        }
    }
    return num;
}
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MITModule *aModule = [self.searchableModules objectAtIndex:section];
    NSString *title = aModule.longName;
    return [UITableView ungroupedSectionHeaderWithTitle:title];
}
*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MITModule *aModule = [self.searchableModules objectAtIndex:indexPath.section];
    if ([aModule.searchResults count]) {
        MIT_MobileAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		[appDelegate springboard].activeModule = aModule;
        if (indexPath.row == MAX_FEDERATED_SEARCH_RESULTS) {
            [aModule handleLocalPath:LocalPathFederatedSearch query:[NSString stringWithFormat:@"%@", self.query, indexPath.row]];
        } else {
            // TODO: decide whether the query string really needs to be passed to the module
            [aModule handleLocalPath:LocalPathFederatedSearchResult query:[NSString stringWithFormat:@"%d", indexPath.row]];
        }
        [appDelegate showModuleForTag:aModule.tag];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MITModule *aModule = [self.searchableModules objectAtIndex:section];
	return aModule.longName;
}
/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UNGROUPED_SECTION_HEADER_HEIGHT;
}
*/

@end
