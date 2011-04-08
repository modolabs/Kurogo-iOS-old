#import "AboutMITVC.h"
#import "AnalyticsWrapper.h"
#import "KGOTheme.h"

@implementation AboutMITVC
@synthesize orgName, orgAboutText;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = orgName; //NSLocalizedString(@"AboutOrgTitle", nil);
    
    [[AnalyticsWrapper sharedWrapper] trackPageview:@"/about/harvard"];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *aboutText = orgAboutText; //NSLocalizedString(@"AboutOrgText", nil);
    UIFont *aboutFont = [UIFont systemFontOfSize:15.0];
    CGSize aboutSize = [aboutText sizeWithFont:aboutFont constrainedToSize:CGSizeMake(270, 2000) lineBreakMode:UILineBreakModeWordWrap];
    return aboutSize.height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = orgAboutText; //NSLocalizedString(@"AboutOrgText", nil);
    cell.textLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
    cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
	
    return cell;
}

@end

