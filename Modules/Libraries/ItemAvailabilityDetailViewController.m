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
@synthesize libraryItem;
@synthesize libraryAlias;
//@synthesize availabilityCategories;
@synthesize arrayWithAllLibraries;
@synthesize currentIndex;
@synthesize openToday;
@synthesize tableCells;

#pragma mark -
#pragma mark View lifecycle

-(void) setupLayout {
    if ([arrayWithAllLibraries count] && [arrayWithAllLibraries count] > 1) {
        
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
    }	
	
	//headerView = nil; 

    NSString *nameToDisplay;
    if (![libraryAlias.name isEqualToString:libraryAlias.library.primaryName] && [libraryAlias.library.primaryName length]) {
        nameToDisplay = [NSString stringWithFormat:@"%@ (%@)", libraryAlias.name, libraryAlias.library.primaryName];
    } else {
        nameToDisplay = libraryAlias.name;
    }
	
    UIFont *libNameFont = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
    UIFont *openTodayFont = [UIFont fontWithName:COURSE_NUMBER_FONT size:13];
	
    UIButton *infoButton = (UIButton *)[self.tableView.tableHeaderView viewWithTag:235];
    if (!infoButton) {
        infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        infoButton.enabled = YES;
        [infoButton setImage:[UIImage imageNamed:@"global/info_button.png"] forState:UIControlStateNormal];
        [infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:UIControlStateSelected];
        [infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
        [infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    NSLog(@"%@", [UIImage imageNamed:@"global/info_button.png"]);
    CGFloat infoButtonWidth = 50; // TODO: get these from image size
    CGFloat infoButtonHeight = 50;
    CGFloat infoButtonPadding = 5;
    CGFloat labelLeftMargin = 12;
    CGFloat labelWidth = self.tableView.frame.size.width - infoButtonWidth - infoButtonPadding;
    infoButton.frame = CGRectMake(labelWidth, infoButtonPadding, infoButtonWidth, infoButtonHeight);
    
	CGFloat displayNameHeight = [nameToDisplay sizeWithFont:libNameFont
                                          constrainedToSize:CGSizeMake(labelWidth, 2000)         
                                              lineBreakMode:UILineBreakModeWordWrap].height;
	CGFloat openTodayHeight = [openToday sizeWithFont:openTodayFont
                                    constrainedToSize:CGSizeMake(labelWidth, 20)         
                                        lineBreakMode:UILineBreakModeWordWrap].height;
    
    UILabel *libraryDisplayLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:233];
    if (!libraryDisplayLabel) {
        libraryDisplayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(labelLeftMargin, 9.0, labelWidth, displayNameHeight)] autorelease];
        libraryDisplayLabel.font = libNameFont;
        libraryDisplayLabel.textColor = [UIColor colorWithHexString:@"#1a1611"];
        libraryDisplayLabel.backgroundColor = [UIColor clearColor];	
        libraryDisplayLabel.lineBreakMode = UILineBreakModeWordWrap;
        libraryDisplayLabel.numberOfLines = 0;
    } else {
        libraryDisplayLabel.frame = CGRectMake(labelLeftMargin, 9.0, labelWidth, displayNameHeight);
    }
    libraryDisplayLabel.text = nameToDisplay;

	displayNameHeight += 9.0;
	
	
    UILabel *openTodayLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:234];
    if (!openTodayLabel) {
        openTodayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(labelLeftMargin, displayNameHeight, labelWidth, openTodayHeight)] autorelease];
        openTodayLabel.font = openTodayFont;
        openTodayLabel.textColor = [UIColor colorWithHexString:@"#666666"];
        openTodayLabel.backgroundColor = [UIColor clearColor];
        openTodayLabel.tag = 234;
    } else {
        openTodayLabel.frame = CGRectMake(labelLeftMargin, displayNameHeight, labelWidth, openTodayHeight);
    }
    openTodayLabel.text = openToday;
	
	CGFloat height = displayNameHeight + openTodayHeight;
	
	if (height < 50)
		height = 50;
	
    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 5.0)] autorelease];
    [headerView addSubview:libraryDisplayLabel];
    [headerView addSubview:openTodayLabel];
    [headerView addSubview:infoButton];
    self.tableView.tableHeaderView = headerView;
	
	limitedView = YES;
}

