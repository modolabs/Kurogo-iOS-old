//
//  LibItemDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibItemDetailViewController.h"
#import "MITUIConstants.h"
#import "CoreDataManager.h"
#import "ItemAvailabilityDetailViewController.h"
#import "LibraryLocationsMapViewController.h"
#import "LibrariesSearchViewController.h"
#import "LibraryAlias.h"

@implementation LibItemDetailViewController
@synthesize bookmarkButtonIsOn;
@synthesize displayImage;


#pragma mark -
#pragma mark Initialization

-(id) initWithStyle:(UITableViewStyle)style 
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex
	   imageDisplay:(BOOL) imageDisplay{
	
	self = [super initWithStyle:style];
	
	if (self) {

		libItem = [libraryItem retain];
		libItemDictionary = [results retain];
		currentIndex = itemIndex;
		displayImage = imageDisplay;
		
		//locationsWithItem = [[NSArray alloc] init];
        locationsWithItem = nil;
        displayLibraries = [[NSMutableArray alloc] init];
        
        [[LibraryDataManager sharedManager] registerItemDelegate:self];
	}
	
	return self;
}


/*
- (void)fullAvailabilityDidLoad {
    
    [displayNameAndLibraries setObject:alreadyInDB forKey:displayName];
    
    [self.tableView reloadData];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
}
*/

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.tableView applyStandardColors];
	
    [self setupLayout];
    
    if (!libItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
        [[LibraryDataManager sharedManager] requestDetailsForItem:libItem];
    } else {
        [self detailsDidLoadForItem:libItem];
    }
    if (![[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
        [[LibraryDataManager sharedManager] requestFullAvailabilityForItem:libItem.itemId];
    }

    // subscribe to libdetail notifications in case LibraryDataManager gets more info
    // while loading full availability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraryDetail];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestArchiveDetail];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//[self setupLayout];
}


- (void) setupLayout{
    
    // segment control
    if ([libItemDictionary count] && [libItemDictionary count] > 1) {
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                                        [UIImage imageNamed:MITImageNameUpArrow],
                                                                                        [UIImage imageNamed:MITImageNameDownArrow], nil]];
        [segmentControl setMomentary:YES];
        [segmentControl addTarget:self action:@selector(showNextLibItem:) forControlEvents:UIControlEventValueChanged];
        segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
        
        if (currentIndex == 0)
            [segmentControl setEnabled:NO forSegmentAtIndex:0];
        
        if (currentIndex == [libItemDictionary count] - 1)
            [segmentControl setEnabled:NO forSegmentAtIndex:1];
        
        [segmentControl release];
        [segmentBarItem release];

    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // strings
    
    NSString *edition = libItem.edition;
    NSString *pubYear = [libItem.publisher length] ? [NSString stringWithFormat:@"%@ %@", libItem.publisher, libItem.year] : libItem.year;
	NSString *formatDetails = [NSString string];
	if (([libItem.formatDetail length] > 0) && ([libItem.typeDetail length] > 0))
		formatDetails = [NSString stringWithFormat:@"%@: %@", libItem.formatDetail, libItem.typeDetail];
	else if (([libItem.formatDetail length] == 0) && ([libItem.typeDetail length] > 0))
		formatDetails = [NSString stringWithFormat:@"%@", libItem.typeDetail];
	else if (([libItem.formatDetail length] > 0) && ([libItem.typeDetail length] == 0))
		formatDetails = [NSString stringWithFormat:@"%@", libItem.formatDetail];
	
    NSString *itemTitle = displayImage ? [NSString stringWithFormat:@"%@\nHOLLIS # %@", libItem.title, libItem.itemId] : libItem.title;
    
    // title label
	
	CGFloat runningYDispacement = 0.0;
	CGFloat titleHeight = [itemTitle sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
                                constrainedToSize:CGSizeMake(300, 2000)         
                                    lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 10.0, 300.0, titleHeight)];
	
	runningYDispacement += titleHeight;
	
	titleLabel.text = itemTitle;
	titleLabel.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	titleLabel.textColor = [UIColor colorWithHexString:@"#1a1611"];
	titleLabel.backgroundColor = [UIColor clearColor];	
	titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	titleLabel.numberOfLines = 10;
	
	
	CGFloat authorHeight = [libItem.author sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:15]
                                      constrainedToSize:CGSizeMake(190, 20)         
                                          lineBreakMode:UILineBreakModeWordWrap].height;
	
	UnderlinedUILabel *authorLabel = [[UnderlinedUILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 190.0, authorHeight)];
	
	UIButton * authorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	authorButton.frame = CGRectMake(12.0, 20 + runningYDispacement, 190.0, authorHeight);
	[authorButton addTarget:self action:@selector(authorLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
	authorButton.enabled = YES;
	
	if (authorHeight >= 20)
		runningYDispacement += authorHeight;
	
	else {
		runningYDispacement += 20;
	}

	authorLabel.text = libItem.author;
	authorLabel.font = [UIFont fontWithName:COURSE_NUMBER_FONT size:14];
	authorLabel.textColor = [UIColor colorWithHexString:@"#8C000B"]; 
	authorLabel.backgroundColor = [UIColor clearColor];	
	authorLabel.lineBreakMode = UILineBreakModeTailTruncation;
	authorLabel.numberOfLines = 1;
	

	bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 105.0 , runningYDispacement - 10, 50.0, 50.0);
	bookmarkButton.enabled = YES;
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateSelected];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[bookmarkButton addTarget:self action:@selector(bookmarkButtonToggled:) forControlEvents:UIControlEventTouchUpInside];
    
    bookmarkButtonIsOn = bookmarkButton.selected = [libItem.isBookmarked boolValue];
	
	mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
	mapButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , runningYDispacement - 10, 50.0, 50.0);
	mapButton.enabled = YES;
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png"] forState:UIControlStateNormal];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it-pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png-pressed"] forState:UIControlStateSelected];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png-pressed"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[mapButton addTarget:self action:@selector(mapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	UIView * headerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	
	[headerView addSubview:titleLabel];
	[headerView addSubview:authorLabel];
	[headerView addSubview:authorButton];
    [headerView addSubview:mapButton];
	[headerView addSubview:bookmarkButton];
    
    UIFont *labelFont = [UIFont fontWithName:STANDARD_FONT size:13];
    for (NSString *labelText in [NSArray arrayWithObjects:edition, pubYear, formatDetails, nil]) {
        if ([labelText length]) {
            CGFloat detailHeight = [labelText sizeWithFont:labelFont].height;
            UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 20 + runningYDispacement, 190, detailHeight)];
            runningYDispacement += detailHeight;
            detailLabel.text = labelText;
            detailLabel.font = labelFont;
            detailLabel.backgroundColor = [UIColor clearColor];
            detailLabel.lineBreakMode = UILineBreakModeTailTruncation;
            [headerView addSubview:detailLabel];
        }
    }
    headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, 10 + runningYDispacement);
	
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];    
	thumbnail = [[UIView alloc] initWithFrame:CGRectMake((screenRect.size.width - 150.0) / 2, headerView.frame.size.height, 150.0, 150.0)];
	thumbnail.backgroundColor = [UIColor clearColor];
    
	if (displayImage == YES){
		[self addLoadingIndicator:thumbnail];
		bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , bookmarkButton.frame.origin.y, 50.0, 50.0);
        headerView.frame = CGRectMake(0, 0, headerView.frame.size.width, thumbnail.frame.origin.y + thumbnail.frame.size.height);
		[headerView addSubview:thumbnail];
	}
	else{
		if (nil != thumbnail){
			[thumbnail removeFromSuperview];
            [thumbnail release];
			thumbnail = nil;
		}
	}
	
	//self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height)] autorelease];
	//[self.tableView.tableHeaderView addSubview:headerView];
    self.tableView.tableHeaderView = headerView;
}


