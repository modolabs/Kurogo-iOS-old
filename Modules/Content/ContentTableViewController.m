//
//  ContentTableViewController.m
//  Universitas
//
//  Created by Muhammad J Amjad on 3/26/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "ContentTableViewController.h"


@implementation ContentTableViewController
@synthesize moduleTag;
@synthesize request;
@synthesize webViewController;
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
    numberOfFeeds = 0;
    self.moduleTag = [tag retain];
    self = [super initWithStyle:style];
    if (self) {
        
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:self.moduleTag
                                                                         path:@"feeds"
                                                                       params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        self.request.expectedResponseType = [NSDictionary class];
        if (self.request) {
            [self.request connect];
            [self addLoadingView];
        }
        self.title = [self.moduleTag capitalizedString];
        

    }
    return self;
}

- (void) addLoadingView {
    
    loadingView = [[UIView alloc] initWithFrame:
                   CGRectMake(self.view.frame.origin.x, 
                              self.view.frame.origin.y - 50, 
                              self.view.frame.size.width, 
                              self.view.frame.size.height)];
    
    loadingView.backgroundColor = [UIColor whiteColor];
    
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingIndicator startAnimating];
    loadingIndicator.center = self.view.center;
    [loadingView addSubview:loadingIndicator];
    [self.view addSubview:loadingView];
}

- (void) removeLoadingView {
    [self.loadingIndicator stopAnimating];
    [self.loadingView removeFromSuperview];
    
    self.loadingView = nil;
    self.loadingIndicator = nil;
}


- (void) showSingleFeedWebView: (NSString *) titleString htmlString: (NSString *) htmlStringText {
    [self removeLoadingView];
    singleFeedView = [[UIWebView alloc] init];
    singleFeedView.frame = self.view.frame;
    
    [singleFeedView loadHTMLString:htmlStringText baseURL:nil];
    self.title = titleString;
    [self.view addSubview:singleFeedView];
}

- (void)dealloc
{
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
    
    
    cell.textLabel.text = [listOfFeeds objectForKey:[[listOfFeeds allKeys] objectAtIndex:indexPath.row]];
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
    
    NSString * feedKey = [[listOfFeeds allKeys] objectAtIndex:indexPath.row];
    
    webViewController = [[ContentWebView alloc] init];
    
    KGORequest *  feedRequest = [[KGORequestManager sharedManager] 
                                        requestWithDelegate:webViewController                              
                                        module:self.moduleTag                                   
                                        path:@"getFeed"                           
                                        params:[NSDictionary dictionaryWithObjectsAndKeys:feedKey, @"key", nil]];
    
    feedRequest.expectedResponseType = [NSDictionary class];
    if (feedRequest) {
        [feedRequest connect];
    
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:webViewController animated:YES];
     [webViewController release];
    }
     
}



#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    NSLog(@"%@", [result description]);
   
    NSDictionary * resultDict = (NSDictionary * ) result;
    numberOfFeeds = (int) [[resultDict objectForKey:@"totalFeeds"] intValue];
    
    listOfFeeds = [[NSMutableDictionary alloc] initWithCapacity:numberOfFeeds];
    NSArray * pages = (NSArray *)[resultDict objectForKey:@"pages"];
    
    for (int count=0; count < numberOfFeeds; count++){
        NSDictionary * pagesDictionary = [pages objectAtIndex:count];
        
        [listOfFeeds setValue:[pagesDictionary objectForKey:@"title"] forKey:[pagesDictionary objectForKey: @"key"]];
    }
    
    NSString * temp = [resultDict objectForKey:@"totalFeeds"];
    
    NSLog(@"%@", temp);
    
    // if only one feed, then directly show the feed contents in the WebView
    if (numberOfFeeds == 1) {
        
        NSDictionary * feedData = [resultDict objectForKey:@"feedData"];
        
        NSString * htmlStringText = [feedData objectForKey:@"contentBody"]; 
        NSString * titleString = [feedData objectForKey:@"title"];
        
        [self showSingleFeedWebView:titleString htmlString:htmlStringText];
        return;
    }
    
        [self.tableView reloadData];
        [self removeLoadingView];

}
@end
