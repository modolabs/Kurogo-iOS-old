#import "EventListTableView.h"
#import "MITCalendarEvent.h"
#import "CalendarDetailViewController.h"
#import "MITUIConstants.h"

#define MULTILINE_ADJUSTMENT_ACCESSORY 41.0
#define MULTILINE_ADJUSTMENT_NO_ACCESSORY 21.0

@implementation EventListTableView
@synthesize events, parentViewController, isSearchResults, searchSpan, isAcademic;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (self.events != nil) {
        self.separatorColor = TABLE_SEPARATOR_COLOR;
		return [self.events count];
	}
    self.separatorColor = [UIColor whiteColor];
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
    NSString *titleString = nil;
	if (isSearchResults) {
		NSUInteger numResults = [self.events count];
		switch (numResults) {
			case 0:
                titleString = [NSString stringWithString:@"No events found"];
				break;
			case 1:
                titleString = [NSString stringWithString:@"1 event found"];
				break;
			default:
                titleString = [NSString stringWithFormat:@"%d events found", numResults];
				break;
		}
        
        if (searchSpan) {
            titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, searchSpan];
        }
		else
			titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, @"7 days"];
	}
	return titleString;
}
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
    NSString *titleString = nil;
	if (isSearchResults) {
		NSUInteger numResults = [self.events count];
		switch (numResults) {
			case 0:
                titleString = [NSString stringWithString:@"No events found"];
				break;
			case 1:
                titleString = [NSString stringWithString:@"1 event found"];
				break;
			default:
                titleString = [NSString stringWithFormat:@"%d events found", numResults];
				break;
		}
        
        if (searchSpan) {
            titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, searchSpan];
        }
		else
			 titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, @"7 days"];
        
        titleView = [UITableView ungroupedSectionHeaderWithTitle:titleString];
	}
    return titleView;
}
*/

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	
    if (event.shortloc) {
        // right align event location
		CGFloat maxWidth = self.frame.size.width - 20;
		UIFont *font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
		CGSize textSize = [event.title sizeWithFont:font];
		CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 1 : textSize.height);
		
		font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
        CGSize locationTextSize = [event.shortloc sizeWithFont:font
													  forWidth:100.0
												 lineBreakMode:UILineBreakModeTailTruncation];
        CGRect locationFrame = CGRectMake(maxWidth - locationTextSize.width,
                                          textHeight,
                                          locationTextSize.width,
                                          locationTextSize.height);
        
        UILabel *locationLabel = [[[UILabel alloc] initWithFrame:locationFrame] autorelease];
        locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
        locationLabel.text = event.shortloc;
        locationLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
        locationLabel.font = font;
        locationLabel.highlightedTextColor = [UIColor whiteColor];
        
		return [NSArray arrayWithObject:locationLabel];
    }
	
	return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {

	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	NSString *title = event.title;
    NSString *subtitle = nil;
	
	BOOL showTimeOnly = !isSearchResults && ([CalendarConstants intervalForEventType:self.parentViewController.activeEventList fromDate:self.parentViewController.startDate forward:YES] == 86400.0);
    
    if (showTimeOnly) {
        subtitle = [event dateStringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    } else {
		if (isAcademic) {
			NSArray *stringArray = [[event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "] componentsSeparatedByString: @" "];
			subtitle = [stringArray objectAtIndex:0];
		} else {
			subtitle = [event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
		}
    }
	
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
		cell.detailTextLabel.text = subtitle;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } copy] autorelease];
}

// required method in UITableViewDataSource
// still thinking of a cleaner way to do this
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

//- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath;

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
	NSInteger randomTagNumberForLocationLabel = 1831;
    
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    } else {
		UIView *extraView = [cell viewWithTag:randomTagNumberForLocationLabel];
		[extraView removeFromSuperview];
	}
    
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];

	CGFloat maxWidth = self.frame.size.width - MULTILINE_ADJUSTMENT_ACCESSORY;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	CGSize textSize = [event.title sizeWithFont:cell.textLabel.font];
	CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 1 : textSize.height);

    cell.textLabelNumberOfLines = 2;
    //cell.textLabelLineBreakMode = UILineBreakModeTailTruncation;
	cell.textLabel.text = event.title;

	// show time only if date is shown; date plus time otherwise
	BOOL showTimeOnly = !isSearchResults && ([CalendarConstants intervalForEventType:self.parentViewController.activeEventList fromDate:self.parentViewController.startDate forward:YES] == 86400.0);
    
    //NSInteger locationTextLength;
    if (showTimeOnly) {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
        //locationTextLength = 25;
    } else {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
        //locationTextLength = 25; //was 10
		
		if (isAcademic) {
			NSArray *stringArray = [[event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "] componentsSeparatedByString: @" "];
			cell.detailTextLabel.text = [stringArray objectAtIndex:0];
		}
    }
        
    if (event.shortloc) {
        // right align event location
		
        CGSize locationTextSize = [event.shortloc sizeWithFont:[[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle]
													  forWidth:100.0
												 lineBreakMode:UILineBreakModeTailTruncation];
        CGRect locationFrame = CGRectMake(maxWidth - locationTextSize.width,
                                          textHeight,
                                          locationTextSize.width,
                                          locationTextSize.height);
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:locationFrame];
        locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
        locationLabel.text = event.shortloc;
        locationLabel.textColor = cell.detailTextLabel.textColor;
        locationLabel.font = cell.detailTextLabel.font;
        locationLabel.tag = randomTagNumberForLocationLabel;
        locationLabel.highlightedTextColor = [UIColor whiteColor];
        
        [cell.contentView addSubview:locationLabel];
        [locationLabel release];
    }
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	//CGFloat height = CELL_TWO_LINE_HEIGHT;
	UIFont *font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
	//CGFloat constraintWidth = self.frame.size.width - MULTILINE_ADJUSTMENT_ACCESSORY;

	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	//CGSize textSize = [event.title sizeWithFont:font];
	//if (textSize.width > (constraintWidth - 20)) {
	//	height += textSize.height + 2.0;
	//}

    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                         tableView:tableView 
                                              text:event.title
                                      maxTextLines:2
                                        detailText:CalendarTag // something with one line
                                    maxDetailLines:1
                                              font:font 
                                        detailFont:nil 
                                     accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                         cellImage:NO];
    
    
    
	//return height;
}
*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
		
	CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] initWithStyle:UITableViewStylePlain];
	detailVC.event = event;
	detailVC.events = self.events;

	[self.parentViewController.navigationController pushViewController:detailVC animated:YES];
	[detailVC release];
}


- (void)dealloc {
    if (searchSpan) {
        [searchSpan release];
    }
    events = nil;
    [super dealloc];
}


@end