#pragma mark User Interaction

-(void) thumbNailPressed: (id) sender {
	
	if (nil != fullImageLink)
		if([fullImageLink length] > 0){
			
			NSString *url = fullImageLink;
			
			NSURL *libURL = [NSURL URLWithString:url];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
		}
	
}

-(void) authorLinkTapped:(id)sender{
	NSArray *viewControllerArray = [self.navigationController viewControllers];
	NSUInteger parentViewControllerIndex = [viewControllerArray count] - 2;
	DLog(@"Parent view controller: %@", [viewControllerArray objectAtIndex:parentViewControllerIndex]);
	DLog(@"Total vc: %d", [viewControllerArray count]);
	
	if ([sender isKindOfClass:[UIButton class]]){
		
		if ([libItem.author length]) {
			
			LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
			vc.title = @"Search Results";
			
			apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:vc];
			BOOL requestWasDispatched = [apiRequest requestObjectFromModule:@"libraries"
														command:@"search"
													 parameters:[NSDictionary dictionaryWithObjectsAndKeys:libItem.author, @"author", nil]];
			
			if (requestWasDispatched) {
				vc.searchTerms = libItem.author;
				
				// break the navigation stack and only have the springboard, library-home and the next vc
				UIViewController * rootVC = [[self.navigationController viewControllers] objectAtIndex:0];
				UIViewController * nextVC = [[self.navigationController viewControllers] objectAtIndex:1];
				
				NSArray *controllersArray = [NSArray arrayWithObjects: rootVC, nextVC, vc,nil];
				
				[self.navigationController setViewControllers:controllersArray animated:YES];
				
			}
			
			[vc release];
		}
	}
}


