#import "AboutTableViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "AboutMITVC.h"
#import "MITMailComposeController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOWebViewController.h"

@implementation AboutTableViewController
@synthesize request;
@synthesize moduleTag;
@synthesize resultDict;
@synthesize resultKeys;
@synthesize loadingIndicator;
@synthesize loadingView;

- (id)initWithStyle:(UITableViewStyle)style {
    
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"About";
        
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:@"about"
                                                                         path:@"index"
                                                                        params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        self.request.expectedResponseType = [NSDictionary class];
        if (self.request) {
            [self.request connect];
            [self addLoadingView];
        }
    }
    return self;

}

- (void) addLoadingView {
    
    self.loadingView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    loadingView.backgroundColor = [UIColor whiteColor];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.loadingIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    [loadingIndicator startAnimating];
    loadingIndicator.center = self.view.center;
    [loadingView addSubview:loadingIndicator];
    [self.view addSubview:loadingView];
}

- (void) removeLoadingView {
    [self.loadingIndicator stopAnimating];
    [self.loadingView removeFromSuperview];
}

- (void)viewDidLoad {
    showBuildNumber = NO;
}

-(void) viewDidUnload {
    [super viewDidUnload];
    
    self.resultDict = nil;
    self.resultKeys = nil;

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            
        case 1:
            if (resultDict != nil)
                return [[resultDict allKeys] count];
            else
                return 0;
            
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    /*if (indexPath.section == 0 && indexPath.row == 1) {
        //NSString *aboutText = aboutText; //NSLocalizedString(@"AboutAppText", nil);
        UIFont *aboutFont = [UIFont systemFontOfSize:14.0];
        if ((aboutText != nil)) {
            CGSize aboutSize = [aboutText sizeWithFont:aboutFont constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000) lineBreakMode:UILineBreakModeWordWrap];
            
            return aboutSize.height + 40;
        }
        else
            return 0;
    }*/
    if (indexPath.section == 1) {
        NSDictionary *itemDict = (NSDictionary *)[resultDict objectForKey:[self.resultKeys objectAtIndex:indexPath.row]];
        
        BOOL hasTyepString = NO;
        NSString * type = @"webView";
        
        if ([[itemDict allKeys] containsObject:@"type"]){
            
            hasTyepString = YES;
            type = [itemDict objectForKey:@"type"];
        }
        
        if ([type isEqualToString:@"map"]){
            return 0;
        }
        else
            return self.tableView.rowHeight;
        
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
            
        case 1:{
            if (self.resultDict != nil) {
            NSDictionary *itemDict = (NSDictionary *)[resultDict objectForKey:[self.resultKeys objectAtIndex:indexPath.row]];
            NSString * titleString = [itemDict objectForKey:@"title"];
            
            BOOL hasTyepString = NO;
            NSString * type = @"webView";
            
            if ([[itemDict allKeys] containsObject:@"type"]){
                
                hasTyepString = YES;
                type = [itemDict objectForKey:@"type"];
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
        }
            break;

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

        NSDictionary *itemDict = (NSDictionary *)[resultDict objectForKey:[self.resultKeys objectAtIndex:indexPath.row]];
        
        BOOL hasTyepString = NO;
        NSString * type = @"webView";
        
        if ([[itemDict allKeys] containsObject:@"type"]){
            
            hasTyepString = YES;
            type = [itemDict objectForKey:@"type"];
        }

        if ([type isEqualToString:@"webView"]){
            
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                                   forModuleTag:self.moduleTag 
                                         params:(NSDictionary *)[resultDict objectForKey:[self.resultKeys objectAtIndex:indexPath.row]]];
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
    [super dealloc];
    [self.resultDict dealloc];
   // [self.resultKeys dealloc];
}


#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    NSLog(@"%@", [result description]);
    
    self.resultDict = result;
    
    if (nil != self.resultKeys)
        [self.resultKeys release];
    
    self.resultKeys = [[[NSMutableArray alloc] init] retain];
    
    int count = 0;
    for (NSString * key in self.resultDict)
         [self.resultKeys insertObject:key atIndex:count++];
    
    [self.tableView reloadData];
    [self removeLoadingView];
    
}
@end

