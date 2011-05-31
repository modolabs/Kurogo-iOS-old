//
//  ContentTableViewController.m
//  Universitas
//
//  Created by Muhammad J Amjad on 3/26/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "ContentTableViewController.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"


@implementation ContentTableViewController
@synthesize moduleTag;
@synthesize request;
@synthesize loadingIndicator;
@synthesize loadingView;
@synthesize singleFeedView;

/************************************************************************************************* 
 * 
 *  Call this function from the file extending this.
 *
 * ***********************************************************************************************/


- (id)initWithStyle:(UITableViewStyle)style moduleTag:(NSString *) tag
{

    self = [super initWithStyle:style];
    if (self) {
        self.moduleTag = tag;
        self.title = [self.moduleTag capitalizedString];
        numberOfFeeds = 0;
       
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:self.moduleTag
                                                                         path:@"feeds"
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


- (void) showSingleFeedWebView: (NSString *) titleString htmlString: (NSString *) htmlStringText {
    [self removeLoadingView];
    self.singleFeedView = [[[UIWebView alloc] init] autorelease];
    singleFeedView.frame = self.view.bounds;
    
    [singleFeedView loadHTMLString:htmlStringText baseURL:nil];
    self.title = titleString;
    [self.view addSubview:singleFeedView];
}

- (void)dealloc
{
    self.singleFeedView = nil;
    self.loadingIndicator = nil;
    self.loadingView = nil;
    self.moduleTag = nil;
    [listOfFeeds release];
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
    self.singleFeedView = nil;
    self.loadingIndicator = nil;
    self.loadingView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    return numberOfFeeds;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    
    cell.textLabel.text = [listOfFeeds stringForKey:[feedKeys objectAtIndex:indexPath.row] nilIfEmpty:NO];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString * feedKey = [feedKeys objectAtIndex:indexPath.row];
        
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:feedKey, @"key", nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    DLog(@"%@", [result description]);
   
    NSDictionary *resultDict = (NSDictionary *)result; 
    numberOfFeeds = [resultDict integerForKey:@"totalFeeds"];
    
    listOfFeeds = [[NSMutableDictionary alloc] initWithCapacity:numberOfFeeds];
    feedKeys = [[NSMutableArray alloc] initWithCapacity:numberOfFeeds];
    
    NSArray * pages = (NSArray *)[resultDict arrayForKey:@"pages"];
    
    for (int count=0; count < numberOfFeeds; count++){
        NSDictionary * pagesDictionary = [pages objectAtIndex:count];
        NSString *key = [pagesDictionary stringForKey:@"key" nilIfEmpty:YES];
        if (key) {
            [feedKeys addObject:key];
            
            NSString *title = [pagesDictionary stringForKey:@"title" nilIfEmpty:NO];
            [listOfFeeds setValue:title forKey:key];
        }
    }
    
    // if only one feed, then directly show the feed contents in the WebView
    if (numberOfFeeds == 1) {
        
        NSDictionary * feedData = [resultDict dictionaryForKey:@"feedData"];
        
        NSString * htmlStringText = [feedData stringForKey:@"contentBody" nilIfEmpty:NO]; 
        NSString * titleString = [feedData stringForKey:@"title" nilIfEmpty: NO];
        
        [self showSingleFeedWebView:titleString htmlString:htmlStringText];
        return;
    }
    
    [self.tableView reloadData];
    [self removeLoadingView];

}

@end