-(void) showNextLibItem: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([[libItemDictionary allKeys] count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentIndex - 1;
			}
			else
				tempLibIndex = currentIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [[libItemDictionary allKeys] count])){
				
				LibraryItem *nextLibItem = (LibraryItem *)[libItemDictionary objectForKey:[NSString stringWithFormat:@"%d", tempLibIndex +1]];
                if (nextLibItem) {
                    if (!nextLibItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
                        [[LibraryDataManager sharedManager] requestDetailsForItem:nextLibItem];
                    }
                    currentIndex = tempLibIndex;
                    [libItem release];
                    libItem = [nextLibItem retain];
                    displayImage = [libItem.formatDetail isEqualToString:@"Image"];
                    [self setupLayout];
                }
                
                [locationsWithItem release];
                locationsWithItem = nil;
                
                if (!libItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
                    [[LibraryDataManager sharedManager] requestDetailsForItem:libItem];
                } else {
                    [self detailsDidLoadForItem:libItem];
                }
                if (![[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
                    [[LibraryDataManager sharedManager] requestFullAvailabilityForItem:libItem.itemId];
                }
                
                [self.tableView reloadData];
			}			
		}
	}	
	
}

-(void) mapButtonPressed: (id) sender {
	
	if ([displayLibraries count] > 0) {
		LibraryLocationsMapViewController * vc = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.view.frame];
	
        [vc setAllLibraryLocations:displayLibraries];
		vc.navController = self;
		
		vc.title = @"Locations with Item";
		
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	 }
	
}


