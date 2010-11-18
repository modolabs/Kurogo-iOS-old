//
//  HoursAndLocationsViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/18/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "HoursAndLocationsViewController.h"
#import "MITUIConstants.h"

@implementation HoursAndLocationsViewController
@synthesize listOrMapView;
@synthesize showingMapView;


-(id)init {
	
	self = [super init];
	
	if (self) {
		
		CGRect frame = CGRectMake(0, 0, 400, 44);
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        //label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        self.navigationItem.titleView = label;
        label.text = NSLocalizedString(@"Locations & Hours", @"");
	}
	
	return self;
}

-(void) viewDidLoad {
	
	if (self.showingMapView != YES)
		self.showingMapView = NO;
	
	_viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Map"
													   style:UIBarButtonItemStylePlain 
													  target:self
													  action:@selector(displayTypeChanged:)];
	//_viewTypeButton.enabled = NO;										  
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
    imageView.tag = 1005;
	
	CGFloat footerDisplacementFromTop = self.view.frame.size.height -  NAVIGATION_BAR_HEIGHT -  imageView.frame.size.height;
	imageView.frame = CGRectMake(0, footerDisplacementFromTop, imageView.frame.size.width, imageView.frame.size.height);
    [self.view addSubview:imageView];
    [imageView release];
	

	
	//Create the segmented control
	NSArray *itemArray = [NSArray arrayWithObjects: @"All Libraries", @"Open Now", nil];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
	segmentedControl.tintColor = [UIColor darkGrayColor];
	segmentedControl.frame = CGRectMake(80, footerDisplacementFromTop + 8, 150, 30);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.selectedSegmentIndex = 0;
	[segmentedControl addTarget:self
	                     action:@selector(pickOne:)
	           forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:segmentedControl];
	//[segmentedControl release];
	
	
	NSArray *filterArray = [NSArray arrayWithObjects: @"Filter", nil];
	filterButtonControl = [[UISegmentedControl alloc] initWithItems:filterArray];
	filterButtonControl.tintColor = [UIColor darkGrayColor];
	filterButtonControl.frame = CGRectMake(260,footerDisplacementFromTop + 8, 50, 30);
	filterButtonControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[filterButtonControl addTarget:self
	                     action:@selector(filterButtonPressed:)
	           forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:filterButtonControl];
	//[filterButtonControl release];
	
	
	UIImage *gpsImage = [UIImage imageNamed:@"maps/map_button_icon_locate.png"];
	NSArray *gpsArray = [NSArray arrayWithObjects: gpsImage, nil];
	gpsButtonControl = [[UISegmentedControl alloc] initWithItems:gpsArray];
	gpsButtonControl.tintColor = [UIColor darkGrayColor];
	gpsButtonControl.frame = CGRectMake(10,footerDisplacementFromTop + 8, 30, 30);
	gpsButtonControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[gpsButtonControl addTarget:self
							action:@selector(gpsButtonPressed:)
				  forControlEvents:UIControlEventValueChanged];
	
	if (self.showingMapView == YES)
		[self.view addSubview:gpsButtonControl];
	
	//[gpsButtonControl release];
	
	self.listOrMapView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 
																	 self.view.frame.size.width,
																   footerDisplacementFromTop)] autorelease];
	
	[self.view addSubview:self.listOrMapView];
	
	
	_tableView = [[UITableView alloc] initWithFrame:self.listOrMapView.frame style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	
	[self.listOrMapView addSubview:_tableView];
	
	allLibraries = [[NSMutableArray alloc] initWithObjects:
					@"Abc Lib 1",
					@"Yak Lib 2",
					@"Utf Lib 0",
					@"Zkf Lib 4",
					@"Bea Lib 5",
					@"Trst Lib 11",
					@"Yte Lib 1",
					@"Cam Lib 2",
					@"Pst Lib 0",
					@"Que Lib 4",
					@"Mbt Lib 5",
					@"Wqt Lib 11",
					@"Xzw Lib 11",
					@"Klj Lib 1",
					@"Ghj Lib 2",
					@"Fft Lib 0",
					@"Ele Lib 4",
					@"Cos Lib 5",
					@"Doc Lib 11",
					nil];
	
	[allLibraries sortUsingSelector:@selector(compare:)];
}



//Action method executes when user touches the button
- (void) pickOne:(id)sender{
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	//[segmentedControl selectedSegmentIndex
	//label.text = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
} 


-(void)displayTypeChanged:(id)sender {
}

-(void) filterButtonPressed:(id)sender {
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	segmentedControl.selectedSegmentIndex = -1;

}

-(void) gpsButtonPressed:(id)sender {
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	segmentedControl.selectedSegmentIndex = -1;
}

/*
- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
    if (pressedButton.tag == SEARCH_BUTTON_TAG) {
        [self showSearchBar];
    } else {
        [self reloadView:pressedButton.tag];
    }
}
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	_viewTypeButton = nil;
	self.listOrMapView = nil;
	_tableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[_viewTypeButton dealloc];
	[listOrMapView dealloc];
	[_tableView dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	//return 6;
	
	int count = 0;
	if (nil != allLibraries)
		count = [allLibraries count];
	
	return count;

}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ShuttleStop *aStop = nil;
	if(nil != self.route && self.route.stops.count > indexPath.row) {
		aStop = [self.route.stops objectAtIndex:indexPath.row];
	}
	
	
	CGSize constraintSize = CGSizeMake(280.0f, 2009.0f);
	NSString* cellText = @"A"; // just something to guarantee one line
	UIFont* cellFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	
	if (aStop.upcoming)
		labelSize.height += 5.0f;
	
	return labelSize.height + 20.0f;
}
*/


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *optionsForMainViewTableStringConstant = @"listViewCell";
	UITableViewCell *cell = nil;
	
	
	cell = [tableView dequeueReusableCellWithIdentifier:optionsForMainViewTableStringConstant];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:optionsForMainViewTableStringConstant] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (nil != allLibraries)
		cell.textLabel.text = [allLibraries objectAtIndex:indexPath.section];
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	
	NSMutableArray *tempIndexArray = [NSMutableArray array];
	
	
	for(NSString *libraryName in allLibraries) {
		if (![tempIndexArray containsObject:[libraryName substringToIndex:1]])
			[tempIndexArray addObject:[libraryName substringToIndex:1]];		
	}
	
	NSArray *indexArray = (NSArray *)tempIndexArray;
	
	return indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	
	int ind = 0;
	
	for(NSString *libraryName in allLibraries) {
		if ([[libraryName substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}


@end
