#import "EmergencyHomeViewController.h"
#import "EmergencyDataManager.h"
#import "KGOHTMLTemplate.h"
#import "UIKit+KGOAdditions.h"
#import "ThemeConstants.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"


@interface EmergencyHomeViewController (Private)

- (void)emergencyNoticeRetrieved:(NSNotification *)notification;
- (void)emergencyContactsRetrieved:(NSNotification *)notification;
- (NSArray *)noticeViewsWithtableView:(UITableView *)tableView;

@end

@implementation EmergencyHomeViewController
@synthesize contentDivHeight = _contentDivHeight;
@synthesize module = _module;
@synthesize notice = _notice;
@synthesize infoWebView = _infoWebView;

@synthesize primaryContacts = _primaryContacts;

- (id)init {
    if ((self = [self initWithStyle:UITableViewStyleGrouped])) {
        loadingStatus = Loading;
    }
    return self;
}

- (void)dealloc
{
    self.module = nil;
    self.infoWebView.delegate = nil;
    self.notice = nil;
    self.primaryContacts = nil;
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
    self.notice = nil;
    EmergencyDataManager *manager = [EmergencyDataManager managerForTag:_module.tag];
    
    if(_module.noticeFeedExists) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emergencyNoticeRetrieved:) name:EmergencyNoticeRetrievedNotification object:manager];
        [manager fetchLatestEmergencyNotice];
    }
    
    if(_module.contactsFeedExists) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emergencyContactsRetrieved:) name:EmergencyContactsRetrievedNotification object:manager];

        // load cached contacts
        self.primaryContacts = [manager primaryContacts];
        _hasMoreContact = [manager hasSecondaryContacts];
        
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
    NSInteger sections = 0;
    if (_module.noticeFeedExists) {
        sections++;
    }
    if(_module.contactsFeedExists) {
        sections++;
    }
    return sections;
}

- (NSInteger)sectionIndexForNotice {
    return _module.noticeFeedExists ? 0 : -1;
}

- (NSInteger)sectionIndexForContacts {
    if (!_module.contactsFeedExists) {
        return -1;
    }
    
    return _module.noticeFeedExists ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == [self sectionIndexForNotice]) {
        return 1;
    } else if(section == [self sectionIndexForContacts]) {
        NSInteger contactRows = self.primaryContacts.count;
        if(_hasMoreContact) {
            contactRows++;
        }
        return contactRows;
    }
    return 0;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {  
    if(indexPath.section == [self sectionIndexForNotice]) {
        return [self noticeViewsWithtableView:tableView];
    }
    return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = nil;
    NSString *detailText = nil;
    NSString *accessoryTag = nil;
    
    if(indexPath.section == [self sectionIndexForContacts]) {
        if (indexPath.row < self.primaryContacts.count) {
            EmergencyContact *contact = [self.primaryContacts objectAtIndex:indexPath.row];
            title = contact.title;
            detailText = contact.summary;
            accessoryTag = TableViewCellAccessoryPhone;

        } else if(indexPath.row == self.primaryContacts.count) {
            title = @"More contacts";
        }
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = title;
        cell.detailTextLabel.text = detailText;
        if(accessoryTag) {
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryTag];
        } else {
            cell.accessoryView = nil;
        }
    } copy] autorelease];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == [self sectionIndexForContacts]) {
        if (indexPath.row < self.primaryContacts.count) {
            return KGOTableCellStyleSubtitle;          
        } 
    }
    return KGOTableCellStyleDefault;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    if (indexPath.section == [self sectionIndexForContacts]) {
        if (indexPath.row < self.primaryContacts.count) {
            EmergencyContact *contact = [self.primaryContacts objectAtIndex:indexPath.row];
            NSString *urlString = [NSString stringWithFormat:@"tel:%@", contact.dialablePhone];
            NSURL *externURL = [NSURL URLWithString:urlString];
            if ([[UIApplication sharedApplication] canOpenURL:externURL])
                [[UIApplication sharedApplication] openURL:externURL];
            
            
        } else if (indexPath.row == self.primaryContacts.count) {
            [KGO_SHARED_APP_DELEGATE() showPage:EmergencyContactsPathPageName forModuleTag:_module.tag params:nil];
        }
    }
    
}

- (NSArray *)noticeViewsWithtableView:(UITableView *)tableView {
    CGFloat height = 1000.0f;
    if(self.contentDivHeight) {
        height = [self.contentDivHeight floatValue] + 20.0;
    }
    CGRect frame = CGRectMake(10, 10, tableView.frame.size.width-20-20, height);
    self.infoWebView.delegate = nil;
    self.infoWebView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
    self.infoWebView.delegate = self;
    
    NSString *htmlString;
    if (loadingStatus == Loading) {
        htmlString = @"<html><body style=\"font:15px/1.33em Helvetica;color:#333;margin:0;padding:2px\"><div id=\"content\">Loading...</div></body></html>";
        [self.infoWebView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
    } else if(loadingStatus == Failed) {
        htmlString =@"<html><body style=\"font:15px/1.33em Helvetica;color:#333;margin:0;padding:2px\"><div id=\"content\">Failed to load.</div></body></html>";
        [self.infoWebView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
    }
    
    if (loadingStatus == Loaded) {
        KGOHTMLTemplate *template;
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        
        if(_notice) {
            template = [KGOHTMLTemplate templateWithPathName:@"modules/emergency/emergency_notice_template.html"];
        
            NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setDateFormat:@"MMM d, y"];
            NSString *pubDate = [dateFormatter stringFromDate:_notice.pubDate];
        
            [values setValue:_notice.title forKey:@"TITLE"];
            [values setValue:pubDate forKey:@"DATE"];
            [values setValue:_notice.html forKey:@"BODY"];
        } else {
            template = [KGOHTMLTemplate templateWithPathName:@"modules/emergency/no_emergency_notice_template.html"];
            
        }
        [self.infoWebView loadTemplate:template values:values];
    }
    return [NSArray arrayWithObject:self.infoWebView];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if(self.contentDivHeight) {
        // height already known so just exit
        return;
    }
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"content\").offsetHeight;"];
    self.contentDivHeight = [NSNumber numberWithInt:[output intValue]];
    if(self.contentDivHeight) {
        [self reloadDataForTableView:self.tableView];
    }
}

- (void)emergencyNoticeRetrieved:(NSNotification *)notification {
    enum EmergencyNoticeStatus status = [[[notification userInfo] objectForKey:@"EmergencyStatus"] intValue];
    loadingStatus = Loaded;
    
    if(status == NoCurrentEmergencyNotice) {
        self.notice = nil;
    } else if (status == EmergencyNoticeActive) {
        // reset content values
        self.notice = [[EmergencyDataManager managerForTag:_module.tag] latestEmergency];
    }
    self.contentDivHeight = nil;
        
    [self reloadDataForTableView:self.tableView];
}

- (void)emergencyContactsRetrieved:(NSNotification *)notification {
    EmergencyDataManager *manager = [EmergencyDataManager managerForTag:_module.tag];
    self.primaryContacts = [manager primaryContacts];
    _hasMoreContact = [manager hasSecondaryContacts];    
    [self reloadDataForTableView:self.tableView];
}
@end