-(void) bookmarkButtonToggled: (id) sender {
	
	
	BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@",libItem.itemId];
	LibraryItem *alreadyInDB = (LibraryItem *)[[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
	
	if (nil == alreadyInDB){
		return;
	}
	
	if (newBookmarkButtonStatus) {
		bookmarkButton.selected = YES;
		alreadyInDB.isBookmarked = [NSNumber numberWithBool:YES];
	}
	
	else {
		bookmarkButton.selected = NO;
		alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
	}
	
	[CoreDataManager saveData];
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 1;
		
		return 0;
	}
	
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 1;
			
		return 0;
	}
	
	/*
	if (section == 0) {
		BOOL val = [libItem.isOnline boolValue];
		if (val == YES) {
			return 1;
		}
		else {
			return 0;
		}
	}
	
	else */ if (section == 1){
		if ([locationsWithItem count] == 0)
			return 1;
		
		return [locationsWithItem count];
	}
	
	return 0;
		
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell"; // for single-row cells
    
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink ){
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.text = @"View more details";
			cell.accessoryView =  [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			return cell;
		}
		
		return nil;
	}
	
	if (indexPath.section == 0) {
		/*
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		BOOL val = [libItem.isOnline boolValue];
		if (val == YES) {
			cell.textLabel.text = @"Available Online";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			cell.textLabel.text = @"Not Available Online";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}

		return cell;
        */
        return nil;
	}
	
	else if (indexPath.section == 1) {
        
        if (![locationsWithItem count]) {
			UITableViewCell *cell4 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell4 == nil) {
				cell4 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}
            if (locationsWithItem == nil) {
                // TODO: this is not aligned well.
                // also we should probably make this into a reusable cell type instead of an instance method.
                [self addLoadingIndicator:cell4];
            } else {
                cell4.textLabel.text = @"data unavailable";
                cell4.selectionStyle = UITableViewCellSelectionStyleNone;
            }
			return cell4;
        }
        
		// cell for availability listings
		
		static NSString *CellIdentifier1 = @"CellLib";
        
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];
        
		NSArray * collections = (NSArray *)[tempDict objectForKey:@"collection"];
        // TODO: is there a good reason for using just the last collection?
        NSDictionary *collectionDict = [collections lastObject];
		
		NSMutableDictionary * dictWithStatuses = [NSMutableDictionary dictionary];

        if (collectionDict) {
			
			NSArray * itemsByStat = (NSArray *)[collectionDict objectForKey:@"itemsByStat"];
			
			for (NSDictionary * statDict in itemsByStat) {
				NSString * statMain = [statDict objectForKey:@"statMain"];
				
				int availCount = [[statDict objectForKey:@"availCount"] intValue];
				int unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
				int checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
				int requestCount = [[statDict objectForKey:@"requestCount"] intValue] + [[statDict objectForKey:@"scanAndDeliverCount"] intValue];
				int collectionOnlyCount = [[statDict objectForKey:@"collectionOnlyCount"] intValue];
				
				int totalItems = availCount + unavailCount + checkedOutCount + collectionOnlyCount;
				
				NSString * status;
				
				if (availCount > 0)
					status = @"available";
				else if (checkedOutCount > 0 || requestCount > 0)
					status = @"request";
				else
					status = @"unavailable";
				
				NSString * statusDetailString = [NSString stringWithFormat:
												 @"%d of %d available - %@", availCount, totalItems, statMain];
				
				if (collectionOnlyCount > 0)
					statusDetailString = [NSString stringWithFormat:
										  @"0 of %d may be available", collectionOnlyCount];
				
				if ((totalItems > 0) || (requestCount > 0))
					[dictWithStatuses setObject:status forKey:statusDetailString];
			}
            
            if (![dictWithStatuses count]) {
				[dictWithStatuses setObject:@"unavailable" forKey:@"none available"];
            }
            
		}
        

		
		NSString * libName = [tempDict objectForKey:@"name"];
        
        DLog(@"%@", libName);
        DLog(@"%@", [[dictWithStatuses allKeys] description]);

        Library *theLibrary = nil;
        // TODO: we can already get the library from locationsWithItem
        // displayLibraries is mostly redundant and each use of it can be replaced
        for (LibraryAlias *alias in displayLibraries) {
            if ([alias.name isEqualToString:libName]) {
                theLibrary = alias.library;
                break;
            }
        }
        
        UITableViewCell *cell1 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell1 == nil) {
            cell1 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        }
        cell1.textLabel.text = nil;
        
        CGFloat accessoryAdjustment;
        CGFloat cellWidth = tableView.frame.size.width - 20; // assume 10px padding left and right
        
        // accessory view
        NSArray * itemsByStat = (NSArray *)[collectionDict objectForKey:@"itemsByStat"];
        if (![itemsByStat count]) {
            cell1.accessoryType = UITableViewCellAccessoryNone;
            cell1.selectionStyle = UITableViewCellSelectionStyleNone;
            accessoryAdjustment = 0;
        } else {
            cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell1.selectionStyle = UITableViewCellSelectionStyleGray;
            accessoryAdjustment = 30;
        }
        
        // "text label"

        UIFont *textFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        CGSize size = [libName sizeWithFont:textFont];
        CGRect frame = CGRectMake(10, 10, cellWidth, size.height);
        UILabel *textLabel = (UILabel *)[cell1.contentView viewWithTag:21];
        if (!textLabel) {
            textLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            textLabel.tag = 21;
            [cell1.contentView addSubview:textLabel];
        } else {
            textLabel.frame = frame;
        }
        textLabel.text = libName;
        
        // "detail text label"
        
        UIColor *detailTextColor = [UIColor colorWithHexString:@"#554C41"];
        UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        
        frame.origin.y += frame.size.height + 2;
        size = [libName sizeWithFont:detailTextFont]; // just want height of one line
        frame.size.width = cellWidth - accessoryAdjustment;
        frame.size.height = (size.height + 2) * ([dictWithStatuses count] + (theLibrary && nil != currentLocation && [theLibrary.lat doubleValue]) ? 1 : 0);
        
        UIView *otherLabels = [cell1.contentView viewWithTag:22];
        [otherLabels removeFromSuperview];
        
        otherLabels = [[[UIView alloc] initWithFrame:frame] autorelease];
        otherLabels.tag = 22;
        [cell1.contentView addSubview:otherLabels];
        
        frame = CGRectMake(0, 0, otherLabels.frame.size.width, size.height + 3);
        
        if (theLibrary && nil != currentLocation) {
            CGFloat latitude = [theLibrary.lat doubleValue];
            CGFloat longitude = [theLibrary.lon doubleValue];
            
            if (latitude != 0) {
                CLLocation * libLoc = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
                CLLocationDistance dist = [currentLocation distanceFromLocation:libLoc];
                if (dist >= 0) {
                    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
                    label.backgroundColor = [UIColor clearColor];
                    label.font = detailTextFont;
                    label.textColor = detailTextColor;
                    label.text = [NSString stringWithFormat:@"%@ away", [self textForDistance:dist]];
                    [otherLabels addSubview:label];
                    
                    frame.origin.y += frame.size.height;
                }
            }
		}
        
        for (NSString *statusString in [dictWithStatuses allKeys]) {
            NSString *itemStatus = [dictWithStatuses objectForKey:statusString];
            NSString * imageString;
            
            if ([itemStatus isEqualToString:@"available"]) {
                imageString = @"dining/dining-status-open@2x.png";
            }
            else if ([itemStatus isEqualToString:@"unavailable"]) {
                imageString = @"dining/dining-status-closed@2x.png";
            }
            else 
                imageString = @"dining/dining-status-open-w-restrictions@2x.png";
            
            UIImage *image = [UIImage imageNamed:imageString];
            UIImageView *imView = [[[UIImageView alloc] initWithImage:image] autorelease];
            imView.frame = CGRectMake(0, frame.origin.y, 20, frame.size.height);
            
            [otherLabels addSubview:imView];
            
            frame.origin.x = imView.frame.size.width + 5;
            frame.size.width = cellWidth - frame.origin.x - accessoryAdjustment;
            
            UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
            label.text = statusString;
            label.font = detailTextFont;
            label.textColor = detailTextColor;
            label.backgroundColor = [UIColor clearColor];
            [otherLabels addSubview:label];
            
            frame.origin.y += frame.size.height;
        }
		
		return cell1;
	}
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 42;
		
		return 0;
	}
    
    static NSString *oneLine = @"oneLine";

    NSInteger height = 0;

    // one line for library name label
    UIFont *textFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGSize size = [oneLine sizeWithFont:textFont];
    height += size.height;
    
    // detail labels...
    UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
    size = [oneLine sizeWithFont:detailTextFont];
    
    if (indexPath.section == 0 || ![locationsWithItem count]) {
        return tableView.rowHeight;
        
    } else { // section 1
        
        NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];    
        NSArray * collections = (NSArray *)[tempDict objectForKey:@"collection"];
        // TODO: see comment in -tableView:cellForRow...
        NSDictionary *collectionDict = [collections lastObject]; // may be nil
        NSArray * itemsByStat = (NSArray *)[collectionDict objectForKey:@"itemsByStat"]; // may be nil
        NSInteger numberOfStatusLines = 0;
        if (![itemsByStat count]) {
            numberOfStatusLines = 1;
        } else {
            for (NSDictionary * statDict in itemsByStat) {
                if ([[statDict objectForKey:@"availCount"] intValue]
                 || [[statDict objectForKey:@"unavailCount"] intValue]
                 || [[statDict objectForKey:@"checkedOutCount"] intValue]
                 || [[statDict objectForKey:@"requestCount"] intValue]
                 || [[statDict objectForKey:@"scanAndDeliverCount"] intValue]
                 || [[statDict objectForKey:@"collectionOnlyCount"] intValue])
                {
                    numberOfStatusLines++;
                }
            }
            if (numberOfStatusLines == 0) numberOfStatusLines = 1;
        }
        
        NSString * libName = [tempDict objectForKey:@"name"];
        Library *theLibrary = nil;
        for (LibraryAlias *alias in displayLibraries) {
            if ([alias.name isEqualToString:libName]) {
                theLibrary = alias.library;
                break;
            }
        }
        NSInteger numberOfDistanceLines = (theLibrary && nil != currentLocation && [theLibrary.lat doubleValue]) ? 1 : 0;
        
        NSLog(@"%@ %d %d", libName, numberOfStatusLines, numberOfDistanceLines);
        
        height += (size.height + 2) * (numberOfStatusLines + numberOfDistanceLines);
        
        return height + 22; // for top and bottom padding
    }
}



