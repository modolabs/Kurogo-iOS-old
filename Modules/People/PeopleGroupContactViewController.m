#import "PeopleGroupContactViewController.h"
#import "PeopleHomeViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"
#import "KGOLabel.h"
#import "PeopleModel.h"
#import "PeopleModule.h"

@implementation PeopleGroupContactViewController

@synthesize module = _module;
@synthesize allContacts = _allContacts;
@synthesize contactGroup;
@synthesize dataManager;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.module = nil;
    self.allContacts = nil;
    self.dataManager.delegate = nil;
    self.dataManager = nil;
    self.contactGroup = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.contactGroup.title;
    
    self.allContacts = [[self.contactGroup.contacts allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[PersonContact class]]) {
            if ([obj2 isKindOfClass:[PersonContact class]]) {
                return [[(PersonContact *)obj1 identifier] compare:[(PersonContact *)obj2 identifier]];
            } else {
                return NSOrderedAscending;
            }

        } else if ([obj2 isKindOfClass:[PersonContact class]]) {
            return NSOrderedDescending;
        } else {
            return [[(PersonContactGroup *)obj1 sortOrder] compare:[(PersonContactGroup *)obj2 sortOrder]];
        }
    }];
    
    if (!self.dataManager) {
        self.dataManager = [[[PeopleDataManager alloc] init] autorelease];
        self.dataManager.delegate = self;
        self.dataManager.moduleTag = self.module.tag;
        [self.dataManager fetchContactsForGroup:self.contactGroup.identifier];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - PeopleDataDelegate

- (void)dataManager:(PeopleDataManager *)dataManager didReceiveContacts:(NSArray *)contacts
{
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[PersonContact class]];
    }];
    self.allContacts = [contacts filteredArrayUsingPredicate:pred];
    [self reloadDataForTableView:self.tableView];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allContacts count];
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = nil;
    NSString *detailText = nil;
    NSString *accessoryTag = nil;
    UIColor *backgroundColor = nil;
    UIView *backgroundView = nil;
    UIView *selectedBackgroundView = nil;

    
    PersonContact *contact = [_allContacts objectAtIndex:indexPath.row];
    title = contact.title;
    detailText = contact.subtitle;
    accessoryTag = KGOAccessoryTypePhone; 
    backgroundColor = [[KGOTheme sharedTheme] backgroundColorForSecondaryCell];
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
        cell.detailTextLabel.text = detailText;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryTag];
        if (backgroundColor) {
            cell.backgroundColor = backgroundColor;
        }
        if (backgroundView) {
            cell.backgroundView = backgroundView;
        }
        if (selectedBackgroundView) {
            cell.selectedBackgroundView = selectedBackgroundView;
        }
    } copy] autorelease];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    PersonContact *contact = [_allContacts objectAtIndex:indexPath.row];
    NSString *urlString = contact.url; 
    NSURL *externURL = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:externURL])
        [[UIApplication sharedApplication] openURL:externURL];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleSubtitle;          
}

@end
