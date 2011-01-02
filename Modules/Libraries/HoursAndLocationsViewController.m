//
//  HoursAndLocationsViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/18/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "HoursAndLocationsViewController.h"
#import "MITUIConstants.h"
#import "Library.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "LibrariesMultiLineCell.h"

@interface HoursAndLocationsViewController (Private)

- (NSArray *)currentLibraries;

@end

@implementation HoursAndLocationsViewController
@synthesize listOrMapView;
@synthesize showingMapView;
@synthesize librayLocationsMapView;
@synthesize showArchives;


- (NSArray *)currentLibraries {
    
    NSArray *currentLibraries = nil;
    
    if (showArchives) {
        if (showingOnlyOpen == NO) {
            currentLibraries = [[LibraryDataManager sharedManager] allArchives];
        } else {
            currentLibraries = [[LibraryDataManager sharedManager] allOpenArchives];
        }
    } else {
        if (showingOnlyOpen == NO) {
            currentLibraries = [[LibraryDataManager sharedManager] allLibraries];
        } else {
            currentLibraries = [[LibraryDataManager sharedManager] allOpenLibraries];
        }
    }
    
    return currentLibraries;
}

- (void)pingLibraries {
    // TODO: subscribe to failure notifications if necessary
    
    if (![[self currentLibraries] count]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:showingOnlyOpen ? @selector(openLibrariesDidLoad) : @selector(librariesDidLoad)
                                                     name:LibraryRequestDidCompleteNotification
                                                   object:showingOnlyOpen ? LibraryDataRequestOpenLibraries : LibraryDataRequestLibraries];
    }
}


-(id)initWithType:(NSString *) type {
	
	self = [super init];
	
	if (self) {
		
		/*CGRect frame = CGRectMake(0, 0, 400, 44);
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
        //label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        self.navigationItem.titleView = label;
       // label.text = NSLocalizedString(@"Locations & Hours", @"");
		label.text = type;
		typeOfRepo = type;*/
		
		typeOfRepo = [type retain];
	}
	
	return self;
}


-(void) viewDidLoad {
	
	if (self.showingMapView != YES)
		self.showingMapView = NO;
	
	gpsPressed = NO;
	
	if (nil == _viewTypeButton)
		_viewTypeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
													   style:UIBarButtonItemStylePlain 
													  target:self
													   action:@selector(displayTypeChanged:)] autorelease];
	//_viewTypeButton.enabled = NO;										  
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
    imageView.tag = 1005;



	
	//Create the segmented control
	
	NSString * typeOfRepoString = @"All Libraries";
	
	if ((nil != typeOfRepo) && ([typeOfRepo isEqualToString:@"Archives"]))
		typeOfRepoString = @"All Archives";
	
	CGFloat footerDisplacementFromTop = self.view.frame.size.height -  NAVIGATION_BAR_HEIGHT;
	
	if (![typeOfRepo isEqualToString:@"Archives"])
		footerDisplacementFromTop -= imageView.frame.size.height;
	
	imageView.frame = CGRectMake(0, footerDisplacementFromTop, imageView.frame.size.width, imageView.frame.size.height);
		
	NSArray *itemArray = [NSArray arrayWithObjects: typeOfRepoString, @"Open Now", nil];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
	segmentedControl.tintColor = [UIColor darkGrayColor];
	segmentedControl.frame = CGRectMake(80, footerDisplacementFromTop + 8, 170, 30);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.selectedSegmentIndex = 0;
	[segmentedControl addTarget:self
	                     action:@selector(pickOne:)
	           forControlEvents:UIControlEventValueChanged];
	
	if (![typeOfRepo isEqualToString:@"Archives"]){
		
		[self.view addSubview:imageView];
		[imageView release];
		[self.view addSubview:segmentedControl];
		
		
	}
	//[segmentedControl release];
	
	
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
	
	showingOnlyOpen = NO;
	
	[self.listOrMapView addSubview:_tableView];
    
    [self pingLibraries];
	
	/*
	NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
	NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:matchAll];
	
	tempArray = [tempArray sortedArrayUsingFunction:libraryNameSort context:self];
	
	allLibraries = nil;
	allOpenLibraries = nil;
	allLibraries = [[[NSMutableArray alloc] init] retain];
	allOpenLibraries = [[[NSMutableArray alloc] init] retain];
	for(Library * lib in tempArray) {
		
		if (showArchives == YES) {
			if ([lib.type isEqualToString:@"archive"])
				[allLibraries addObject:lib];
		}
		else {
			if ([lib.type isEqualToString: @"library"])
				[allLibraries addObject:lib];
		}

		
		
	}
	*/
}