#pragma mark -
#pragma mark Table view delegate
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink ){
			DLog(@"cat link = %@",libItem.catalogLink); 
			NSString * url = libItem.catalogLink;
			
			//url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
			NSURL *urlToOpen = [NSURL URLWithString:url];
			if (urlToOpen && [[UIApplication sharedApplication] canOpenURL:urlToOpen]) {
				[[UIApplication sharedApplication] openURL:urlToOpen];
			}
		}
		
		return ;
	}
	
	if (indexPath.section == 0){
		/*
		BOOL val = [libItem.isOnline boolValue];
		if (val == YES) {
			
			NSString *url = libItem.onlineLink;
			
			NSURL *libURL = [NSURL URLWithString:url];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
		}
        */
	}
	
	
	if ([locationsWithItem count]) {

		NSDictionary * libDict = [locationsWithItem objectAtIndex:indexPath.row];		
		NSArray * collections = (NSArray *)[libDict objectForKey:@"collection"];
	
		BOOL tappable = NO;
		for (NSDictionary * collectionDict in collections){
			NSArray * itemsByStat = (NSArray *)[collectionDict objectForKey:@"itemsByStat"];
            if ([itemsByStat count]) {
                tappable = YES;
                break;
            }
		}
	
		if (tappable && ([collections count] > 0) && (indexPath.section == 1)) {
            
            NSString * libName = [libDict objectForKey:@"name"];
            NSString * libId = [libDict objectForKey:@"id"];
            NSString * type = [libDict objectForKey:@"type"];
            NSString * primaryName = [((NSDictionary *)[libDict objectForKey:@"details"]) objectForKey:@"primaryName"];
            
            // create library if it doesn't exist already
            Library *library = [[LibraryDataManager sharedManager] libraryWithID:libId type:type primaryName:primaryName];
            library.type = type;
            
            LibraryAlias *alias = [[LibraryDataManager sharedManager] libraryAliasWithID:libId type:type name:libName];
            ItemAvailabilityDetailViewController *vc = [[ItemAvailabilityDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
			vc.title = @"Availability";
            vc.libraryItem = libItem;
            vc.libraryAlias = alias;
            vc.availabilityCategories = collections;
            vc.arrayWithAllLibraries = locationsWithItem;
            vc.currentIndex = indexPath.row;
            
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
    }
		
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
	locationManager.delegate = nil;
	[locationManager release];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[LibraryDataManager sharedManager] unregisterItemDelegate:self];

	locationManager.delegate = nil;
	[locationManager release];
	
    [super dealloc];
}


#pragma mark -
#pragma mark JSONAPIRequest Delegate function 



- (void)availabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)availabilityData {
    [locationsWithItem release];
    locationsWithItem = [availabilityData retain];
    
    [displayLibraries removeAllObjects];
    
    for (NSDictionary * tempDict in availabilityData) {
        NSString * displayName = [tempDict objectForKey:@"name"];
        NSString * identityTag = [tempDict objectForKey:@"id"];
        NSString * type = [tempDict objectForKey:@"type"];
    
        LibraryAlias *alias = [[LibraryDataManager sharedManager] libraryAliasWithID:identityTag type:type name:displayName];
        [displayLibraries addObject:alias];
    }
    
    [self.tableView reloadData];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    [locationManager startUpdatingLocation];
    
    [self removeLoadingIndicator];
}

