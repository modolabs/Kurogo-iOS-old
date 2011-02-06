#import "CalendarDetailViewController.h"
#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "MITUIConstants.h"
#import "Foundation+MITAdditions.h"
#import "MapBookmarkManager.h"
#import "MapSearchResultAnnotation.h"
#import "AnalyticsWrapper.h"
#import "MITMailComposeController.h"
#import "ThemeConstants.h"

#define WEB_VIEW_PADDING 10.0
#define BUTTON_PADDING 10.0
#define kCategoriesWebViewTag 521
#define kDescriptionWebViewTag 516

enum CalendarDetailRowTypes {
	CalendarDetailRowTypeTime,
	CalendarDetailRowTypeLocation,
	CalendarDetailRowTypePhone,
	CalendarDetailRowTypeURL,
	CalendarDetailRowTypeTicketURL,
	CalendarDetailRowTypeEmail,
	CalendarDetailRowTypeDescription,
	CalendarDetailRowTypeCategories
};

@implementation CalendarDetailViewController

@synthesize event, events;

- (void)loadView {
    [super loadView];
	
	shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Detail";
    
    if (isRegularEvent) {
        [self setupShareButton];
    }
	
	// set up table rows
	[self reloadEvent];
    if (isRegularEvent) {
       // [self requestEventDetails];
    }
	
	descriptionString = nil;
    //categoriesString = nil;
	
	// setup nav bar
	if (self.events.count > 1) {
		UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																						[UIImage imageNamed:MITImageNameUpArrow],
																						[UIImage imageNamed:MITImageNameDownArrow], nil]];
		[segmentControl setMomentary:YES];
		[segmentControl addTarget:self action:@selector(showNextEvent:) forControlEvents:UIControlEventValueChanged];
		segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
		UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
		self.navigationItem.rightBarButtonItem = segmentBarItem;
		[segmentControl release];
		[segmentBarItem release];
	}
	
	descriptionHeight = 0;
    
    NSString *detailString = [NSString stringWithFormat:@"/events/detail?id=%@", self.event.title];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)showNextEvent:(id)sender
{
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
		NSInteger currentEventIndex = [self.events indexOfObject:self.event];
		if (i == 0) { // previous
			currentEventIndex--;
			if (currentEventIndex == -1) {
				currentEventIndex = [self.events count] - 1;
			}
		} else {
			currentEventIndex++;
			if (currentEventIndex == [self.events count]) {
				currentEventIndex = 0;
			}
		}
		self.event = [self.events objectAtIndex:currentEventIndex];
		[self reloadEvent];
		
		if (isRegularEvent) {
            //[self requestEventDetails];
        }
    }
}

- (void)requestEventDetails
{
	// No longer required as the details come with the initial header requests
	//JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	//NSString *eventID = [NSString stringWithFormat:@"%d", [self.event.eventID intValue]];
	/*
	[apiRequest requestObjectFromModule:@"calendar" 
								command:@"detail" 
							 parameters:[NSDictionary dictionaryWithObjectsAndKeys:eventID, @"id", nil]];
	 */
}

// helper function that maintains consistency of descriptionString and descriptionHeight
-(void)setDescriptionString:(NSString *)description
{
	[descriptionString release];
	descriptionString = [[NSMutableString stringWithContentsOfTemplate:@"calendar/events_template.html"
														 searchStrings:[NSArray arrayWithObject:@"__BODY__"]
														  replacements:[NSArray arrayWithObject:description]] retain];
	return;
}

