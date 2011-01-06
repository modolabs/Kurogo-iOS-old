    //
//  LibraryDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryDetailViewController.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "LibrariesMultiLineCell.h"
#import "MapBookmarkManager.h"
#import "MIT_MobileAppDelegate.h"
#import "Foundation+MITAdditions.h"
#import "LibraryPhone.h"
#import "CoreDataManager.h"
#import "Library.h"
#import "LibraryAlias.h"

@implementation LibraryDetailViewController
@synthesize weeklySchedule;
@synthesize bookmarkButtonIsOn;
@synthesize lib;
@synthesize otherLibraries;
@synthesize currentlyDisplayingLibraryAtIndex;

NSInteger phoneNumberSort(id num1, id num2, void *context);

NSInteger phoneNumberSort(id num1, id num2, void *context){
	
	LibraryPhone * phone1 = (LibraryPhone *)num1;
	LibraryPhone * phone2 = (LibraryPhone *)num2;
	
	return [phone1.descriptionText compare:phone2.descriptionText];
	
}

-(void) setupLayout {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:nil];
    
    if ([self.lib.library.type isEqualToString:@"archive"])
        self.title = @"Archive Detail";
    
    else {
        self.title = @"Library Detail";
    }
	
    if ([otherLibraries count] > 1) {
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                                        [UIImage imageNamed:MITImageNameUpArrow],
                                                                                        [UIImage imageNamed:MITImageNameDownArrow], nil]];
        [segmentControl setMomentary:YES];
        [segmentControl addTarget:self action:@selector(showNextLibrary:) forControlEvents:UIControlEventValueChanged];
        segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
        
        if (currentlyDisplayingLibraryAtIndex == 0)
            [segmentControl setEnabled:NO forSegmentAtIndex:0];
        
        if (currentlyDisplayingLibraryAtIndex == [otherLibraries count] - 1)
            [segmentControl setEnabled:NO forSegmentAtIndex:1];
        
        [segmentControl release];
        [segmentBarItem release];

    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
	
	//headerView = nil; 
	NSString * libraryName;
	
	if (([lib.name isEqualToString:lib.library.primaryName]) && ([lib.library.primaryName length] > 0))
		libraryName = lib.name;
	
	else {
		libraryName = [NSString stringWithFormat:@"%@ (%@)", lib.name, lib.library.primaryName];
	}
	
	CGFloat height = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(250, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 15)] autorelease];
    if (!bookmarkButton) {
        bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , 5.0, 50.0, 50.0);
        bookmarkButton.enabled = YES;
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateSelected];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
        [bookmarkButton addTarget:self action:@selector(bookmarkButtonToggled:) forControlEvents:UIControlEventTouchUpInside];
    }
	[headerView addSubview:bookmarkButton];
	
	bookmarkButtonIsOn = NO;
    
    bookmarkButton.selected = [lib.library.isBookmarked boolValue];
    bookmarkButtonIsOn = [lib.library.isBookmarked boolValue];

    UILabel *label = (UILabel *)[self.tableView.tableHeaderView viewWithTag:1234];
    if (!label) {
        label = [[[UILabel alloc] initWithFrame:CGRectMake(12.0, 9.0, 250.0, height)] autorelease];
        label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
        label.textColor = [UIColor colorWithHexString:@"#1a1611"];
        label.backgroundColor = [UIColor clearColor];	
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.numberOfLines = 10;
        label.tag = 1234;
    } else {
        label.frame = CGRectMake(12.0, 9.0, 250.0, height);
    }
    label.text = libraryName;
	[headerView addSubview:label];
    
    self.tableView.tableHeaderView = headerView;
	
    [self setupWeeklySchedule];
    
	if (!didSetupWeeklySchedule) {
		weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  @"loading...", @"Monday",
					  @"loading...", @"Tuesday",
					  @"loading...", @"Wednesday",
					  @"loading...", @"Thursday",
					  @"loading...", @"Friday",
					  @"loading...", @"Saturday",
					  @"loading...", @"Sunday", nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupLayout) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraryDetail];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupLayout) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestArchiveDetail];

        [[LibraryDataManager sharedManager] requestDetailsForLibType:lib.library.type libID:lib.library.identityTag libName:lib.name];
    }
		
	[self setDaysOfWeekArray];
	
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    [phoneNumbersArray release];
    phoneNumbersArray = [[lib.library.phone sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]] retain];
    phoneNumbersArray = [[phoneNumbersArray sortedArrayUsingFunction:phoneNumberSort context:self] retain];
}