/*
- (void)processAvailabilityData {

    NSLog(@"%d collections", [availabilityCategories count]);
    //DLog(@"%@", [availabilityCategories description]);

    NSMutableArray *mutableTableCells = [NSMutableArray array];
    
    collectionOnly = NO;
    BOOL uniformHoldingStatus = YES;
    NSString *referenceHoldingStatus = nil;

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
                collectionOnly = YES;
                break;
            }
            
            for (NSInteger i = 0; i < 3; i++) {

                NSString *groupScanURL = nil;
                NSString *groupRequestURL = nil;
                
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
                        uniformCallNumber = NO;
                    }

                    if (!referenceHoldingStatus) {
                        referenceHoldingStatus = holdingStatus;
                    } else if (![holdingStatus isEqualToString:referenceHoldingStatus]) {
                        uniformHoldingStatus = NO;
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
                    
                    requestURL = [availItemDict objectForKey:@"requestUrl"];
                    if ([requestURL length]) {
                        [cellInfo setObject:requestURL forKey:@"requestURL"];
                        if (uniformCallNumber)
                            [cellForHoldingStatus setObject:requestURL forKey:@"requestURL"];
                        groupRequestURL = requestURL;
                    }
                    
                    scanURL = [availItemDict objectForKey:@"scanAndDeliverUrl"];
                    if ([scanURL length]) {
                        [cellInfo setObject:scanURL forKey:@"scanURL"];
                        if (uniformCallNumber)
                            [cellForHoldingStatus setObject:scanURL forKey:@"scanURL"];
                        groupScanURL = scanURL;
                    }
                    
                    [cellsForIndividualItems addObject:cellInfo];
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
                                                     nil];
                    
                    if (groupScanURL)    [cellInfo setObject:groupScanURL forKey:@"scanURL"];
                    if (groupRequestURL) [cellInfo setObject:groupRequestURL forKey:@"requestURL"];
                    
                    [cellsForGroups addObject:cellInfo];
                }
            }
        }
        
        if (uniformCallNumber) {
            if (uniformHoldingStatus) {
                DLog(@"type 1, %d cells", [cellsForGroups count]);
                
                [mutableTableCells addObject:cellsForGroups];
            }
            else {
                DLog(@"type 2, %d cells", [cellsForHoldings count]);
                
                [mutableTableCells addObject:cellsForHoldings];
            }
        } else {
            if (uniformHoldingStatus) {
                DLog(@"type 3, %d cells", [cellsForIndividualItems count]);
                for (NSMutableDictionary *cellInfo in cellsForIndividualItems) {
                    [cellInfo removeObjectForKey:@"holdingStatus"];
                }
            }
            else {
                DLog(@"type 4, %d cells", [cellsForIndividualItems count]);
            }

            [mutableTableCells addObject:cellsForIndividualItems];
        }
    } // end for (NSDictionary *aCollection in availabilityCategories)
    
    self.tableCells = [NSArray arrayWithArray:mutableTableCells];
}
 */


- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.tableView applyStandardColors];
    
    [[LibraryDataManager sharedManager] setAvailabilityDelegate:self];
    [[LibraryDataManager sharedManager] setLibDelegate:self];
    [[LibraryDataManager sharedManager] requestFullAvailabilityForItem:libraryItem.itemId];
    
    NSString *hrsToday = [[[LibraryDataManager sharedManager] scheduleForLibID:libraryAlias.library.identityTag] objectForKey:@"hrsOpenToday"];
    
    if (hrsToday) {
        [self detailsDidLoadForLibrary:libraryAlias.library.identityTag type:libraryAlias.library.type];
        
    } else {
        [[LibraryDataManager sharedManager] requestDetailsForLibType:self.libraryAlias.library.type libID:self.libraryAlias.library.identityTag libName:self.libraryAlias.name];
    }
    
	[self setupLayout];
    //[self processAvailabilityData];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %d", [super description], self.currentIndex];
}

