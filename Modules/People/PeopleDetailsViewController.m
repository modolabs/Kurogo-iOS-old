#import "PeopleDetailsViewController.h"
#import "KGOAppDelegate.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "ModoNavigationController.h"
#import "MapBookmarkManager.h"
#import "TileServerManager.h"
#import "AnalyticsWrapper.h"
#import "MITMailComposeController.h"
#import "ThemeConstants.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"

@interface PeopleDetailsViewController (Private)

- (NSString *)displayTitleForSection:(NSInteger)section label:(NSString *)label;
- (void)displayPerson;

@end


@implementation PeopleDetailsViewController

@synthesize sectionArray = _sectionArray, person = _person, pager;

- (void)viewDidLoad
{
    // TODO: provide interface to mark person as viewed
    //self.person.viewed = [NSNumber numberWithBool:YES];
    [[CoreDataManager sharedManager] saveData];
    
	self.title = @"Info";
    
    [self displayPerson];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	
	self.sectionArray = nil;
    self.person = nil;
    [super dealloc];
}

- (void)displayPerson {
    // information in header: photo, name
    
    UIFont *font = [[KGOTheme sharedTheme] fontForContentTitle];
    UILabel *nameLabel = [UILabel multilineLabelWithText:self.person.name font:font width:self.tableView.frame.size.width - 20];
    nameLabel.frame = CGRectMake(10, 10, nameLabel.frame.size.width, nameLabel.frame.size.height);

    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, nameLabel.frame.size.height + 14)] autorelease];
	[header addSubview:nameLabel];

	self.tableView.tableHeaderView = header;

    // sections
    
	self.sectionArray = [NSMutableArray array];
    
    NSMutableArray *currentSection = nil;

    // - organization/department/title TODO: make more flexible we can do stuff like split title/org at harvard
    for (NSDictionary *orgDict in self.person.organizations) {
        currentSection = [NSMutableArray array];
        for (NSString *label in [NSArray arrayWithObjects:@"jobTitle", @"organization", @"department", nil]) {
            NSString *value = [orgDict stringForKey:label nilIfEmpty:YES];
            if (value) {
                [currentSection addObject:[NSDictionary dictionaryWithObjectsAndKeys:label, @"label", value, @"value", nil]];
            }
        }
        [self.sectionArray addObject:currentSection];
    }
    
    // - emails
    if (self.person.emails.count) {
        _emailSection = self.sectionArray.count;

        currentSection = [NSMutableArray array];
        for (NSDictionary *aDict in self.person.emails) {
            [currentSection addObject:aDict];
        }
        [self.sectionArray addObject:currentSection];
    }
    
    // - phones
    if (self.person.phones.count) {
        _phoneSection = self.sectionArray.count;
        
        currentSection = [NSMutableArray array];
        for (NSDictionary *aDict in self.person.phones) {
            [currentSection addObject:aDict];
        }
        [self.sectionArray addObject:currentSection];
    }
    
    // - addresses
    if (self.person.addresses.count) {
        _addressSection = self.sectionArray.count;
        
        currentSection = [NSMutableArray array];
        for (NSDictionary *aDict in self.person.addresses) {
            NSString *label = [aDict stringForKey:@"label" nilIfEmpty:NO];
            if (!label)
                label = [NSString string];
            
            NSString *displayAddress = [KGOPersonWrapper displayAddressForDict:aDict];
            if (!displayAddress)
                displayAddress = [NSString string];
            
            [currentSection addObject:[NSDictionary dictionaryWithObjectsAndKeys:displayAddress, @"value", label, @"label", nil]];
        }
        [self.sectionArray addObject:currentSection];
    }
    
    // - IM
    if (self.person.screennames.count) {
        currentSection = [NSMutableArray array];
        for (NSDictionary *aDict in self.person.screennames) {
            [currentSection addObject:aDict];
        }
        [self.sectionArray addObject:currentSection];
    }
    
    // - urls
    if (self.person.webpages.count) {
        currentSection = [NSMutableArray array];
        for (NSDictionary *aDict in self.person.webpages) {
            [currentSection addObject:aDict];
        }
        [self.sectionArray addObject:currentSection];
    }
    
    [self.tableView reloadData];
}

#pragma mark KGODetailPager

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPersonWrapper class]]) {
        self.person = (KGOPersonWrapper *)content;
        [self displayPerson];
    }
}

#pragma mark -
#pragma mark Table view methods

