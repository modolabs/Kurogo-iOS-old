//
//  ItemAvailabilityDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/6/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "ItemAvailabilityDetailViewController.h"
#import "MITUIConstants.h"
#import "RequestWebViewModalViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "LibrariesMultiLineCell.h"
#import "LibraryAlias.h"
#import "LibraryDetailViewController.h"

@implementation ItemAvailabilityDetailViewController
@synthesize parentViewApiRequest;
@synthesize libraryItem;
@synthesize libraryAlias;
@synthesize availabilityCategories;
@synthesize arrayWithAllLibraries;
@synthesize currentIndex;
@synthesize openToday;
@synthesize tableCells;

#pragma mark -
#pragma mark View lifecycle

-(void) setupLayout {
	UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																					[UIImage imageNamed:MITImageNameUpArrow],
																					[UIImage imageNamed:MITImageNameDownArrow], nil]];
	[segmentControl setMomentary:YES];
	[segmentControl addTarget:self action:@selector(showNextLibrary:) forControlEvents:UIControlEventValueChanged];
	segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	
	if (currentIndex == 0)
		[segmentControl setEnabled:NO forSegmentAtIndex:0];
	
	if (currentIndex == [arrayWithAllLibraries count] - 1)
		[segmentControl setEnabled:NO forSegmentAtIndex:1];
	
	[segmentControl release];
	[segmentBarItem release];
	
	
	headerView = nil; 

    NSString *nameToDisplay;
    if (![libraryAlias.name isEqualToString:libraryAlias.library.primaryName] && [libraryAlias.library.primaryName length]) {
        nameToDisplay = [NSString stringWithFormat:@"%@ (%@)", libraryAlias.name, libraryAlias.library.primaryName];
    } else {
        nameToDisplay = libraryAlias.name;
    }
	
    UIFont *libNameFont = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
    UIFont *openTodayFont = [UIFont fontWithName:COURSE_NUMBER_FONT size:13];
    
    // TODO: this width should be calculated from the view frame width minus
    // the size of the info button and associated padding/margins.
	CGFloat height1 = [nameToDisplay sizeWithFont:libNameFont constrainedToSize:CGSizeMake(250, 2000)         
                                    lineBreakMode:UILineBreakModeWordWrap].height;
						
	CGFloat height2 = [openToday sizeWithFont:openTodayFont constrainedToSize:CGSizeMake(250, 20)         
                                lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height = height1 + height2;
    
    // TODO: rename these label variables so the code is easier to read
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 9.0, 250, height1)];

	height1 += 9.0;
	
	label.text = nameToDisplay;
	label.font = libNameFont;
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 10;
	
	NSString * openTodayString;
	if (nil == openToday)
		openTodayString = @"";
	else {
		openTodayString = openToday;
	}

	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height1, 250, height2)];
	label2.text = openTodayString;
	label2.font = openTodayFont;
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	//label2.lineBreakMode = UILineBreakModeWordWrap;
	//label2.numberOfLines = 1;
	
	infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
	infoButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , 5, 50.0, 50.0);
	infoButton.enabled = YES;
	[infoButton setImage:[UIImage imageNamed:@"global/info_button.png"] forState:UIControlStateNormal];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:UIControlStateSelected];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	
	if (height < 50)
		height = 50;
	
	headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 5.0)] autorelease];
	[headerView addSubview:label];
	[headerView addSubview:label2];
	[headerView addSubview:infoButton];
	
	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 5)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
	
	[label2 release];
	[label release];
    
	limitedView = YES;
}