-(void) viewDidLoad {
	
	[self.tableView applyStandardColors];
    didSetupWeeklySchedule = NO;
	
	[self setupLayout];
	
}

-(void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupLayout];
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
    
    [bookmarkButton release];
	[weeklySchedule release];
    [daysOfWeek release];
    
    self.lib = nil;
    [phoneNumbersArray release];
    [footerView release];
    
    self.otherLibraries = nil;
    
    [super dealloc];
}


-(void) setDaysOfWeekArray {
	
	daysOfWeek = [[NSMutableArray alloc] initWithCapacity:7];
	
	NSDate * today = [NSDate date];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"EEEE"];
	NSString *dayString = [dateFormat stringFromDate:today];
	
	[daysOfWeek insertObject:dayString atIndex:0];
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDate *nextDate = today;
	
	for (int day=1; day < 7; day++){
		
		NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
		[offsetComponents setDay:1];
		nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:nextDate options:0];
		
		dayString = [dateFormat stringFromDate:nextDate];
		
		[daysOfWeek insertObject:dayString atIndex:day];
	}
}


-(void) bookmarkButtonToggled: (id) sender {
	
    BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
    
    lib.library.isBookmarked = [NSNumber numberWithBool:newBookmarkButtonStatus];
    bookmarkButton.selected = newBookmarkButtonStatus;
	
	[CoreDataManager saveData];
}


-(void) showNextLibrary: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([otherLibraries count] > 1) {
			int tempLibIndex;
			
			if (index == 0 && currentlyDisplayingLibraryAtIndex > 0) { // going up
				tempLibIndex = currentlyDisplayingLibraryAtIndex - 1;
			}
			else if (index == 1 && currentlyDisplayingLibraryAtIndex < [otherLibraries count]) {
				tempLibIndex = currentlyDisplayingLibraryAtIndex + 1;
            }
			
			
			if (tempLibIndex != currentlyDisplayingLibraryAtIndex){
                currentlyDisplayingLibraryAtIndex = tempLibIndex;
				
                self.lib = (LibraryAlias *)[otherLibraries objectAtIndex:tempLibIndex];
                didSetupWeeklySchedule = NO;
                [self setupLayout];
                [self.tableView reloadData];
			}			
		}
	}	
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2 + ((weeklySchedule == nil) ? 0 : 1);
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSInteger proxyIndex = section;

    if (weeklySchedule != nil) {
        if (section == 0) {
            if ([weeklySchedule count] == 7) {
                return 4;
            }
            return 1;

        } else {
            proxyIndex--;
        }
    }

    if (proxyIndex == 0) {
		if ([lib.library.location length])
			return 1;
    }
	
	else if (proxyIndex == 1) {
        
        NSInteger count = [lib.library.websiteLib length] ? 1 : 0;
        count += [lib.library.emailLib length] ? 1 : 0;
        count += [lib.library.phone count];
		
        return count;
	}
	

    return 0;
}


