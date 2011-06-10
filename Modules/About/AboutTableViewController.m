#import "AboutTableViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "AboutMITVC.h"
#import "MITMailComposeController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation AboutTableViewController
@synthesize request;
@synthesize moduleTag;

- (id)initWithStyle:(UITableViewStyle)style {
    
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"About";
        
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:@"about"
                                                                         path:@"alldata"
                                                                        params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        self.request.expectedResponseType = [NSDictionary class];
        if (self.request) {
            [self.request connect];
            //[self addLoadingView];
        }
        
        // initialize as empty strings if not-assigned.
        if (aboutText == nil) aboutText = @"About";
        if (orgText == nil) orgText = @"";
        if (orgName == nil) orgText = @"About";
        if (orgEmail == nil) orgText = @"";
        if (orgWebsite == nil) orgText = @"";
        if (credits == nil) orgText = @"";
        if (copyright == nil) orgText = @"";
    }
    return self;

}

- (void)viewDidLoad {
    showBuildNumber = NO;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 20, 45)];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, footerView.frame.size.width, 30)];
    footerLabel.text = copyright; //NSLocalizedString(@"AboutFooterText", nil);
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySmallPrint];
    footerLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySmallPrint];
    footerLabel.lineBreakMode = UILineBreakModeWordWrap;
    footerLabel.numberOfLines = 0;
    [footerView addSubview:footerLabel];
    self.tableView.tableFooterView = footerView;
    [footerLabel release];
    [footerView release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 3;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1) {
        //NSString *aboutText = aboutText; //NSLocalizedString(@"AboutAppText", nil);
        UIFont *aboutFont = [UIFont systemFontOfSize:14.0];
        if ((aboutText != nil)) {
            CGSize aboutSize = [aboutText sizeWithFont:aboutFont constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000) lineBreakMode:UILineBreakModeWordWrap];
            
            return aboutSize.height + 40;
        }
        else
            return 0;
    }
    else {
        return self.tableView.rowHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    if (!showBuildNumber) {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"]];
                        cell.imageView.image = nil;
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"], MITBuildNumber];
                        cell.imageView.image = [UIImage imageWithPathName:@"common/githash.png"];
                    }
                    cell.textLabel.textAlignment = UITextAlignmentCenter;
                    cell.textLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        			cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                case 1:
                {
                    cell.textLabel.text = aboutText;
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
        			cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = orgName;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
                    break;
                
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Credits", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
                    break;
                    
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Send Feedback", nil);
                    cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeEmail];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    break;
                break;
            }
        default:
            break;
    }
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        showBuildNumber = !showBuildNumber;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {                
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:orgName, @"orgName", orgText, @"orgText", nil];
                [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
                break;
            }
            case 1: {
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:credits, @"creditsHTMLString", nil];
                [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameWebViewDetail forModuleTag:self.moduleTag params:params];
                break;
            }
            case 2: {
                NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    
                NSString *subject = [NSString stringWithFormat:@"%@:%@ %@, Build: %@", @"Regarding", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"], MITBuildNumber];
                
                NSString *email = orgEmail;
                [self presentMailControllerWithEmail:email subject:subject body:[NSString string] delegate:self];
				break;
            }
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error 
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)dealloc {
    [super dealloc];
}


#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    NSLog(@"%@", [result description]);
    
    NSDictionary * resultDict = (NSDictionary * ) result;
    
    aboutText = [[resultDict stringForKey:@"aboutHTML" nilIfEmpty:NO] retain];
    orgText = [[resultDict stringForKey:@"siteAboutHTML" nilIfEmpty:NO] retain];
    orgName = [[resultDict stringForKey:@"orgName" nilIfEmpty:NO] retain];
    orgEmail = [[resultDict stringForKey:@"email" nilIfEmpty:NO] retain];
    orgWebsite = [[resultDict stringForKey:@"website" nilIfEmpty:NO] retain];
    copyright = [[resultDict stringForKey:@"copyright" nilIfEmpty:NO] retain];
    credits = [[result stringForKey:@"credits" nilIfEmpty:NO] retain];

    [self.tableView reloadData];
    //[self removeLoadingView];
    
}
@end

