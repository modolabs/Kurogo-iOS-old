#import "EmergencyHomeViewController.h"
#import "EmergencyDataManager.h"
#import "KGOHTMLTemplate.h"
#import "UIKit+KGOAdditions.h"

@interface EmergencyHomeViewController (Private)

- (void)emergencyNoticeRetrieved:(NSNotification *)notification;
- (NSArray *)noticeViewsWithtableView:(UITableView *)tableView;

@end

@implementation EmergencyHomeViewController
@synthesize contentDivHeight = _contentDivHeight;
@synthesize module = _module;
@synthesize notice = _notice;
@synthesize infoWebView = _infoWebView;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emergencyNoticeRetrieved:) name:EmergencyNoticeRetrievedNotification object:manager];
    [[EmergencyDataManager managerForTag:_module.tag] fetchLatestEmergencyNotice];
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
    if(section == 0) {
        return 1;
    }
    return 0;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {  
    if(_module.noticeFeedExists) {
        if(indexPath.row == 0 && indexPath.section == 0) {
            return [self noticeViewsWithtableView:tableView];
        }
    }
    return nil;
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
        htmlString = @"<html><body><div id=\"content\">Loading...</div></body></html>";
        [self.infoWebView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
    } else if(loadingStatus == Failed) {
        htmlString =@"<html><body><div id=\"content\">Failed to load.</div></body></html>";
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
    NSLog(@"height = %@", output);
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
@end
