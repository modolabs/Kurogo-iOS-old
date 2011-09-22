#import "ContentTableViewController.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"


@implementation ContentTableViewController
@synthesize moduleTag;
@synthesize pagesRequest, pageRequest;

@synthesize tableView = _tableView, contentView, loadingView, contentTitle;

@synthesize feedTitles, feedKeys;
@synthesize feedKey = _feedKey;

- (void)loadView
{
    [super loadView];
    
    if (self.feedKey) {
        [self requestPageContent];
        
    } else {
        self.pagesRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                            module:self.moduleTag
                                                                              path:@"pages"
                                                                            params:nil];
        self.pagesRequest.expectedResponseType = [NSDictionary class];
        [self.pagesRequest connect];
    }
    [self addLoadingView];
}

- (void)requestPageContent
{
    NSDictionary *params = [NSDictionary dictionaryWithObject:self.feedKey forKey:@"key"];
    self.pageRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:self.moduleTag                            
                                                                         path:@"page"
                                                                       params:params];
    self.pageRequest.expectedResponseType = [NSString class];
    
    [self.pageRequest connect];
}

- (void)addLoadingView
{
    self.loadingView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    loadingView.backgroundColor = [UIColor whiteColor];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    CGSize size = loadingView.bounds.size;
    indicator.center = CGPointMake(floor(size.width / 2), floor(size.height / 2));
    indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [indicator startAnimating];
    [loadingView addSubview:indicator];
    [self.view addSubview:loadingView];
}

- (void)removeLoadingView {
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
}

- (void)dealloc
{
    self.contentView = nil;
    self.loadingView = nil;
    self.moduleTag = nil;
    self.tableView = nil;
    self.feedKey = nil;

    [self.pageRequest cancel];
    self.pageRequest = nil;
    
    [self.pagesRequest cancel];
    self.pagesRequest = nil;

    [feedTitles release];
    [feedKeys release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.contentView = nil;
    self.loadingView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.tableView) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return self.feedKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    
    cell.textLabel.text = [feedTitles stringForKey:[feedKeys objectAtIndex:indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *feedKey = [feedKeys objectAtIndex:indexPath.row];
    NSString *title = [self.feedTitles objectForKey:feedKey];
        
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            feedKey, @"key",
                            title, @"title",
                            nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    if (request == self.pageRequest) {
        self.pageRequest = nil;
    }
    else if (request == self.pagesRequest) {
        self.pagesRequest = nil;
    }
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    if (request == self.pagesRequest) {
        
        DLog(@"%@", [result description]);
        
        NSDictionary *resultDict = (NSDictionary *)result;
        
        NSArray *pages = (NSArray *)[resultDict arrayForKey:@"pages"];
        NSInteger numberOfFeeds = pages.count;

        self.feedTitles = [NSMutableDictionary dictionaryWithCapacity:numberOfFeeds];
        self.feedKeys = [NSMutableArray arrayWithCapacity:numberOfFeeds];
        
        for (NSDictionary *pageDict in pages) {
            NSString *key = [pageDict nonemptyStringForKey:@"key"];
            NSString *title = [pageDict stringForKey:@"title"];
            if (key && title) {
                [feedKeys addObject:key];
                [feedTitles setValue:title forKey:key];
            }
        }
        
        // if only one feed, then directly show the feed contents in the WebView
        if (numberOfFeeds == 1) {
            self.feedKey = [feedKeys objectAtIndex:0];
            [self requestPageContent];

        } else {
            self.tableView = [[[UITableView alloc] initWithFrame:self.view.bounds
                                                           style:UITableViewStyleGrouped] autorelease];
            self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            [self.view addSubview:self.tableView];
            self.tableView.delegate = self;
            self.tableView.dataSource = self;
            
            [self removeLoadingView];
        }

    } else if (request == self.pageRequest) {
        NSString *htmlString = (NSString *)result;
        
        [self removeLoadingView];
        
        self.contentView = [[[UIWebView alloc] init] autorelease];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.frame = self.view.bounds;
        
        // TODO: this isn't the correct way to display the content
        // we want to show the title above it as well (separate from nav bar)
        [contentView loadHTMLString:htmlString baseURL:nil];
        [self.view addSubview:contentView];
        
    }
}

@end
