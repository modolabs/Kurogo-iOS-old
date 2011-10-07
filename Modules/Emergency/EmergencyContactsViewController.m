#import "EmergencyContactsViewController.h"
#import "EmergencyDataManager.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "EmergencyModel.h"

@interface EmergencyContactsViewController (Private)

- (void)emergencyContactsRetrieved:(NSNotification *)notification;

@end

@implementation EmergencyContactsViewController
@synthesize module = _module;
@synthesize allContacts = _allContacts;

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)dealloc
{
    self.module = nil;
    self.allContacts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    EmergencyDataManager *manager = [EmergencyDataManager managerForTag:_module.tag];
    self.navigationItem.title = @"Contacts";
    
    if(_module.contactsFeedExists) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emergencyContactsRetrieved:) name:EmergencyContactsRetrievedNotification object:manager];

        // load cached contacts
        self.allContacts = [manager allContacts];
        
        // refresh contacts (if stale)
        if (![manager contactsFresh]) {
            [manager fetchContacts];
        }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.allContacts) {
        return self.allContacts.count;
    }
    return 0;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    
    EmergencyContact *contact = [self.allContacts objectAtIndex:indexPath.row];
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = contact.title;
        cell.detailTextLabel.text = contact.subtitle;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypePhone];
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    EmergencyContact *contact = [self.allContacts objectAtIndex:indexPath.row];
    NSURL *externURL = [NSURL URLWithString:contact.url];
    if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
        [[UIApplication sharedApplication] openURL:externURL];
    }
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleSubtitle;          
}

- (void)emergencyContactsRetrieved:(NSNotification *)notification {
    EmergencyDataManager *manager = [EmergencyDataManager managerForTag:_module.tag];
    self.allContacts = [manager allContacts];    
    [self reloadDataForTableView:self.tableView];
}
@end