- (void)availabilityFailedToLoadForItemID:(NSString *)itemID {
    [locationsWithItem release];
    locationsWithItem = [[NSArray alloc] init];
    
    [self removeLoadingIndicator];
}

- (void)detailsDidLoadForItem:(LibraryItem *)aLibItem {

    if (![libItem.itemId isEqualToString:aLibItem.itemId]) {
        return;
    }
    
    [self removeLoadingIndicator];

    if (libItem != aLibItem) {
        [libItem release];
        libItem = [aLibItem retain];
    }
    
    if (aLibItem.formatDetail && [[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
        UIImage *image = [aLibItem thumbnailImage];
        if (image) {
            
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
            if (image.size.width > 160 || image.size.height > 160) {
                imageView.contentMode = UIViewContentModeScaleAspectFit;
            } else {
                imageView.contentMode = UIViewContentModeCenter;
            }
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            imageView.frame = CGRectMake(0, 0, 160, 160);
            imageView.backgroundColor = [UIColor clearColor];
            imageView.image = image;
            
            CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
            
            CGFloat imageX = (screenRect.size.width - imageView.frame.size.width) / 2;
            CGFloat imageY = thumbnail.frame.origin.y;
            CGFloat bottomY = imageY + (imageView.frame.size.height - image.size.height) / 2 + image.size.height;
            
            thumbnail.frame = CGRectMake(imageX, imageY, imageView.frame.size.width, imageView.frame.size.height);
            
            UIButton * customButton = [UIButton buttonWithType:UIButtonTypeCustom];
            customButton.frame = CGRectMake(imageX+image.size.width-15, bottomY - 20, 30, 30);  // a little higher so text fits
            customButton.enabled = YES;
            [customButton setImage:[UIImage imageNamed:@"global/searchfield_star.png"] forState:UIControlStateNormal];
            [customButton addTarget:self action:@selector(thumbNailPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            [thumbnail addSubview:imageView];
            
            UILabel * count = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, bottomY + 10, screenRect.size.width, 20)] autorelease];
            count.text = [NSString stringWithFormat:@"Total Images: %d", [aLibItem.numberOfImages integerValue]];
            count.font = [UIFont fontWithName:COURSE_NUMBER_FONT size:14];
            count.textAlignment = UITextAlignmentCenter;
            count.textColor = [UIColor blackColor]; 
            count.backgroundColor = [UIColor clearColor];	
            count.lineBreakMode = UILineBreakModeTailTruncation;
            count.numberOfLines = 1;
            
            CGFloat newHeight = self.tableView.tableHeaderView.frame.size.height - 150.0 + thumbnail.frame.size.height + count.frame.size.height + 5;
            self.tableView.tableHeaderView.frame = CGRectMake(0, 0, self.tableView.tableHeaderView.frame.size.width, newHeight);
            
            if (![thumbnail isDescendantOfView:self.tableView.tableHeaderView]) {
                [self.tableView.tableHeaderView addSubview:thumbnail];
            }
            [self.tableView.tableHeaderView addSubview:customButton];
            [self.tableView.tableHeaderView addSubview:count];
            [self.tableView setTableHeaderView:self.tableView.tableHeaderView]; // force resize of header
        }
        [self.tableView reloadData];
    } else {
        [self setupLayout];
    }
}

- (void)detailsFailedToLoadForItemID:(NSString *)itemID {
}

- (void)libraryDetailsDidLoad:(NSNotification *)aNotification {
    [self.tableView reloadData];
}


#pragma mark loading-indicator
- (void)addLoadingIndicator:(UIView *)view
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Checking availability...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = view.frame.size.height/2 - 5;
        CGFloat horizontalPadding = 5.0; //view.frame.size.width/2 - 50;
        CGFloat horizontalSpacing = 15.0;
		// CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		// spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(horizontalPadding, verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding + horizontalSpacing, verticalPadding -10, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(20.0, 5.0, view.frame.size.width/2 - 20, 0.8*view.frame.size.height - 5)];
		
		if (displayImage == YES) {
			loadingIndicator.frame = CGRectMake(20.0, 5.0, view.frame.size.width/3, 0.8*view.frame.size.height - 5);
			label.frame = CGRectMake(horizontalPadding + horizontalSpacing - 30, verticalPadding -10, stringSize.width, stringSize.height + 2.0);
			spinny.center = CGPointMake(horizontalPadding - 30, verticalPadding);
			[loadingIndicator setBackgroundColor:[UIColor clearColor]];
		}
		
		else
			[loadingIndicator setBackgroundColor:[UIColor whiteColor]];
		
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
		
	}
	
	
	[view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
	[loadingIndicator release];
	loadingIndicator = nil;
	
}