- (void)librariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraries];
    [_tableView reloadData];
}

- (void)openLibrariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestOpenLibraries];
    [_tableView reloadData];
}



//Action method executes when user touches the button
- (void) pickOne:(id)sender{
	//UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	[segmentedControl selectedSegmentIndex];
	
	showingOnlyOpen = !showingOnlyOpen;
    [self pingLibraries];
    
	[_tableView reloadData];
	
	
	if (showingMapView == YES) {
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
         /*
		if (nil != librayLocationsMapView) {
			if (showingOnlyOpen == NO)
				[librayLocationsMapView setAllLibraryLocations:allLibraries];
			
			else {
				[librayLocationsMapView setAllLibraryLocations:allOpenLibraries];
			}
			
			[librayLocationsMapView viewWillAppear:YES];
		}
          */
	}
	
	//label.text = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
} 


-(void)displayTypeChanged:(id)sender {
	
	if([_viewTypeButton.title isEqualToString:@"Map"]) {
		[self setMapViewMode:YES animated:YES];
		showingMapView = YES;
	}
	else if ([_viewTypeButton.title isEqualToString:@"List"]) {
		[self setMapViewMode:NO animated:YES];
		showingMapView = NO;
	}
	
	if (self.showingMapView == YES)
		[self.view addSubview:gpsButtonControl];
	
	else {
		
		[gpsButtonControl removeFromSuperview];
		[gpsButtonControl retain];
	}
}

-(void) gpsButtonPressed:(id)sender {
	UISegmentedControl *segmentedController = (UISegmentedControl *)sender;
	segmentedController.selectedSegmentIndex = -1;

	if (showingMapView == YES)
	{
		//self.librayLocationsMapView.mapView.showsUserLocation = !self.librayLocationsMapView.mapView.showsUserLocation;
		
		if (!self.librayLocationsMapView.mapView.showsUserLocation) {	
			

				BOOL successful = [self.librayLocationsMapView mapView:self.librayLocationsMapView.mapView 
									   didUpdateUserLocation:self.librayLocationsMapView.mapView.userLocation];
			
				if (successful == YES)
					self.librayLocationsMapView.mapView.showsUserLocation = YES;
			
			}
		
		else {	
			self.librayLocationsMapView.mapView.showsUserLocation = NO;
				self.librayLocationsMapView.mapView.region = [self.librayLocationsMapView 
															  regionForAnnotations:self.librayLocationsMapView.mapView.annotations];

			
		}
	}		
		
	gpsPressed = !gpsPressed;
}


// set the view to either map or list mode
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated {
	//NSLog(@"map is showing=%i", _mapShowing);
	if (showMap == YES) {
		if (showingMapView)
			return;
	}

	// flip to the correct view. 
	if (animated) {
		[UIView beginAnimations:@"flip" context:nil];
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.listOrMapView cache:NO];
	}
	
	if (!showMap) {
		
		if (nil != self.librayLocationsMapView)
			[self.librayLocationsMapView.view removeFromSuperview];
		
			[self.listOrMapView addSubview:_tableView];
			[_tableView reloadData];
			self.librayLocationsMapView = nil;
			_viewTypeButton.title = @"Map";


	} else {
		[_tableView removeFromSuperview];
				
		if (nil == librayLocationsMapView) {
			librayLocationsMapView = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.listOrMapView.frame];

		}
		librayLocationsMapView.navController = self;
		
		//librayLocationsMapView.parentViewController = self;
		librayLocationsMapView.view.frame = self.listOrMapView.frame;
		[self.listOrMapView addSubview:librayLocationsMapView.view];
		/*
		if (showingOnlyOpen == NO)
			[librayLocationsMapView setAllLibraryLocations:allLibraries];
		
		else {
			[librayLocationsMapView setAllLibraryLocations:allOpenLibraries];
		}
         */
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
         
		[librayLocationsMapView viewWillAppear:YES];
		_viewTypeButton.title = @"List";

	}
	
	if(animated) {
		[UIView commitAnimations];
	}
	
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