- (void)reloadEvent
{
	[self setupHeader];
	
	if (numRows > 0) {
		free(rowTypes);
	}
	
	rowTypes = malloc(sizeof(CalendarEventListType) * 6);
	numRows = 0;
	if (self.event.start) {
		rowTypes[numRows] = CalendarDetailRowTypeTime;
		numRows++;
	}
	if (self.event.shortloc || self.event.location) {
		rowTypes[numRows] = CalendarDetailRowTypeLocation;
		numRows++;
	}
	if (self.event.phone) {
		rowTypes[numRows] = CalendarDetailRowTypePhone;
		numRows++;
	}
	if (self.event.url) {
		rowTypes[numRows] = CalendarDetailRowTypeURL;
		numRows++;
	}
	if (self.event.ticketUrl) {
		rowTypes[numRows] = CalendarDetailRowTypeTicketURL;
		numRows++;
	}
	if (self.event.email) {
		rowTypes[numRows] = CalendarDetailRowTypeEmail;
		numRows++;
	}
	if (self.event.summary) {
		rowTypes[numRows] = CalendarDetailRowTypeDescription;
        [descriptionString release];

		//sets the description string and height of the views
		[self setDescriptionString:self.event.summary];
		
		numRows++;
	}
	if ([self.event.categories count] > 0 && isRegularEvent) {
        rowTypes[numRows] = CalendarDetailRowTypeCategories;
        
        [categoriesString release];
        
        UIFont *cellFont = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:UITableViewCellStyleDefault];
        CGSize textSize = [CalendarTag sizeWithFont:cellFont];
        // one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
        categoriesHeight = (textSize.height + 5.0) * ([event.categories count] + 2);
		
        numRows++;
	}
	
	[self.tableView reloadData];
}

- (void)share:(id)sender {
	[shareController shareInView:self.view];
}