#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 120.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
  
    [currentLocation release];
	currentLocation = [newLocation retain];
    
    DLog(@"current location is %@", [currentLocation description]);
    
	[locationManager stopUpdatingLocation];
	[self.tableView reloadData];

}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
	currentLocation = nil;
	[locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"could not update location");
    
	currentLocation = nil;
	[locationManager stopUpdatingLocation];

#if TARGET_IPHONE_SIMULATOR
    CLLocationCoordinate2D coord;
    switch (arc4random() % 3) {
        case 0:
            NSLog(@"we are in kendall square");
            coord.latitude = 42.3629;
            coord.longitude = -71.0862;
            break;
        case 1:
            NSLog(@"we are in alewife");
            coord.latitude = 42.3948;
            coord.longitude = -71.1446;
            break;
        default:
            NSLog(@"we are nowhere");
            break;
    }
    
    if (coord.latitude) {
        currentLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        [self.tableView reloadData];
    }
#endif
}

- (NSString *)textForDistance:(CLLocationDistance)meters {
    NSString *measureSystem = [[NSLocale currentLocale] objectForKey:NSLocaleMeasurementSystem];
    BOOL isMetric = ![measureSystem isEqualToString:@"U.S."];
    
    NSString *distanceString;

    if (!isMetric) {
        CGFloat feet = meters / METERS_PER_FOOT;
        if (feet * 2 > FEET_PER_MILE) {
            distanceString = [NSString stringWithFormat:@"%.1f miles", (feet / FEET_PER_MILE)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f feet",feet];
        }
    } else {
        if (meters > 1000) {
            distanceString = [NSString stringWithFormat:@"%.1f km", (meters / 1000)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f meters", meters];
        }
    }
    
    return distanceString;
}

@end

