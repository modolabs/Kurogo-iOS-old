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
#import "LibraryAlias.h"

@interface HoursAndLocationsViewController (Private)

- (NSArray *)currentLibraries;

@end

@implementation HoursAndLocationsViewController
@synthesize showingMapView;
@synthesize librayLocationsMapView;
@synthesize showArchives;
@synthesize showBookmarks;
@synthesize typeOfRepo;

- (NSArray *)currentLibraries {
    
    NSArray *currentLibraries = nil;
    
    if (showBookmarks) {
        NSPredicate *bookmarkPred = [NSPredicate predicateWithFormat:@"name like library.primaryName AND library.isBookmarked == YES"];
        NSArray *libraries;
        NSArray *archives;
        
        if (showingOnlyOpen == NO) {
            libraries = [[LibraryDataManager sharedManager] allLibraries];
            archives = [[LibraryDataManager sharedManager] allArchives];
        } else {
            libraries = [[LibraryDataManager sharedManager] allOpenLibraries];
            archives = [[LibraryDataManager sharedManager] allOpenArchives];
        }
        
        NSArray *everything = [libraries arrayByAddingObjectsFromArray:archives];
        NSArray *bookmarkedLibraries = [everything filteredArrayUsingPredicate:bookmarkPred];
        currentLibraries = [bookmarkedLibraries sortedArrayUsingFunction:libraryNameSort context:nil];
        
    } else {    
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


-(void) viewDidLoad {
    
    if (showBookmarks) {
        CGRect frame = CGRectMake(0, 0, 400, 44);
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        self.navigationItem.titleView = label;
        label.text = NSLocalizedString(@"Bookmarked Repositories", @"");
    }
	
	gpsPressed = NO;
	showingOnlyOpen = NO;
	
	if (nil == _viewTypeButton)
		_viewTypeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
                                                            style:UIBarButtonItemStylePlain 
                                                           target:self
                                                           action:@selector(displayTypeChanged:)] autorelease];

	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]] autorelease];
    imageView.tag = 1005;

    if (showBookmarks) {
        CGFloat footerDisplacementFromTop = self.view.frame.size.height -  NAVIGATION_BAR_HEIGHT -  imageView.frame.size.height;
        imageView.frame = CGRectMake(0, footerDisplacementFromTop, imageView.frame.size.width, imageView.frame.size.height);
        [self.view addSubview:imageView];
    }

	NSString * typeOfRepoString = @"All Libraries";
	
	if (!showBookmarks && (nil != typeOfRepo) && ([typeOfRepo isEqualToString:@"Archives"]))
		typeOfRepoString = @"All Archives";
	
	CGFloat footerDisplacementFromTop = self.view.frame.size.height -  NAVIGATION_BAR_HEIGHT;
	
	if (![typeOfRepo isEqualToString:@"Archives"])
		footerDisplacementFromTop -= imageView.frame.size.height;
	
	imageView.frame = CGRectMake(0, footerDisplacementFromTop, imageView.frame.size.width, imageView.frame.size.height);

	//Create the segmented control
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
        // TODO: does archives not have an open/closed state?
		[self.view addSubview:segmentedControl];
	}
	
	
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

    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, footerDisplacementFromTop);
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;

    [self.view addSubview:_tableView];
    
    [self pingLibraries];
}

- (void)librariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraries];
    [_tableView reloadData];
}

- (void)openLibrariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestOpenLibraries];
    [_tableView reloadData];
}



// called when user toggles "all" vs "open now" segment at the bottom
- (void) pickOne:(id)sender{
	//UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	//[segmentedControl selectedSegmentIndex];
	
	showingOnlyOpen = !showingOnlyOpen;
    [self pingLibraries];
    
	[_tableView reloadData];
	
	
	if (showingMapView == YES) {
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
        
        [librayLocationsMapView viewWillAppear:YES];
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
	if (showMap == showingMapView) {
        return;
	}

	// flip to the correct view. 
	if (animated) {
		[UIView beginAnimations:@"flip" context:nil];
		//[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.listOrMapView cache:NO];
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
	}
	
	if (!showMap) {
		
		if (nil != self.librayLocationsMapView)
			[self.librayLocationsMapView.view removeFromSuperview];
		
        [self.view addSubview:_tableView];
			[_tableView reloadData];
			self.librayLocationsMapView = nil;
			_viewTypeButton.title = @"Map";


	} else {
		[_tableView removeFromSuperview];
				
		if (nil == librayLocationsMapView) {
            librayLocationsMapView = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.view.frame];
		}
		librayLocationsMapView.navController = self;
		
        librayLocationsMapView.view.frame = self.view.frame;
        [self.view addSubview:librayLocationsMapView.view];
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
         
		[librayLocationsMapView viewWillAppear:YES];
		_viewTypeButton.title = @"List";

	}
	
	if(animated) {
		[UIView commitAnimations];
	}
	
}


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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tableView release];
    [librayLocationsMapView release];
    [segmentedControl release];
    [filterButtonControl release];
    [gpsButtonControl release];
    
    self.typeOfRepo = nil;
    
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	int count = [[self currentLibraries] count];
	
	return count;

}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LibraryAlias * lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    NSString * cellText = lib.name;
    
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
	
	LibraryAlias * lib;
    
    lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    cell.textLabel.text = lib.name;
    
    return cell;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	NSMutableArray *tempIndexArray = [NSMutableArray array];
	
    NSArray *tempLibraries = [self currentLibraries];
	
	for(LibraryAlias *lib in tempLibraries) {
		if (![tempIndexArray containsObject:[lib.name substringToIndex:1]])
			[tempIndexArray addObject:[lib.name substringToIndex:1]];		
	}
	
	NSArray *indexArray = (NSArray *)tempIndexArray;
	
	return indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {

    NSArray *tempLibraries = [self currentLibraries];
	int ind = 0;
	
	for(LibraryAlias *lib in tempLibraries) {
		if ([[lib.name substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	LibraryDetailViewController *vc = [[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	
	NSArray * tempArray;

    tempArray = [self currentLibraries];
    
	LibraryAlias * lib = (LibraryAlias *) [tempArray objectAtIndex:indexPath.section];
	vc.lib = lib;
	vc.otherLibraries = tempArray;
	vc.currentlyDisplayingLibraryAtIndex = indexPath.section;
	
	if ([lib.library.type isEqualToString:@"archive"])
		vc.title = @"Archive Detail";
	
	else
		vc.title = @"Library Detail";
	
    [self.navigationController pushViewController:vc animated:YES];

	[vc release];
	
}

@end