- (void)processAvailabilityData {

    NSLog(@"%d collections", [availabilityCategories count]);
    //DLog(@"%@", [availabilityCategories description]);

    NSMutableArray *mutableTableCells = [NSMutableArray array];
    
    for (NSDictionary *aCollection in availabilityCategories) {

        NSString * displayType = [aCollection objectForKey:@"displayType"];
        NSLog(@"section type %@", displayType);
        
        NSString *collectionCallNumber = [aCollection objectForKey:@"collectionCallNumber"];
        NSArray *itemListsByAvailability = [aCollection objectForKey:@"itemsByStat"];

        NSArray *statusNames = [NSArray arrayWithObjects:@"availableItems", @"checkedOutItems", @"unavailableItems", nil];
        NSArray *statusDisplays = [NSArray arrayWithObjects:@"Available", @"Checked out", @"Unavailable", nil];
        NSArray *statusImages = [NSArray arrayWithObjects:
                                 @"dining/dining-status-open.png",
                                 @"dining/dining-status-open-w-restrictions.png",
                                 @"dining/dining-status-closed.png", nil];
        
        BOOL uniformHoldingStatus = YES;
        //BOOL uniformHoldingStatus = NO;
        BOOL uniformCallNumber = YES;
        
        // we will end up throwing away two out of three of these arrays
        NSMutableArray *cellsForGroups = [NSMutableArray array];
        NSMutableArray *cellsForHoldings = [NSMutableArray array];
        NSMutableArray *cellsForIndividualItems = [NSMutableArray array];
        
        for (NSDictionary *availabilityDict in itemListsByAvailability) {
            // special case for collection-only items
            if ([[availabilityDict objectForKey:@"collectionOnlyCount"] integerValue]) {
                NSDictionary *cellInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Contact library/archive", @"text", nil];
                [cellsForGroups addObject:cellInfo];
                continue;
            }
            
            for (NSInteger i = 0; i < 3; i++) {

                NSString *groupScanURL = nil;
                NSString *groupRequestURL = nil;
                BOOL groupTappable = NO;
                
                NSString *availabilityStatus = [statusNames objectAtIndex:i];
                NSString *statusLabel = [statusDisplays objectAtIndex:i];
                NSString *statusImage = [statusImages objectAtIndex:i];
                NSArray *itemsForAvailability = [availabilityDict objectForKey:availabilityStatus];
                if (![itemsForAvailability count]) continue;
                
                NSMutableDictionary *cellsByHoldingStatus = [NSMutableDictionary dictionary];
                
                for (NSDictionary *availItemDict in itemsForAvailability) {
                    
                    NSString *callNumber = [availItemDict objectForKey:@"callNumber"];
                    NSString *holdingStatus = [availItemDict objectForKey:@"statMain"];
                    NSString *requestURL = nil;
                    NSString *scanURL = nil;
                    NSString *description = [availItemDict objectForKey:@"description"];
                    if ([description length]) {
                        callNumber = [NSString stringWithFormat:@"%@ - %@", description, callNumber];
                    }
                    
                    if (![callNumber isEqualToString:collectionCallNumber]) {
                        //NSLog(@"collection: '%@'", collectionCallNumber);
                        //NSLog(@" this item: '%@'", callNumber);
                        uniformCallNumber = NO;
                    }
                    
                    // keep populating cells by holding status until we find out call numbers are different
                    NSMutableDictionary *cellForHoldingStatus = nil;
                    if (uniformCallNumber) {
                        cellForHoldingStatus = [cellsByHoldingStatus objectForKey:holdingStatus];
                        if (!cellForHoldingStatus) {
                            cellForHoldingStatus = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    [statusLabel lowercaseString], @"text",
                                                    holdingStatus, @"holdingStatus",
                                                    statusImage, @"image",
                                                    [NSNumber numberWithInt:1], @"statusCount",
                                                    nil];
                            [cellsByHoldingStatus setObject:cellForHoldingStatus forKey:holdingStatus];
                        } else {
                            NSInteger numberOfCells = [[cellForHoldingStatus objectForKey:@"statusCount"] integerValue];
                            numberOfCells++;
                            [cellForHoldingStatus setObject:[NSNumber numberWithInt:numberOfCells] forKey:@"statusCount"];
                        }
                    }
                    
                    NSMutableDictionary *cellInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     statusLabel, @"text",
                                                     callNumber, @"callNumber",
                                                     holdingStatus, @"holdingStatus",
                                                     statusImage, @"image",
                                                     nil];
                    
                    
                    BOOL canRequest = [[availItemDict objectForKey:@"canRequest"] isEqualToString:@"YES"];
                    BOOL canScanAndDeliver = [[availItemDict objectForKey:@"canScanAndDeliver"] isEqualToString:@"YES"];

                    // tappable might not be necessary
                    BOOL tappable = canRequest || canScanAndDeliver;
                    if (tappable) {
                        groupTappable = YES;
                        [cellInfo setObject:[NSNumber numberWithBool:tappable] forKey:@"tappable"];
                        [cellForHoldingStatus setObject:[NSNumber numberWithBool:YES] forKey:@"tappable"];
                    }
                    
                    if (canRequest) {
                        requestURL = [availItemDict objectForKey:@"requestUrl"];
                        [cellInfo setObject:requestURL forKey:@"requestURL"];
                        if (uniformCallNumber)
                            [cellForHoldingStatus setObject:requestURL forKey:@"requestURL"];
                        groupRequestURL = requestURL;
                    }
                    
                    if (canScanAndDeliver) {
                        scanURL = [availItemDict objectForKey:@"scanAndDeliverUrl"];
                        [cellInfo setObject:scanURL forKey:@"scanURL"];
                        if (uniformCallNumber)
                            [cellForHoldingStatus setObject:scanURL forKey:@"scanURL"];
                        groupScanURL = scanURL;
                    }
                    
                    [cellsForIndividualItems addObject:cellInfo];
                }
                
                if ([cellsByHoldingStatus count] > 1) {
                    uniformHoldingStatus = NO;
                }
                
                for (NSString *holdingStatus in [cellsByHoldingStatus allKeys]) {
                    [cellsForHoldings addObject:[cellsByHoldingStatus objectForKey:holdingStatus]];
                }
                
                // keep populating cells by availability until either holding status or call numbers are different
                if (uniformCallNumber && uniformHoldingStatus) {
                    NSString *text = [NSString stringWithFormat:@"%d %@", [itemsForAvailability count], [statusLabel lowercaseString]];
                    NSMutableDictionary *cellInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     text, @"text",
                                                     statusImage, @"image",
                                                     [NSNumber numberWithBool:groupTappable], @"tappable",
                                                     nil];
                    
                    if (groupScanURL)    [cellInfo setObject:groupScanURL forKey:@"scanURL"];
                    if (groupRequestURL) [cellInfo setObject:groupRequestURL forKey:@"requestURL"];
                    
                    [cellsForGroups addObject:cellInfo];
                }
            }
        }
        
        if (uniformCallNumber) {
            if (uniformHoldingStatus) {
                NSLog(@"type 1, %d cells", [cellsForGroups count]);
                
                [mutableTableCells addObject:cellsForGroups];
            }
            else {
                NSLog(@"type 2, %d cells", [cellsForHoldings count]);
                
                [mutableTableCells addObject:cellsForHoldings];
            }
        } else {
            if (uniformHoldingStatus) {
                NSLog(@"type 3, %d cells", [cellsForIndividualItems count]);
                for (NSMutableDictionary *cellInfo in cellsForIndividualItems) {
                    [cellInfo removeObjectForKey:@"holdingStatus"];
                }
            }
            else {
                NSLog(@"type 4, %d cells", [cellsForIndividualItems count]);
            }

            [mutableTableCells addObject:cellsForIndividualItems];
        }
    } // end for (NSDictionary *aCollection in availabilityCategories)
    
    self.tableCells = [NSArray arrayWithArray:mutableTableCells];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *hrsToday = [[[LibraryDataManager sharedManager] scheduleForLibID:requestedLibID] objectForKey:@"hrsOpenToday"];
    
    if (hrsToday) {
        [self libraryDetailsDidLoad:nil];
        
    } else {
        if ([self.libraryAlias.library.type isEqualToString:@"library"]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraryDetail];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestArchiveDetail];
        }
        [[LibraryDataManager sharedManager] requestDetailsForLibType:self.libraryAlias.library.type libID:self.libraryAlias.library.identityTag libName:self.libraryAlias.name];
    }
    
	[self setupLayout];
    [self processAvailabilityData];
}

