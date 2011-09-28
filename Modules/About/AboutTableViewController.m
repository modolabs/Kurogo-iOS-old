#import "AboutTableViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "MITMailComposeController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOWebViewController.h"

@implementation AboutTableViewController
@synthesize request;
@synthesize moduleTag;
@synthesize resultArray;
@synthesize loadingView;


- (void) addLoadingView {
    
    self.loadingView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    loadingView.backgroundColor = [UIColor whiteColor];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    [indicator startAnimating];
    indicator.center = self.view.center;
    [loadingView addSubview:indicator];
    [self.view addSubview:loadingView];
}

- (void) removeLoadingView {
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
}

- (void)viewDidLoad {
    showBuildNumber = NO;
    
    self.title = @"About";
    
    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                   module:@"about"
                                                                     path:@"index"
                                                                  version:1
                                                                   params:nil];
    self.request.expectedResponseType = [NSArray class];
    if (self.request) {
        [self.request connect];
        [self addLoadingView];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.loadingView = nil;
    self.resultArray = nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            
        case 1:
            if (resultArray != nil)
                return [resultArray count];
            else
                return 0;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
        
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
                }
                    break;
              /*  case 1:
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
                    break;*/
                default:
                    break;
            }
            break;
            
        case 1:
        {
            if (self.resultArray != nil) {
                NSDictionary *itemDict = (NSDictionary *)[resultArray objectAtIndex:indexPath.row];
                NSString * titleString = [itemDict objectForKey:@"title"];
                
                NSString *type = [itemDict nonemptyStringForKey:@"type"];
                if (!type) {
                    type = @"webView";
                }
                
                if ([type isEqualToString:@"email"]){
                    cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeEmail];
                }
                else if ([type isEqualToString:@"phone"]){
                    cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypePhone];
                }
                else if ([type isEqualToString:@"webView"]){
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                
                cell.textLabel.text = titleString;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
            }
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

        NSDictionary *itemDict = (NSDictionary *)[resultArray objectAtIndex:indexPath.row];
        
        NSString *type = [itemDict nonemptyStringForKey:@"type"];

        if (!type) {
            NSDictionary *params = (NSDictionary *)[resultArray objectAtIndex:indexPath.row];
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                                   forModuleTag:self.moduleTag 
                                         params:params];
        }
        else if ([type isEqualToString:@"email"]){
            [self presentMailControllerWithEmail:[itemDict objectForKey:@"email"] subject:@"" body:[NSString string] delegate:self];
        }
        else if ([type isEqualToString:@"phone"]) {
            NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [itemDict objectForKey:@"phone"]]];
            if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
                [[UIApplication sharedApplication] openURL:externURL];
            }
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
    [resultArray release];

    self.request = nil;
    self.moduleTag = nil;
    self.loadingView = nil;
    
    [super dealloc];
}


#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    DLog(@"%@", [result description]);
    self.resultArray = result;
    
    // TODO: only reload the section that will be updated
    [self.tableView reloadData];
    [self removeLoadingView];
    
}
@end