- (UIView *)tableView: (UITableView *)tableView viewForFooterInSection: (NSInteger)section{

	UIView * view = nil;
		
	if ((section == 1) && (lib.library.directions)) {
        NSString *text = lib.library.directions;
        UIFont *font = [UIFont fontWithName:STANDARD_FONT size:13];
        CGFloat width = self.view.frame.size.width - 20;
        CGFloat height = [text sizeWithFont:font
                          constrainedToSize:CGSizeMake(width, 2000)         
                              lineBreakMode:UILineBreakModeWordWrap].height;
        
        CGRect frame = CGRectMake(12.0, 5.0, width, height);

        if (!footerView) {
            footerView = [[UIView alloc] initWithFrame:frame];
        } else {
            footerView.frame = frame;
        }

        UILabel *footerLabel = (UILabel *)[footerView viewWithTag:7687];
        if (!footerLabel) {
            footerLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            footerLabel.tag = 7687;
            footerLabel.text = text;
            footerLabel.font = font;
            footerLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
            footerLabel.backgroundColor = [UIColor clearColor];	
            footerLabel.lineBreakMode = UILineBreakModeWordWrap;
            footerLabel.numberOfLines = 0;
            [footerView addSubview:footerLabel];
        } else {
            footerLabel.frame = frame;
        }
        
        view = footerView;
	}
	
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	
    if (section == 1 && lib.library.directions) {
		CGFloat height = [lib.library.directions sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
                                            constrainedToSize:CGSizeMake(300, 2000)
                                                lineBreakMode:UILineBreakModeWordWrap].height;
		
		return height + 10;
	}
	
	else return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSString * cellIdentifier = [NSString stringWithFormat:@"%d", indexPath.section];
    
    if (indexPath.section == 0 && [weeklySchedule count] == 7 && indexPath.row == 3) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"seeFullSchedule"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"seeFullSchedule"] autorelease];
        }
        cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:17];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Full week's schedule";
        return cell;
    }
    
    LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        
        cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:13];
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
        
        cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:17];
        cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#1A1611"];

		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    // TODO: set up sections beforehand so we don't have to keep doing this proxy thing
    NSInteger proxySectionIndex = indexPath.section; // decrement once for each existing section we don't lay out this time

    if (weeklySchedule != nil) {
        if (proxySectionIndex == 0) {
            if ([weeklySchedule count] == 7){
                if (indexPath.row <= 2) {
                    cell.textLabel.text = [daysOfWeek objectAtIndex:indexPath.row];
                    if ([weeklySchedule count] == [daysOfWeek count])
                        cell.detailTextLabel.text = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
                }
            }
            else if ([weeklySchedule count] == 0){
                cell.textLabel.text = nil;
                cell.detailTextLabel.text = @"loading...";
            }
            else {
                NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
                
                NSRange range = [hoursString rangeOfString:@"http"];
                if (range.location != NSNotFound) {
                    hoursString = [hoursString substringFromIndex:range.location];
                    cell.textLabel.text = @"Hours";
                    cell.detailTextLabel.text = @"See webpage";
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                }
                else {
                    cell.textLabel.text = [[weeklySchedule allKeys] objectAtIndex:0];
                    cell.detailTextLabel.text = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
                }
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            return cell;
        } else {
            proxySectionIndex--;
        }
    }
    
    if (proxySectionIndex == 0) {
        cell.textLabel.text = @"Location";
        cell.detailTextLabel.text = lib.library.location;
        cell.detailTextLabel.numberOfLines = 10;
        cell.detailTextLabelNumberOfLines = 10;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        return cell;
    }
	
	else if (proxySectionIndex == 1) {

        NSInteger proxyIndex = indexPath.row; // decrement this for each thing we don't lay out
        BOOL complete = NO;
        
        if ([lib.library.websiteLib length]) {
            if (proxyIndex == 0) {
                cell.textLabel.text = @"Website";
                NSRange range = [lib.library.websiteLib rangeOfString:@"http://"];
                NSString * website = lib.library.websiteLib;
                if (range.location != NSNotFound)
                    website = [lib.library.websiteLib substringFromIndex:range.location + range.length];
                
                cell.detailTextLabel.text = website;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.emailLib length]) {
            if (proxyIndex == 0) {
                cell.textLabel.text = @"Email";
                cell.detailTextLabel.text = lib.library.emailLib;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.phone count]) {

			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count]){
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:proxyIndex];
			}
			
			if (nil != phone) {
				cell.textLabel.numberOfLines = 2;
				if ([phone.descriptionText length] > 0)
					cell.textLabel.text = phone.descriptionText;
				else
					cell.textLabel.text = @"Phone";
				
				if ([phone.phoneNumber length] > 0)
					cell.detailTextLabel.text = phone.phoneNumber;
                
				cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
			}
        }
        
		return cell;
	}
	
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    NSInteger proxySectionIndex = indexPath.section; // decrement once for each existing section we don't lay out this time
    BOOL sectionComplete = NO;
    
    if (weeklySchedule != nil) {
        if (proxySectionIndex == 0) {
            
            if (([weeklySchedule count] == 7) && (indexPath.row == 3)){
                LibraryWeeklyScheduleViewController * vc = [[LibraryWeeklyScheduleViewController alloc] initWithStyle:UITableViewStyleGrouped];
                vc.title = @"Weekly Schedule";
                vc.daysOfTheWeek = daysOfWeek;
                vc.weeklySchedule = weeklySchedule;
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
            else if ([weeklySchedule count]) {
                NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
                
                NSRange range = [hoursString rangeOfString:@"http"];
                if (range.location != NSNotFound)
                {
                    hoursString = [hoursString substringFromIndex:range.location];
                    NSURL *libURL = [NSURL URLWithString:hoursString];
                    if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
                        [[UIApplication sharedApplication] openURL:libURL];
                    }
                }
            }
            sectionComplete = YES;
            
        } else {
            proxySectionIndex--;
        }
    }
	
    if (!sectionComplete && proxySectionIndex == 0) {
		[[MapBookmarkManager defaultManager] pruneNonBookmarks];
		
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([lib.library.lat doubleValue], [lib.library.lon doubleValue]);
		ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:coord] autorelease];
		annotation.name = lib.name;
		annotation.uniqueID = [NSString stringWithFormat:@"%@@%.4f,%.4f", annotation.name,coord.latitude, coord.longitude];
		[[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:annotation];
		
		NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
														path:LocalPathMapsSelectedAnnotation
													   query:annotation.uniqueID];
		
		[[UIApplication sharedApplication] openURL:internalURL];
	}
	
	else if (!sectionComplete && proxySectionIndex == 1) {
        
        NSInteger proxyIndex = indexPath.row; // decrement this for each thing we don't lay out
        BOOL complete = NO;
        
        if ([lib.library.websiteLib length]) {
            if (proxyIndex == 0) {
                NSString *url = lib.library.websiteLib;
                NSURL *libURL = [NSURL URLWithString:url];
                if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
                    [[UIApplication sharedApplication] openURL:libURL];
                }
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.emailLib length]) {
            if (proxyIndex == 0) {
                NSString *emailAdd = lib.library.emailLib;
                NSString *subject = NSLocalizedString(@"About your library", nil);
                [self emailTo:subject body:@"" email:emailAdd];
                
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.phone count]) {
			
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] > 0) {
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:proxyIndex];
			}
			NSString * phoneNum = @""; 
			NSString *phoneString = [phoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
			
			if (nil != phone){
				
				if ([phone.phoneNumber length] > 0) {
					phoneNum = phone.phoneNumber;
					phoneString = [phoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@"(" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@")" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@" " withString:@""];
				}
			}
			
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
        }

	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *detailText = nil;
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    NSInteger maxLines = 2;
    
    NSInteger proxySectionIndex = indexPath.section; // decrement once for each existing section we don't lay out this time
    BOOL sectionComplete = NO;
    
    if (weeklySchedule != nil) {
        if (proxySectionIndex == 0) {
            
            if ([weeklySchedule count] == 7){
                if (indexPath.row <= 2) {
                    if ([weeklySchedule count] == [daysOfWeek count])
                        detailText = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
                    
                } else if (indexPath.row == 3){
                    
                    return tableView.rowHeight;
                }
            } else if ([weeklySchedule count] == 0){
                detailText = @"loading...";
            }
            else {
                DLog(@"number of weekly schedule items: %d", [weeklySchedule count]);
                NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
                
                NSRange range = [hoursString rangeOfString:@"http"];
                if (range.location != NSNotFound) {
                    detailText = @"See webpage";
                    accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                }
                else {
                    detailText = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
                }
            }
            sectionComplete = YES;

        } else {
            proxySectionIndex--;
        }
        
	}
    
    if (!sectionComplete && proxySectionIndex == 0) {
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        detailText = lib.library.location;
        maxLines = 10;
        
    } else if (!sectionComplete && proxySectionIndex == 1) {
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        NSInteger proxyIndex = indexPath.row; // decrement this for each thing we don't lay out
        BOOL complete = NO;
        
        if ([lib.library.websiteLib length]) {
            if (proxyIndex == 0) {
                NSRange range = [lib.library.websiteLib rangeOfString:@"http://"];
                detailText = lib.library.websiteLib;
                if (range.location != NSNotFound)
                    detailText = [lib.library.websiteLib substringFromIndex:range.location + range.length];
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.emailLib length]) {
            if (proxyIndex == 0) {
                detailText = lib.library.emailLib;
                complete = YES;
            } else {
                proxyIndex--;
            }
        }
        
        if (!complete && [lib.library.phone count]) {
            
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] && [phoneNumbersArray count] > proxyIndex){
				phone = (LibraryPhone *)[phoneNumbersArray objectAtIndex:proxyIndex];
                detailText = phone.phoneNumber;
			}
        }
	}
    
    UIFont *cellFont = [UIFont fontWithName:BOLD_FONT size:13];
    UIFont *detailFont = [UIFont fontWithName:STANDARD_FONT size:17];
    
    return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                tableView:tableView 
                                                     text:@"title"
                                             maxTextLines:1
                                               detailText:detailText
                                           maxDetailLines:maxLines
                                                     font:cellFont 
                                               detailFont:detailFont
                                            accessoryType:accessoryType
                                                cellImage:NO];
}


