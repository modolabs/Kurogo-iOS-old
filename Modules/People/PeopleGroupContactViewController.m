#import "PeopleGroupContactViewController.h"
#import "PeopleHomeViewController.h"
#import "KGOPersonWrapper.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "KGOTheme.h"
#import "PersonContact.h"
#import "CoreDataManager.h"
#import "KGOLabel.h"
#import "PeopleModule.h"

@interface PeopleGroupContactViewController (Private)



@end

@implementation PeopleGroupContactViewController
@synthesize module = _module;
@synthesize allContacts = _allContacts;

- (id)initWithGroup:(NSString *)group {
     _group = group;
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
    
    //_phoneDirectoryEntries = [[PersonContact directoryContacts] retain];
    if (!_allContacts) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:_group forKey:@"group"];
        _request = [[KGORequestManager sharedManager] requestWithDelegate:self module:PeopleTag path:@"group" params:params];
        _request.expectedResponseType = [NSDictionary class];
        [_request connect];
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

#pragma mark - KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request
{
    _request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSDictionary *results = [result dictionaryForKey:@"results"];
    NSArray *contacts = [results arrayForKey:@"contacts"];
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *contactDict in contacts) {
        PersonContact *aContact = [PersonContact personContactWithDictionary:contactDict
                                                                        type:[contactDict nonemptyStringForKey:@"class"]];
        [array addObject:aContact];
    }
    [_allContacts release];
    _allContacts = [array copy];
    
    [self reloadDataForTableView:self.tableView];
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