- (void)detailsDidLoadForLibrary:(NSString *)libID type:(NSString *)libType {
    NSLog(@"335 index is now %d", currentIndex);
    if ([libID isEqualToString:libraryAlias.library.identityTag] && [libType isEqualToString:libraryAlias.library.type]) {
        NSString *hrsToday = [[[LibraryDataManager sharedManager] scheduleForLibID:libraryAlias.library.identityTag] objectForKey:@"hrsOpenToday"];
        
        if ([hrsToday isEqualToString:@"closed"]) {
            self.openToday = [NSString stringWithString:@"Closed Today"];
        } else {
            self.openToday = [NSString stringWithFormat: @"Open today from %@", hrsToday];
        }
        
        [self setupLayout];
    }
}

- (void)detailsDidFailToLoadForLibrary:(NSString *)libID type:(NSString *)libType{
    ;
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
				NSString * type = [tempDict objectForKey:@"type"];
				
				//NSArray * collections = (NSArray *)[tempDict objectForKey:@"collection"];
                
                currentIndex = tempLibIndex;
                self.libraryAlias = [[LibraryDataManager sharedManager] libraryAliasWithID:libId type:type name:libName];
                
                NSDictionary *collection = [self.arrayWithAllLibraries objectAtIndex:self.currentIndex];
                self.tableCells = [collection objectForKey:@"collections"]; // may be nil

                /*
                [availabilityCategories release];
                availabilityCategories = [collections retain];
                */
                [self setupLayout];
                //[self processAvailabilityData];
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
    //NSArray *cellsForSection = [self.tableCells objectAtIndex:section];
    NSDictionary *collection = [self.tableCells objectAtIndex:section];
    NSInteger cellCount = 0;
    for (NSDictionary *category in [collection objectForKey:@"categories"]) {
        cellCount += [[category objectForKey:@"items"] count];
    }
    //NSInteger cellCount = [cellsForSection count];
    if (cellCount <= 5 || !limitedView) {
        return cellCount;
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
    
    NSDictionary *collection = [self.tableCells objectAtIndex:indexPath.section];
    NSArray *categories = [collection objectForKey:@"categories"];
    NSDictionary *category = nil;
    NSArray *itemsForStatus = [NSArray array];
    NSInteger currentCollection = 0;
    NSInteger rowsTraversed = 0;
    category = [categories objectAtIndex:currentCollection];
    itemsForStatus = [category objectForKey:@"items"];
    while (indexPath.row >= rowsTraversed + [itemsForStatus count]) {
        currentCollection++;
        rowsTraversed += [itemsForStatus count];
        category = [categories objectAtIndex:currentCollection];
        itemsForStatus = [category objectForKey:@"items"];
    }
    NSDictionary *cellInfo = [itemsForStatus objectAtIndex:indexPath.row - rowsTraversed];
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    NSString *detailTextString = nil;

    NSMutableArray *detailTextLines = [NSMutableArray array];
    if ([itemsForStatus count] > 1) { // multiple call numbers
        NSString *theDescription = [cellInfo objectForKey:@"description"];
        if ([theDescription length]) {
            [detailTextLines addObject:[NSString stringWithFormat:@"%@ - %@", theDescription, [cellInfo objectForKey:@"callNumber"]]];
        } else {
            [detailTextLines addObject:[cellInfo objectForKey:@"callNumber"]];
        }
    }
    if ([categories count] > 1) { // multiple holding statuses
        [detailTextLines addObject:[category objectForKey:@"holdingStatus"]];
    }
    
    if ([detailTextLines count]) {
        detailTextString = [detailTextLines componentsJoinedByString:@"\n"];
        cellStyle = UITableViewCellStyleSubtitle;
    }
    
    UITableViewCell *cell = nil;
    BOOL isMultiCell = [detailTextLines count] > 1;
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d%@", indexPath.section, isMultiCell ? @"m" : @""];
    if (!isMultiCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:CellIdentifier] autorelease];
        }

    } else {
        LibrariesMultiLineCell *multiCell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (multiCell == nil) {
            multiCell = [[[LibrariesMultiLineCell alloc] initWithStyle:cellStyle reuseIdentifier:CellIdentifier] autorelease];
        }
        multiCell.detailTextLabelNumberOfLines = [detailTextLines count];
        cell = multiCell;
    }
    
    cell.detailTextLabel.text = detailTextString;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [cellInfo objectForKey:@"count"], [cellInfo objectForKey:@"state"]];
    cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:16];
    NSString *state = [cellInfo objectForKey:@"state"];
    if ([state isEqualToString:@"available"]) {
        cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open.png"];
    } else if ([state isEqualToString:@"unavailable"]) {
        cell.imageView.image = [UIImage imageNamed:@"dining//dining-status-closed.png"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
    }
    
    // chevron
    if ([[cellInfo objectForKey:@"requestURL"] length] || [[cellInfo objectForKey:@"scanAndDeliverURL"] length]) {
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
    
    
    NSDictionary *collection = [self.tableCells objectAtIndex:indexPath.section];
    NSArray *categories = [collection objectForKey:@"categories"];
    NSDictionary *category = nil;
    NSArray *itemsForStatus = [NSArray array];
    NSInteger currentCollection = 0;
    NSInteger rowsTraversed = 0;
    category = [categories objectAtIndex:currentCollection];
    itemsForStatus = [category objectForKey:@"items"];
    
    while (indexPath.row >= rowsTraversed + [itemsForStatus count]) {
        currentCollection++;
        rowsTraversed += [itemsForStatus count];
        category = [categories objectAtIndex:currentCollection];
        itemsForStatus = [category objectForKey:@"items"];
    }
    NSDictionary *cellInfo = [itemsForStatus objectAtIndex:indexPath.row - rowsTraversed];
    
    NSMutableArray *detailTextLines = [NSMutableArray array];
    //NSString *aLine = nil;
    if ([itemsForStatus count] > 1) { // multiple call numbers
        NSString *theDescription = [cellInfo objectForKey:@"description"];
        if ([theDescription length]) {
            [detailTextLines addObject:[NSString stringWithFormat:@"%@ - %@", theDescription, [cellInfo objectForKey:@"callNumber"]]];
        } else {
            [detailTextLines addObject:[cellInfo objectForKey:@"callNumber"]];
        }
    }
    if ([categories count] > 1) { // multiple holding statuses
        [detailTextLines addObject:[category objectForKey:@"holdingStatus"]];
    }
    
    if ([detailTextLines count]) {
    }
    
    //NSArray *cellsForSection = [self.tableCells objectAtIndex:indexPath.section];
    //NSDictionary *cellInfo = [cellsForSection objectAtIndex:indexPath.row];
    
    CGFloat rowHeight = tableView.rowHeight;

    /*
    NSInteger numberOfExtraLines = 0;
    if ([cellInfo objectForKey:@"callNumber"] != nil)
        numberOfExtraLines++;
    if ([cellInfo objectForKey:@"holdingStatus"] != nil)
        numberOfExtraLines++;
     */
    static NSString *oneLine = @"oneLine";
    //if (numberOfExtraLines == 1) {
    if ([detailTextLines count] == 1) {
        UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        CGSize sizeOfOneLine = [oneLine sizeWithFont:detailTextFont];
        rowHeight += sizeOfOneLine.height;

    //} else if (numberOfExtraLines > 1) {
    } else if ([detailTextLines count] > 1) {

        NSString *detailText = [detailTextLines componentsJoinedByString:@"\n"];
        BOOL hasAccessory = [[cellInfo objectForKey:@"scanAndDeliverURL"] length] != 0 || [[cellInfo objectForKey:@"requestURL"] length] != 0;
        //NSString *detailText = [NSString stringWithFormat:@"%@\n%@", [cellInfo objectForKey:@"callNumber"], [cellInfo objectForKey:@"holdingStatus"]];
        //BOOL hasAccessory = [cellInfo objectForKey:@"scanURL"] != nil || [cellInfo objectForKey:@"requestURL"] != nil;
        UITableViewCellAccessoryType accessoryType = hasAccessory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        
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
        NSDictionary *collection = [self.tableCells objectAtIndex:indexPath.section];
        NSArray *categories = [collection objectForKey:@"categories"];
        NSDictionary *category = nil;
        NSArray *itemsForStatus = [NSArray array];
        NSInteger currentCollection = 0;
        NSInteger rowsTraversed = 0;
        category = [categories objectAtIndex:currentCollection];
        itemsForStatus = [category objectForKey:@"items"];
        while (indexPath.row >= rowsTraversed + [itemsForStatus count]) {
            currentCollection++;
            rowsTraversed += [itemsForStatus count];
            category = [categories objectAtIndex:currentCollection];
            itemsForStatus = [category objectForKey:@"items"];
        }
        NSDictionary *itemInfo = [itemsForStatus objectAtIndex:indexPath.row - rowsTraversed];
        NSString *requestURL = [itemInfo objectForKey:@"requestURL"];
        NSString *scanURL = [itemInfo objectForKey:@"scanAndDeliverURL"];
        
        /*
        NSArray *cellsForSection = [self.tableCells objectAtIndex:indexPath.section];
        NSDictionary *cellInfo = [cellsForSection objectAtIndex:indexPath.row];
        NSString *requestURL = [cellInfo objectForKey:@"requestURL"];
        NSString *scanURL = [cellInfo objectForKey:@"scanURL"];
        */
        if ([requestURL length] && [scanURL length]) {
            [actionSheetItems release];
            actionSheetItems = [[NSArray alloc] initWithObjects:requestURL, scanURL, nil];
            [self showActionSheet];
        } else if ([requestURL length]) {
            [self showModalViewForRequest:@"Request Item" url:requestURL];
        } else if ([scanURL length]) {
            [self showModalViewForRequest:@"Scan & Deliver" url:scanURL];
        }
    }
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section {
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    
    NSDictionary *collection = [self.tableCells objectAtIndex:section];
    NSString *collectionName = [collection objectForKey:@"name"];
    NSString *callNumber = [collection objectForKey:@"callNumber"];
    NSString *holdingStatus = nil;
    
    NSArray *categories = [collection objectForKey:@"categories"];
    if ([categories count]) {
        NSDictionary *firstCategory = [categories objectAtIndex:0];
        NSString *holdingStatus = [firstCategory objectForKey:@"holdingStatus"];
        NSArray *items = [firstCategory objectForKey:@"items"];
        if ([holdingStatus isEqualToString:@"collection"] && [items count] == 1) {
            holdingStatus = [[items objectAtIndex:0] objectForKey:@"description"];
        }
    }
    /*
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
    NSDictionary * statDict = (NSDictionary *)[stats lastObject];
    
    NSString * collectionName;
    NSString * subtitle1 = nil;
    NSString * subtitle2 = nil;
    if (collectionOnly) {
        NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
        collectionName = [collectionItem objectForKey:@"collectionName"];
        subtitle1 = [collectionItem objectForKey:@"collectionCallNumber"];
        subtitle2 = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
    } else {
        collectionName = [collection objectForKey:@"collectionName"];
        subtitle1 = [statDict objectForKey:@"statMain"];
        subtitle2 = [collection objectForKey:@"collectionCallNumber"];
    }
    */
    CGFloat currentY = 0;
    //for (NSString *labelText in [NSArray arrayWithObjects:collectionName, subtitle1, subtitle2, nil]) {
    NSArray *labelStrings = nil;
    if (holdingStatus) {
        labelStrings = [NSArray arrayWithObjects:collectionName, callNumber, holdingStatus, nil];
    } else {
        labelStrings = [NSArray arrayWithObjects:collectionName, callNumber, nil];
    }
    for (NSString *labelText in labelStrings) {
        UIFont *font;
        if (labelText == collectionName) {
            font = [UIFont boldSystemFontOfSize:17];
        } else {
            font = [UIFont fontWithName:STANDARD_FONT size:13];
        }
        CGFloat height = [labelText sizeWithFont:font constrainedToSize:CGSizeMake(200, 2000) lineBreakMode:UILineBreakModeWordWrap].height;
        UILabel *aLabel = [[[UILabel alloc] initWithFrame:CGRectMake(12, currentY, 280, height)] autorelease];
        aLabel.text = labelText;
        aLabel.font = font;
        
        aLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
        aLabel.backgroundColor = [UIColor clearColor];	
        aLabel.lineBreakMode = UILineBreakModeWordWrap;
        aLabel.numberOfLines = 0;
        
        [view addSubview:aLabel];
        
        currentY += height;
    }
    
    view.frame = CGRectMake(0, 0, self.view.frame.size.width, currentY);
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    NSDictionary *collection = [self.tableCells objectAtIndex:section];
    NSString *collectionName = [collection objectForKey:@"name"];
    NSString *callNumber = [collection objectForKey:@"callNumber"];
    NSString *holdingStatus = nil;
    
    NSArray *categories = [collection objectForKey:@"categories"];
    if ([categories count]) {
        NSDictionary *firstCategory = [categories objectAtIndex:0];
        NSString *holdingStatus = [firstCategory objectForKey:@"holdingStatus"];
        NSArray *items = [firstCategory objectForKey:@"items"];
        if ([holdingStatus isEqualToString:@"collection"] && [items count] == 1) {
            holdingStatus = [[items objectAtIndex:0] objectForKey:@"description"];
        }
    }
    
    /*
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
    NSDictionary * statDict = (NSDictionary *)[stats lastObject];
    
    NSString * collectionName;
    NSString * subtitle1 = nil;
    NSString * subtitle2 = nil;
    if (collectionOnly) {
        NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
        collectionName = [collectionItem objectForKey:@"collectionName"];
        subtitle1 = [collectionItem objectForKey:@"collectionCallNumber"];
        subtitle2 = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
    } else {
        collectionName = [collection objectForKey:@"collectionName"];
        subtitle1 = [statDict objectForKey:@"statMain"];
        subtitle2 = [collection objectForKey:@"collectionCallNumber"];
    }
     */
    CGFloat height = 5;
    // for (NSString *labelText in [NSArray arrayWithObjects:collectionName, subtitle1, subtitle2, nil]) {
    NSArray *labelStrings = nil;
    if (holdingStatus) {
        labelStrings = [NSArray arrayWithObjects:collectionName, callNumber, holdingStatus, nil];
    } else {
        labelStrings = [NSArray arrayWithObjects:collectionName, callNumber, nil];
    }
    for (NSString *labelText in labelStrings) {
        UIFont *font;
        if (labelText == collectionName) {
            font = [UIFont boldSystemFontOfSize:17];
        } else {
            font = [UIFont fontWithName:STANDARD_FONT size:13];
        }
        height += [labelText sizeWithFont:font constrainedToSize:CGSizeMake(200, 2000) lineBreakMode:UILineBreakModeWordWrap].height;
    }
    
    return height;
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
    
    
    if ([[LibraryDataManager sharedManager] availabilityDelegate] == self) {
        [[LibraryDataManager sharedManager] setAvailabilityDelegate:nil];
    }
    
    if ([[LibraryDataManager sharedManager] libDelegate] == self) {
        [[LibraryDataManager sharedManager] setLibDelegate:nil];
    }
    
    self.libraryItem = nil;
    self.libraryAlias = nil;
    //self.availabilityCategories = nil;
    self.arrayWithAllLibraries = nil;
    self.openToday = nil;
    self.tableCells = nil;
    
    //[availabilityCategories release];
    
    [super dealloc];
}

#pragma mark -

- (void)fullAvailabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)institutions {
    NSLog(@"index is now %d", currentIndex);
    self.arrayWithAllLibraries = institutions;
    NSDictionary *collection = [self.arrayWithAllLibraries objectAtIndex:self.currentIndex];
    self.tableCells = [collection objectForKey:@"collections"]; // may be nil
    [self.tableView reloadData];
}

- (void)fullAvailabilityFailedToLoadForItemID:(NSString *)itemID {
    ;
}

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