- (NSString *)displayTitleForSection:(NSInteger)section label:(NSString *)label {
    static NSDictionary *displayLabels = nil;
    if (displayLabels == nil) {    
        displayLabels = [[NSDictionary alloc] initWithObjectsAndKeys:
                         NSLocalizedString(@"Home", nil), @"home",
                         NSLocalizedString(@"Work", nil), @"work",
                         NSLocalizedString(@"Other", nil), @"other",
                         nil];
    }
    NSString *title = [displayLabels objectForKey:label];
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return [self.sectionArray count] + 1;
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == [self.sectionArray count])
		return 2;
	return [[self.sectionArray objectAtIndex:section] count];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.section < [self.sectionArray count]) ? KGOTableCellStyleValue2 : KGOTableCellStyleDefault;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title;
    NSString *accessoryTag = nil;
    UITableViewCellSelectionStyle selectionStyle = UITableViewCellSelectionStyleGray;
    BOOL centerText = NO;
    
    if (indexPath.section == [self.sectionArray count]) {
        
        centerText = YES;
        if (indexPath.row == 0) {
            title = NSLocalizedString(@"Create New Contact", nil);
        } else {
            title = NSLocalizedString(@"Add to Existing Contact", nil);
        }

    } else {
		NSDictionary *personAttribute = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *label = [personAttribute objectForKey:@"label"];
        title = [self displayTitleForSection:indexPath.section label:label];

        if (indexPath.section == _addressSection) {
            accessoryTag = TableViewCellAccessoryMap;
            // TODO: check for lookup-ability of address
            //accessoryTag = KGOAccessoryTypeBlank;
        } else if (indexPath.section == _emailSection) {
            accessoryTag = TableViewCellAccessoryEmail;
        } else if (indexPath.section == _phoneSection) {
            accessoryTag = TableViewCellAccessoryPhone;
        }
    }
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = selectionStyle;
        cell.textLabel.text = title;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryTag];
        if (centerText) cell.textLabel.textAlignment = UITextAlignmentCenter;
    } copy] autorelease];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.section < [self.sectionArray count]) { 

		NSDictionary *personAttribute = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *value = [personAttribute objectForKey:@"value"];

        UIFont *font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:UITableViewCellStyleValue2];
        
        // inner 20 for padding; 0.75 is approx ratio allocated to detail text label, 20 for accessory
        CGFloat width = floor((tableView.frame.size.width - 20) * 0.75) - 20;
        CGFloat originX = self.tableView.frame.size.width - 20 - width;
        
        UIColor *textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:UITableViewCellStyleValue2];

        // use a textView for the address so people can copy/paste.
        if (indexPath.section == _addressSection) {

            CGSize size = [value sizeWithFont:font
                            constrainedToSize:CGSizeMake(width, 1989.0f) // 2009 minus vertical padding
                                lineBreakMode:UILineBreakModeWordWrap];
            
            CGRect frame = CGRectMake(originX, 10, width, size.height);
            
            UITextView *textView = [[[UITextView alloc] initWithFrame:frame] autorelease];
            textView.text = value;
            textView.backgroundColor = [UIColor clearColor];
            textView.font = font;
            textView.textColor = textColor;
            textView.editable = NO;
            textView.scrollEnabled = NO;
            textView.contentInset = UIEdgeInsetsMake(-8, -9, -8, -9);
            
            //textView.userInteractionEnabled = addressSearchAnnotation == nil;
            
            return [NSArray arrayWithObject:textView];

        } else {
            UILabel *label = [UILabel multilineLabelWithText:value font:font width:width];
            label.frame = CGRectMake(originX, 10, width, label.frame.size.height);
            return [NSArray arrayWithObject:label];
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == [self.sectionArray count]) { // user selected create/add to contacts
		
		if (indexPath.row == 0) { // create addressbook entry
			ABNewPersonViewController *creator = [[[ABNewPersonViewController alloc] init] autorelease];
			creator.displayedPerson = [self.person convertToABPerson];
			[creator setNewPersonViewDelegate:self];
			
			KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:creator animated:YES];
			
		} else {
			ABPeoplePickerNavigationController *picker = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
			[picker setPeoplePickerDelegate:self];
			
			KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:picker animated:YES];
		}
		
	} else {
		// React if the cell tapped has text that that matches the display name of mail, telephonenumber, or postaladdress.
		if (indexPath.section == _emailSection) {
            NSDictionary *personAttribute = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            [self emailIconTapped:[personAttribute stringForKey:@"value" nilIfEmpty:YES]];
        }
		else if (indexPath.section == _phoneSection) {
            NSDictionary *personAttribute = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            [self phoneIconTapped:[personAttribute stringForKey:@"value" nilIfEmpty:YES]];
        }
		else if (indexPath.section == _addressSection) {
            NSDictionary *personAttribute = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            [self mapIconTapped:[personAttribute stringForKey:@"value" nilIfEmpty:YES]];
        }
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Address book methods

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{	
	KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (BOOL)        personViewController:(ABPersonViewController *)personViewController 
 shouldPerformDefaultActionForPerson:(ABRecordRef)person 
							property:(ABPropertyID)property 
						  identifier:(ABMultiValueIdentifier)identifierForValue
{
    // causes the app to place a phone call, send email, etc.
    // if we want to perform custom actions, return NO and add
    // approriate address book actions
	return YES;
}

/* when they pick a person we are recreating the entire record using
 * the union of what was previously there and what we received from
 * the server
 */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    self.person.ABPerson = person;
    [self.person saveToAddressBook];
	
	KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
	
	return NO; // don't navigate to built-in view
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property 
							  identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}
	
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark App-switching actions

- (void)mapIconTapped:(NSString *)address
{
    /*
    NSURL *internalURL = [NSURL internalURLWithModuleTag:MapTag
                                                    path:LocalPathMapsSelectedAnnotation
                                                   query:addressSearchAnnotation.uniqueID];

    [[UIApplication sharedApplication] openURL:internalURL];
    */
}

- (void)phoneIconTapped:(NSString *)phone
{
    NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phone]];
    if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
        [[UIApplication sharedApplication] openURL:externURL];
    }
}

- (void)emailIconTapped:(NSString *)email
{
    [MITMailComposeController presentMailControllerWithEmail:email subject:nil body:nil];
}

@end


