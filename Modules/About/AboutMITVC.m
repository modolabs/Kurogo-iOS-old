#import "AboutMITVC.h"
#import "MITUIConstants.h"
#import "AnalyticsWrapper.h"
#import "KGOTheme.h"

@implementation AboutMITVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"About Harvard";
    
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
	NSString * file = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
	NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:file];
    NSString *aboutText = [infoDict objectForKey:@"AboutOrgText"];
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
	NSString * file = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
	NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:file];
    cell.textLabel.text = [infoDict objectForKey:@"AboutOrgText"];
    cell.textLabel.font = [[KGOTheme sharedTheme] fontForBodyText];
    cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellTitleWithStyle:UITableViewCellStyleDefault];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
	
    return cell;
}

@end