#pragma mark -
#pragma mark MFMailComposeViewController delegation

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress {
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
		aController.mailComposeDelegate = self;
		
		
		NSMutableArray *emailAddressArray = [NSMutableArray array];
		[emailAddressArray addObject:emailAddress];
		[aController setSubject:subject];
		[aController setToRecipients:emailAddressArray];		
		[aController setMessageBody:emailBody isHTML:NO];
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:aController animated:YES];
		[aController release];
		
	} else {
		NSString *mailtoString = [NSString stringWithFormat:@"mailto://?subject=%@&body=%@", 
								  [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
								  [emailBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
		NSURL *externURL = [NSURL URLWithString:mailtoString];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
	
}

- (void)setupWeeklySchedule {
    
    [weeklySchedule release];
    weeklySchedule = nil;
        
    NSDictionary *libraryDictionary = [[LibraryDataManager sharedManager] scheduleForLibID:lib.library.identityTag];
    if (libraryDictionary) {
        
        [[LibraryDataManager sharedManager] unregisterDelegate:self];
        
        NSMutableDictionary *sched = [NSMutableDictionary dictionary];
        
        for (NSDictionary *wkSched in [libraryDictionary objectForKey:@"weeklyHours"]) {
            NSString *day = [wkSched objectForKey:@"day"];
            NSString *hours = [wkSched objectForKey:@"hours"];
            [sched setObject:hours forKey:day];
        }
        
        NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
        
        if ([sched count] < 7) {
            NSString *hours = [libraryDictionary objectForKey:@"hoursOfOperationString"];
            if ([hours length]) {
                [tempDict setObject:hours forKey:@"Hours"];
            } else {
                tempDict = nil;
            }
        } else {
            for (NSString * dayOfWeek in daysOfWeek) {
                NSString *scheduleString = [sched objectForKey:dayOfWeek];
                if (!scheduleString)
                    scheduleString = @"contact library/archive";
                [tempDict setObject:scheduleString forKey:dayOfWeek];
            }
        }

        if (tempDict)
            weeklySchedule = [tempDict retain];
        
        didSetupWeeklySchedule = YES;
        
        [self.tableView reloadData];
    }
}

- (void)requestDidFailForCommand:(NSString *)command {
    [[LibraryDataManager sharedManager] unregisterDelegate:self];
	[weeklySchedule release];
	weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"unavailable", @"Hours", nil];
}

@end