- (void)libraryDetailsDidLoad:(NSNotification *)aNotification {
    NSString *hrsToday = [[[LibraryDataManager sharedManager] scheduleForLibID:requestedLibID] objectForKey:@"hrsOpenToday"];
    
    if ([hrsToday isEqualToString:@"closed"]) {
        self.openToday = [NSString stringWithString:@"Closed Today"];
    } else {
        self.openToday = [NSString stringWithFormat: @"Open today from %@", hrsToday];
    }
    
    [self setupLayout];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self setupLayout];
	[self.tableView reloadData];
}



#pragma mark User Interaction


-(void)infoButtonPressed: (id) sender {    
    LibraryDetailViewController *vc = [[[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    vc.lib = self.libraryAlias;
	
    [self.navigationController pushViewController:vc animated:YES];
}
	

-(void) showNextLibrary: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([arrayWithAllLibraries count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentIndex - 1;
			}
			else
				tempLibIndex = currentIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [arrayWithAllLibraries count])){
				
				NSDictionary * tempDict = [arrayWithAllLibraries objectAtIndex:tempLibIndex];		
				NSString * libName = [tempDict objectForKey:@"name"];
				NSString * libId = [tempDict objectForKey:@"id"];
				NSString * typeTemp = [tempDict objectForKey:@"type"];
				
				NSArray * collections = (NSArray *)[tempDict objectForKey:@"collection"];
                
                currentIndex = tempLibIndex;
                self.libraryAlias = [[LibraryDataManager sharedManager] libraryAliasWithID:libId name:libName];

                [availabilityCategories release];
                availabilityCategories = [collections retain];
                
                [self setupLayout];
                [self.tableView reloadData];
			}			
		}
	}	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableCells count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *cellsForSection = [self.tableCells objectAtIndex:section];
    NSInteger cellCount = [cellsForSection count];
    if (cellCount <= 5 || !limitedView) {
        return [cellsForSection count];
    }
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (limitedView && indexPath.row == 5) {
        NSString *CellIdentifier = @"more";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
		cell.textLabel.text = @"      Show all items";
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.imageView.image = nil;
		return cell;
    }
    
    
    NSArray *cellsForSection = [self.tableCells objectAtIndex:indexPath.section];
    NSDictionary *cellInfo = [cellsForSection objectAtIndex:indexPath.row];
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    NSString *detailTextString = nil;
    
    NSMutableArray *detailTextLines = [NSMutableArray array];
    NSString *aLine = nil;
    if (aLine = [cellInfo objectForKey:@"callNumber"]) {
        [detailTextLines addObject:aLine];
    }
    if (aLine = [cellInfo objectForKey:@"holdingStatus"]) {
        [detailTextLines addObject:aLine];
    }
    
    if ([detailTextLines count]) {
        detailTextString = [detailTextLines componentsJoinedByString:@"\n"];
        cellStyle = UITableViewCellStyleSubtitle;
    }
    
    UITableViewCell *cell = nil;
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d", indexPath.section];
    if ([detailTextLines count] < 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:CellIdentifier] autorelease];
        }

    } else {
        LibrariesMultiLineCell *multiCell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (multiCell == nil) {
            multiCell = [[[LibrariesMultiLineCell alloc] initWithStyle:cellStyle reuseIdentifier:CellIdentifier] autorelease];
        }
        multiCell.detailTextLabel.numberOfLines = [detailTextLines count];
        cell = multiCell;
    }
    
    cell.textLabel.text = [cellInfo objectForKey:@"text"];
    cell.detailTextLabel.text = detailTextString;
    cell.imageView.image = [UIImage imageNamed:[cellInfo objectForKey:@"image"]];
    
    // chevron
    if ([cellInfo objectForKey:@"scanURL"] != nil || [cellInfo objectForKey:@"requestURL"] != nil) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (limitedView && indexPath.row == 5) {
        return tableView.rowHeight;
    }
    
    NSArray *cellsForSection = [self.tableCells objectAtIndex:indexPath.section];
    NSDictionary *cellInfo = [cellsForSection objectAtIndex:indexPath.row];
    
    CGFloat rowHeight = tableView.rowHeight;

    NSInteger numberOfExtraLines = 0;
    if ([cellInfo objectForKey:@"callNumber"] != nil)
        numberOfExtraLines++;
    if ([cellInfo objectForKey:@"holdingStatus"] != nil)
        numberOfExtraLines++;
    
    static NSString *oneLine = @"oneLine";
    if (numberOfExtraLines == 1) {
        UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        CGSize sizeOfOneLine = [oneLine sizeWithFont:detailTextFont];
        rowHeight += sizeOfOneLine.height;

    } else if (numberOfExtraLines > 1) {

        NSString *detailText = [NSString stringWithFormat:@"%@\n%@", [cellInfo objectForKey:@"callNumber"], [cellInfo objectForKey:@"holdingStatus"]];
        UITableViewCellAccessoryType accessoryType = [cellInfo objectForKey:@"scanURL"] != nil || [cellInfo objectForKey:@"requestURL"] != nil;
        rowHeight = [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                         tableView:tableView 
                                                              text:oneLine
                                                      maxTextLines:1
                                                        detailText:detailText
                                                    maxDetailLines:4
                                                              font:nil 
                                                        detailFont:nil
                                                     accessoryType:accessoryType
                                                         cellImage:YES];
    }
    
    return rowHeight;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (limitedView && indexPath.row == 5) {
        limitedView = NO;
        [self.tableView reloadData];
    } else {
        NSArray *cellsForSection = [self.tableCells objectAtIndex:indexPath.section];
        NSDictionary *cellInfo = [cellsForSection objectAtIndex:indexPath.row];
        NSString *requestURL = [cellInfo objectForKey:@"requestURL"];
        NSString *scanURL = [cellInfo objectForKey:@"scanURL"];
        if (requestURL && scanURL) {
            [actionSheetItems release];
            actionSheetItems = [[NSArray alloc] initWithObjects:requestURL, scanURL, nil];
            [self showActionSheet];
        } else if (requestURL) {
            [self showModalViewForRequest:@"Request Item" url:requestURL];
        } else if (scanURL) {
            [self showModalViewForRequest:@"Scan & Deliver" url:scanURL];
        }
    }
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	
	UIView * view;
	view = nil;

	
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	NSString * displayType = [collection objectForKey:@"displayType"];
	//NSString *collectionTitle = [collection objectForKey:@"collectionName"];
	NSString *collectionCallNbr = [collection objectForKey:@"collectionCallNumber"];
	
	if ([displayType isEqualToString:@"V"]) {
		
		UILabel * headerCollectionName;
		UILabel * headerCollectionCallNumber;
		UILabel * headerCollectionAvailVal;
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
		
		NSString * collectionName = [collectionItem objectForKey:@"collectionName"];
		NSString * callNbr = [collectionItem objectForKey:@"collectionCallNumber"];
		NSString * availVal = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
		
		CGFloat heightName = [collectionName
							  sizeWithFont:[UIFont boldSystemFontOfSize:17]
							  constrainedToSize:CGSizeMake(280, 2000)         
							  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightCallNbr = [callNbr
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(280, 2000)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightAvailVal = [availVal
								  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								  constrainedToSize:CGSizeMake(280, 2000)         
								  lineBreakMode:UILineBreakModeWordWrap].height;
		
		headerCollectionName = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 280, heightName)];
		headerCollectionName.text = collectionName;
		headerCollectionName.font = [UIFont boldSystemFontOfSize:17];
		headerCollectionName.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionName.backgroundColor = [UIColor clearColor];	
		headerCollectionName.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionName.numberOfLines = 5;
		
		headerCollectionCallNumber = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName, 280, heightCallNbr)];
		headerCollectionCallNumber.text = callNbr;
		headerCollectionCallNumber.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionCallNumber.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionCallNumber.backgroundColor = [UIColor clearColor];	
		headerCollectionCallNumber.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionCallNumber.numberOfLines = 5;
		
		headerCollectionAvailVal = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + heightCallNbr, 280, heightAvailVal)];
		headerCollectionAvailVal.text = availVal;
		headerCollectionAvailVal.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionAvailVal.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionAvailVal.backgroundColor = [UIColor clearColor];	
		headerCollectionAvailVal.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionAvailVal.numberOfLines = 5;
		
		CGFloat height = heightName + heightCallNbr + heightAvailVal;
		
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height)];
		[view addSubview:headerCollectionName];
		[view addSubview:headerCollectionCallNumber];
		[view addSubview:headerCollectionAvailVal];
		
		return view;
	}

	else {
		NSString * text0 = @"";
		NSString * text1 = @"";
		NSString * text2 = @"";
		
		UILabel * headerLabel0;
		UILabel * headerLabel1;
		UILabel * headerLabel2;
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		
		text0 = [collection objectForKey:@"collectionName"];
		
		
		if (([displayType isEqualToString:@"I"]) || ([displayType isEqualToString:@"III"]))
			text1 = [statDict objectForKey:@"statMain"];
		
		if ([text1 length] > 0)
			text1 = [text1 stringByReplacingCharactersInRange:
					 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
		
		text2 = collectionCallNbr;
		
		CGFloat height0 = [text0
						   sizeWithFont:[UIFont boldSystemFontOfSize:17]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height1 = [text1
						  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						  constrainedToSize:CGSizeMake(280.0, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height2 = [text2
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;

		headerLabel0 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 280.0, height0)];
		headerLabel0.text = text0;
		headerLabel0.font = [UIFont boldSystemFontOfSize:17];
		headerLabel0.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel0.backgroundColor = [UIColor clearColor];	
		headerLabel0.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel0.numberOfLines = 5;
		
		
		headerLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height0, 280.0, height1)];
		headerLabel1.text = text1;
		headerLabel1.font = [UIFont fontWithName:STANDARD_FONT size:13];
		headerLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel1.backgroundColor = [UIColor clearColor];	
		headerLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel1.numberOfLines = 5;
		
		
		headerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height0 + height1, 280.0, height2)];
		headerLabel2.text = text2;
		headerLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
		headerLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel2.backgroundColor = [UIColor clearColor];	
		headerLabel2.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel2.numberOfLines = 5;
		
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height0 + height1 + height2)];
		[view addSubview:headerLabel0];
		[view addSubview:headerLabel1];
		[view addSubview:headerLabel2];
		
		
		return view;
	}

	

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	NSString * displayType = [collection objectForKey:@"displayType"];
	//NSString *collectionTitle = [collection objectForKey:@"collectionName"];
	NSString *collectionCallNbr = [collection objectForKey:@"collectionCallNumber"];
	
	
	if ([displayType isEqualToString:@"V"]) {
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
		
		NSString * collectionName = [collectionItem objectForKey:@"collectionName"];
		NSString * callNbr = [collectionItem objectForKey:@"collectionCallNumber"];
		NSString * availVal = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
		
		CGFloat heightName = [collectionName
							  sizeWithFont:[UIFont boldSystemFontOfSize:17]
							  constrainedToSize:CGSizeMake(280, 2000)         
							  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightCallNbr = [callNbr
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(280, 2000)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightAvailVal = [availVal
								  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								  constrainedToSize:CGSizeMake(280, 2000)         
								  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height = heightName + heightCallNbr + heightAvailVal;

		
		return height + 4;
	}
	
	else {
		NSString * text0 = @"";
		NSString * text1 = @"";
		NSString * text2 = @"";
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		
		text0 = [statDict objectForKey:@"collectionName"];
		
		
		if (([displayType isEqualToString:@"I"]) || ([displayType isEqualToString:@"III"]))
			text1 = [statDict objectForKey:@"statMain"];
		
		if ([text1 length] > 0)
			text1 = [text1 stringByReplacingCharactersInRange:
					 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
		
		text2 = collectionCallNbr;
		
		CGFloat height0 = [text0
						   sizeWithFont:[UIFont systemFontOfSize:17]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height1 = [text1
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height2 = [text2
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		return height0 + height1 + height2 + 4;

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
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	self.parentViewApiRequest.jsonDelegate = nil;
    self.parentViewApiRequest = nil;
    
    self.libraryItem = nil;
    self.libraryAlias = nil;
    self.availabilityCategories = nil;
    self.arrayWithAllLibraries = nil;
    self.openToday = nil;
    
    [availabilityCategories release];
    
    [super dealloc];
}

#pragma mark -
/*


- (void)requestDidSucceedForCommand:(NSString *)command {
    if ([command isEqualToString:@"libdetail"] || [command isEqualToString:@"archivedetail"]) {
        NSString *hrsToday = [[[LibraryDataManager sharedManager] scheduleForLibID:requestedLibID] objectForKey:@"hrsOpenToday"];
        
        if ([hrsToday isEqualToString:@"closed"])
            self.openToday = [NSString stringWithString:@"Closed Today"];
        
        else {
            self.openToday = [NSString stringWithFormat: @"Open today from %@", hrsToday];
        }
        
        [self setupLayout];
    }
}

- (void)requestDidFailForCommand:(NSString *)command {
    [[LibraryDataManager sharedManager] unregisterDelegate:self];
}
*/

#pragma mark UIActionSheet setup

- (void)showActionSheet {
    
    // TODO: make these button titles into looked-up strings
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Item Action Options" 
															 delegate:self 
													cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:nil 
													otherButtonTitles:@"Request Item", @"Scan & Deliver", nil];

	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

    [actionSheet showInView:self.view];
    [actionSheet release];
	
	return;
}

- (void)showModalViewForRequest:(NSString *)title url:(NSString *)urlString {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:urlString title:title];
    [appDelegate presentAppModalViewController:modalVC animated:YES];
    [modalVC release];
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        return;
    } else {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        NSString *requestURL = nil;
        if ([title isEqualToString:@"Request Item"] && [actionSheetItems count]) {
            requestURL = [actionSheetItems objectAtIndex:0];
        } else if ([title isEqualToString:@"Scan & Deliver"] && [actionSheetItems count] > 1) {
            requestURL = [actionSheetItems objectAtIndex:1];
        }
        if (requestURL)
            [self showModalViewForRequest:[actionSheet buttonTitleAtIndex:buttonIndex] url:requestURL];
    }
}


@end