- (void)setupShareButton {
    if (!shareButton) {
        CGRect tableFrame = self.tableView.frame;
        shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *buttonImage = [UIImage imageNamed:@"global/share.png"];
        shareButton.frame = CGRectMake(tableFrame.size.width - buttonImage.size.width - BUTTON_PADDING,
                                       BUTTON_PADDING,
                                       buttonImage.size.width,
                                       buttonImage.size.height);
        [shareButton setImage:buttonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageNamed:@"global/share_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupHeader {	
	CGRect tableFrame = self.tableView.frame;
	
	CGFloat titlePadding = 10.0;
    CGFloat titleWidth;
    if (isRegularEvent) {
        titleWidth = tableFrame.size.width - shareButton.frame.size.width - BUTTON_PADDING * 2 - titlePadding;
        self.tableView.separatorColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    } else {
        titleWidth = tableFrame.size.width - titlePadding * 2;
        self.tableView.separatorColor = [UIColor whiteColor];
    }
	UIFont *titleFont = [[KGOTheme sharedTheme] fontForContentTitle];
	CGSize titleSize = [self.event.title sizeWithFont:titleFont
									constrainedToSize:CGSizeMake(titleWidth, 2010.0)];
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titlePadding, titleSize.width, titleSize.height)];
	titleView.lineBreakMode = UILineBreakModeWordWrap;
	titleView.numberOfLines = 0;
	titleView.font = titleFont;
	titleView.text = self.event.title;
    titleView.textColor = [[KGOTheme sharedTheme] textColorForContentTitle];
	
	// if title is very short, add extra padding so button won't be too close to first cell
	if (titleSize.height < shareButton.frame.size.height) {
		titleSize.height += BUTTON_PADDING;
	}
	
	CGRect titleFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
	self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:titleFrame] autorelease];
	[self.tableView.tableHeaderView addSubview:titleView];
    if (isRegularEvent) {
        [self.tableView.tableHeaderView addSubview:shareButton];
    }
	[titleView release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	
	[shareController release];
	shareController = nil;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)setEvent:(MITCalendarEvent *)anEvent {
    event = anEvent;
    
    [descriptionString release];
    [categoriesString release];
	
    descriptionString = nil;
    categoriesString = nil;
	
    NSInteger catID = [[[self.event.categories anyObject] catID] intValue];
    isRegularEvent = (catID != kCalendarAcademicCategoryID && catID != kCalendarHolidayCategoryID);
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return numRows;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger rowType = rowTypes[indexPath.row];
	
	if (rowType == CalendarDetailRowTypeDescription) {		
		//sets the description string and height of the views
		[self setDescriptionString:self.event.summary];
		
		CGFloat webViewHeight;
		
		if (descriptionHeight > 0) {
			webViewHeight = descriptionHeight;
		} else {
			webViewHeight =50; //was 2000
		}

		CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, webViewHeight);
		UIWebView *webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
		webView.delegate = self;
		[webView loadHTMLString:descriptionString baseURL:nil];
		webView.tag = kDescriptionWebViewTag;
		
		[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceVertical:NO];
		[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceHorizontal:NO];
		
		return [NSArray arrayWithObject:webView];
		
	} else if (rowType == CalendarDetailRowTypeCategories) {
		NSMutableString *categoriesBody = [NSMutableString stringWithString:@"Gazette Classification: <ul>"];
		
		NSMutableArray *tempCats = [NSMutableArray array];
		
		for (EventCategory *category in event.categories) {
			[tempCats addObject:category];
		}
		
		NSArray *tempA = [tempCats sortedArrayUsingSelector:@selector(compare:)];
		
		for (EventCategory *category in tempA) {
			NSString *catIDString = [NSString stringWithFormat:@"catID=%d", [category.catID intValue]];
			NSURL *categoryURL = [NSURL internalURLWithModuleTag:CalendarTag path:CalendarStateCategoryEventList query:catIDString];
			[categoriesBody appendString:[NSString stringWithFormat:
										  @"<li><a href=\"%@\">%@</a></li>", [categoryURL absoluteString], category.title]];
		}
		
		[categoriesBody appendString:@"</ul>"];
		[categoriesString release];
		categoriesString = [[NSMutableString stringWithContentsOfTemplate:@"calendar/events_template.html"
															searchStrings:[NSArray arrayWithObject:@"__BODY__"]
															 replacements:[NSArray arrayWithObject:categoriesBody]] retain];
		
		UIFont *cellFont = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleDefault];
		CGSize textSize = [CalendarTag sizeWithFont:cellFont];
		// one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
		categoriesHeight = (textSize.height + 5.0) * ([event.categories count] + 2);
		
		CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, categoriesHeight);
		UIWebView *webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
		[webView loadHTMLString:categoriesString baseURL:nil];
		webView.tag = kCategoriesWebViewTag;
		
		return [NSArray arrayWithObject:webView];
	}
	
	return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCellSelectionStyle selectionStyle = UITableViewCellSelectionStyleGray;
	UIImageView *accessoryView = nil;
	NSString *title = nil;
	
	NSInteger rowType = rowTypes[indexPath.row];
	
	switch (rowType) {
		case CalendarDetailRowTypeTime:
			title = [event dateStringWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle separator:@"\n"];
			break;
		case CalendarDetailRowTypeLocation:
			title = (event.location != nil) ? event.location : event.shortloc;
			if ([event hasCoords]) {
				accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryMap];
			} else {
                accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeBlank];
                selectionStyle = UITableViewCellSelectionStyleNone;
            }
			break;
		case CalendarDetailRowTypePhone:
			title = event.phone;
			accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryPhone];			
			break;
		case CalendarDetailRowTypeURL:
			title = @"Visit Website";
			//cell.textLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleURL];
			//cell.textLabel.textColor = [[KGOTheme sharedTheme] linkColor];
			accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryExternal];
			break;
			
		case CalendarDetailRowTypeTicketURL:
			title = @"Link to Tickets";
			//cell.textLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleURL];
			//cell.textLabel.textColor = [[KGOTheme sharedTheme] linkColor];
			accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryExternal];
			break;
			
		case CalendarDetailRowTypeEmail:
			title = event.email;
			//cell.textLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleURL];
			//cell.textLabel.textColor = [[KGOTheme sharedTheme] linkColor];
			accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryEmail];
			break;
		case CalendarDetailRowTypeCategories:
		case CalendarDetailRowTypeDescription:
			selectionStyle = UITableViewCellSelectionStyleNone;
		default:
			break;
	}
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = selectionStyle;
        cell.textLabel.text = title;
        cell.accessoryView = accessoryView;
    } copy] autorelease];
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger rowType = rowTypes[indexPath.row];
	
	switch (rowType) {
		case CalendarDetailRowTypeLocation:
            if ([event hasCoords]) {
                [[MapBookmarkManager defaultManager] pruneNonBookmarks];
                
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([event.latitude floatValue], [event.longitude floatValue]);
                ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:coord] autorelease];
                annotation.name = event.location;
                annotation.uniqueID = [NSString stringWithFormat:@"%@@%.4f,%.4f", event.location, coord.latitude, coord.longitude];
                [[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:annotation];
                
                NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
                                                                path:LocalPathMapsSelectedAnnotation
                                                               query:annotation.uniqueID];
                
                [[UIApplication sharedApplication] openURL:internalURL];
            }
			break;
		case CalendarDetailRowTypePhone:
		{
			NSString *phoneString = [event.phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
			break;
		}
		case CalendarDetailRowTypeURL:
		{
			NSURL *eventURL = [NSURL URLWithString:event.url];
			if (event.url && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			break;
		}
			
		case CalendarDetailRowTypeTicketURL:
		{
			NSURL *eventURL = [NSURL URLWithString:event.ticketUrl];
			if (event.ticketUrl && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			break;
		}
			
		case CalendarDetailRowTypeEmail:
		{
			NSString *subject = [self emailSubject];
			[MITMailComposeController presentMailControllerWithEmail:event.email subject:subject body:nil];
			break;
		}
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark ShareItemDelegate

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share this event"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"Harvard Event: %@", event.title];
}

- (NSString *)emailBody {
	
	NSString *summary = event.summary;
	NSArray *summaryArray = [summary componentsSeparatedByString:@"<"];
	
	if ([summaryArray count] > 0)
		summary = [summaryArray objectAtIndex:0];


	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n%@\n%@\n%@", event.title, [self twitterUrl], summary];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    
    NSString *escapedTitle = [event.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            "\"description\":\"%@\"}",
                            escapedTitle,
                            [self twitterUrl],
                            [event.summary stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    /*
    NSString *mobileUrl = [self twitterUrl];
    if (mobileUrl) {
        attachment = [NSString stringWithFormat:@"{%@,%@}",
                      attachment,
                      [NSString stringWithFormat:@"\"properties\":{\"Mobile web link\":{\"text\":\"%@\",\"href\":\"%@\"}}",
                       mobileUrl, escapedTitle]];
    } else {
        attachment = [NSString stringWithFormat:@"{%@}", attachment];
    }
     */
    return attachment;
}

- (NSString *)twitterUrl {
    if ([event.url length])
        return event.url;
	return [NSString stringWithFormat:@"http://%@/calendar/detail.php?id=%d", MITMobileWebDomainString, [event.eventID integerValue]];
}

- (NSString *)twitterTitle {
	return event.title;
}

#pragma mark JSONAPIDelegate for background refreshing of events

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	if (result && [result isKindOfClass:[NSDictionary class]]) {
		[self.event updateWithDict:result];
		[self reloadEvent];
	}
}


- (void)dealloc {
	self.event = nil;
	free(rowTypes);
	
	[shareButton release];
	[shareController release];
    [categoriesString release];
    [descriptionString release];
    [super dealloc];
}


#pragma mark -
#pragma mark UIWebView delegation

-(void)webViewDidStartLoad:(UIWebView *)webView {
	CGSize size = [webView sizeThatFits:CGSizeZero];

	NSInteger newDescriptionHeight = size.height; 	
	if(newDescriptionHeight != descriptionHeight) {
		descriptionHeight = newDescriptionHeight;
		[self.tableView reloadData];
	}	
	return;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// calculate webView height, if it change we need to reload table
	//NSInteger newDescriptionHeight =[[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"main-content\").offsetHeight;"] intValue];
	CGSize size = [webView sizeThatFits:CGSizeZero];
	
	//[webView loadHTMLString:descriptionString baseURL:nil];
	NSInteger newDescriptionHeight = size.height; 	
	if(newDescriptionHeight != descriptionHeight) {
		descriptionHeight = newDescriptionHeight;
		[self.tableView reloadData];
	}	
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	
	return YES;
}


@end