/*- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}*/

- (void)viewDidUnload {
    [super viewDidUnload];

    
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [typeOfRepo release];
    
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	//return 6;
	int count = 0;
    
    count = [[self currentLibraries] count];
	/*
	if (showingOnlyOpen == NO) {
		if (nil != allLibraries)
			count = [allLibraries count];
	}
	else {
		if (nil != allOpenLibraries)
			count = [allOpenLibraries count];
	}
     */
	
	return count;

}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Library * lib; 
	NSString * cellText = @"";
	/*
	if (showingOnlyOpen == NO) {
		lib = [allLibraries objectAtIndex:indexPath.section];
		
		if (nil != lib)
			cellText = lib.name;
	}
	
	else {
		lib = [allOpenLibraries objectAtIndex:indexPath.section];
		
		if (nil != lib)
			cellText = lib.name;
	}
	*/
    lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    cellText = lib.name;
    
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
	
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleDefault
                                                tableView:tableView 
                                                     text:cellText
                                             maxTextLines:2
                                               detailText:nil
                                           maxDetailLines:0
                                                     font:nil 
                                               detailFont:nil
                                            accessoryType:accessoryType
                                                cellImage:NO];
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *optionsForMainViewTableStringConstant = @"listViewCellMultiLine";
	LibrariesMultiLineCell *cell = nil;
	
	
	cell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:optionsForMainViewTableStringConstant];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:optionsForMainViewTableStringConstant] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.textLabel.numberOfLines = 2;
	
	Library * lib; 
    /*
	if (showingOnlyOpen == NO) {
	 lib = [allLibraries objectAtIndex:indexPath.section];
	
	if (nil != allLibraries)
		cell.textLabel.text = lib.name;
	}
	
	else {
		lib = [allOpenLibraries objectAtIndex:indexPath.section];
			
			if (nil != allOpenLibraries)
				cell.textLabel.text = lib.name;
		}
	*/
    
    lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    cell.textLabel.text = lib.name;
    
    return cell;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	//NSMutableArray *tempLibraries;
	NSMutableArray *tempIndexArray = [NSMutableArray array];
	
	/*
	if (showingOnlyOpen == NO)
		tempLibraries = allLibraries;
	
	else {
		tempLibraries = allOpenLibraries;
	}
     */
    NSArray *tempLibraries = [self currentLibraries];
	
	for(Library *lib in tempLibraries) {
		if (![tempIndexArray containsObject:[lib.name substringToIndex:1]])
			[tempIndexArray addObject:[lib.name substringToIndex:1]];		
	}
	
	NSArray *indexArray = (NSArray *)tempIndexArray;
	
	return indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    /*
	NSMutableArray *tempLibraries;
	
	if (showingOnlyOpen == NO)
		tempLibraries = allLibraries;
	
	else {
		tempLibraries = allOpenLibraries;
	}
     */
    NSArray *tempLibraries = [self currentLibraries];
	int ind = 0;
	
	for(Library *lib in tempLibraries) {
		if ([[lib.name substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	LibraryDetailViewController *vc = [[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
							
	
	
	//apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];
	
	NSArray * tempArray;
	/*
	if (showingOnlyOpen == NO)
		tempArray = allLibraries;
	else {
		tempArray = allOpenLibraries;
	}
     */
    tempArray = [self currentLibraries];
    
	Library * lib = (Library *) [tempArray objectAtIndex:indexPath.section];
	vc.lib = lib;
	
	if ([lib.type isEqualToString:@"archive"])
		vc.title = @"Archive Detail";
	
	else
		vc.title = @"Library Detail";
	
	vc.otherLibraries = tempArray;
	vc.currentlyDisplayingLibraryAtIndex = indexPath.section;
    [self.navigationController pushViewController:vc animated:YES];
	/*
	NSString * libOrArchive;
	
	if ([lib.type isEqualToString:@"archive"])
		libOrArchive = @"archivedetail";
	
	else {
		libOrArchive = @"libdetail";
	}
    
	if ([apiRequest requestObjectFromModule:@"libraries" 
									command:libOrArchive
								 parameters:[NSDictionary dictionaryWithObjectsAndKeys:lib.identityTag, @"id", lib.name, @"name", nil]])
	{
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
															message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
    */
	[vc release];
	
}

/*
#pragma mark -
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {

	NSArray *resultArray = (NSArray *)result;
	
	if ([result count]){
		allLibraries = nil;
		allOpenLibraries = nil;
		allLibraries = [[[NSMutableArray alloc] init] retain];
		allOpenLibraries = [[[NSMutableArray alloc] init] retain];
	}
	
	for (int index=0; index < [result count]; index++) {
		NSDictionary *libraryDictionary = [resultArray objectAtIndex:index];
		
		NSString * name = [libraryDictionary objectForKey:@"name"];
		NSString * primaryName = [libraryDictionary objectForKey:@"primaryName"];
		NSString * identityTag = [libraryDictionary objectForKey:@"id"];
		 NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
		NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
		NSString * location = [libraryDictionary objectForKey:@"address"];
		
		NSString * type = [libraryDictionary objectForKey:@"type"];
		
		NSString *isOpenNow = [libraryDictionary objectForKey:@"isOpenNow"];
		
		BOOL isOpen = NO;
		if ([isOpenNow isEqualToString:@"YES"])
			isOpen = YES;
		
		NSString *typeOfLib;
		
		if (showArchives == YES)
			typeOfLib = @"archive";
		
		else {
			typeOfLib = @"library";
		}

		
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", name, typeOfLib];
		Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];

		
		NSManagedObject *managedObj;
		if (nil == alreadyInDB){
			managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
			alreadyInDB = (Library *)managedObj;
			alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
		}
			
		//[alreadyInDB setValue:name forKey:@"name"];
		//[alreadyInDB setValue:[NSNumber numberWithDouble:[latitude doubleValue]] forKey:@"lat"];
		//[alreadyInDB setValue:[NSNumber numberWithDouble:[longitude doubleValue]] forKey:@"lon"];		
		
		alreadyInDB.name = name;
		alreadyInDB.primaryName = primaryName;
		alreadyInDB.identityTag = identityTag;
		alreadyInDB.location = location;
		alreadyInDB.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
		alreadyInDB.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
		alreadyInDB.type = type;
		
		alreadyInDB.isBookmarked = alreadyInDB.isBookmarked;
		
		[allLibraries addObject:alreadyInDB];
		
		if (isOpen)
			[allOpenLibraries addObject:alreadyInDB];
		
	}
	
	NSArray * tempArray = [allLibraries sortedArrayUsingFunction:libraryNameSort context:self];
	
	allLibraries = nil;
	allLibraries = [[NSMutableArray alloc] init];
	for(Library * lib in tempArray) {
		[allLibraries addObject:lib];		
	}
	
	tempArray = nil;
	tempArray = [allOpenLibraries sortedArrayUsingFunction:libraryNameSort context:self];
	allOpenLibraries = nil;
	allOpenLibraries = [[NSMutableArray alloc] init];
	for(Library * lib in tempArray) {
		[allOpenLibraries addObject:lib];		
	}
	
	[allLibraries retain];
	[allOpenLibraries retain];
	
	[CoreDataManager saveData];
	
	
	[_tableView reloadData];
	//[parentViewController removeLoadingIndicator];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {

    return YES;
}

NSInteger libraryNameSort(id lib1, id lib2, void *context) {

	Library * library1 = (Library *)lib1;
	Library * library2 = (Library *)lib2;
	
	return [library1.name compare:library2.name];
}	
*/

@end
