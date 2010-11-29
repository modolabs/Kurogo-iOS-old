//
//  BookmarkedLibrariesOrArchives.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/29/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "BookmarkedLibrariesOrArchives.h"
#import "MITUIConstants.h"
#import "BookmarkedHoursAndLocationsViewController.h"


@implementation BookmarkedLibrariesOrArchives


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	[self.tableView applyStandardColors];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Celldfjsdjfsdnf";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	
	if (indexPath.row == 0)
		cell.textLabel.text = @"Bookmarked Libraries";
	
	else if (indexPath.row == 1)
		cell.textLabel.text = @"Bookmarked Archives";
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	BookmarkedHoursAndLocationsViewController * vc = [[BookmarkedHoursAndLocationsViewController alloc] init];
	apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];	
    if (indexPath.row == 0) {
		vc.showArchives = NO;
		
		if ([apiRequest requestObjectFromModule:@"libraries" 
										command:@"libraries" 
									 parameters:nil] == YES)
		{
			[self.navigationController pushViewController:vc animated:YES];
		}
		else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																message:@"Could not connect to the server" 
															   delegate:self 
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil];
			[alertView show];
			[alertView release];
		}
		
	}
	
	else if (indexPath.row == 1) {
		vc.showArchives = YES;
		
		if ([apiRequest requestObjectFromModule:@"libraries" 
										command:@"archives" 
									 parameters:nil] == YES)
		{
			[self.navigationController pushViewController:vc animated:YES];
		}
		else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																message:@"Could not connect to the server" 
															   delegate:self 
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil];
			[alertView show];
			[alertView release];
		}
	}
	

	[vc release];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

