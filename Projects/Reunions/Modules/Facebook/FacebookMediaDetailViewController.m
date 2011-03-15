#import "FacebookMediaDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "FacebookModel.h"

@implementation FacebookMediaDetailViewController

@synthesize post, posts, tableView = _tableView;
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
- (void)dealloc
{
    [_comments release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender {
    FacebookCommentViewController *vc = [[[FacebookCommentViewController alloc] initWithNibName:@"FacebookCommentViewController" bundle:nil] autorelease];
    vc.delegate = self;
    vc.post = self.post;
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:vc animated:YES];
}

- (IBAction)likeButtonPressed:(UIBarButtonItem *)sender {
    _likeButton.enabled = NO;
    if ([_likeButton.title isEqualToString:@"Like"]) {
        [[KGOSocialMediaController sharedController] likeFacebookPost:self.post receiver:self callback:@selector(didLikePost:)];
    } else if ([_likeButton.title isEqualToString:@"Unlike"]) {
        [[KGOSocialMediaController sharedController] unlikeFacebookPost:self.post receiver:self callback:@selector(didUnlikePost:)];
    }
}

- (void)didLikePost:(id)result {
    DLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {
        _likeButton.enabled = YES;
        _likeButton.title = @"Unlike";
    }
}

- (void)didUnlikePost:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {
        _likeButton.enabled = YES;
        _likeButton.title = @"Like";
    }
}

- (IBAction)bookmarkButtonPressed:(UIBarButtonItem *)sender {

}

- (void)getCommentsForPost {
    NSString *objectID = self.post.postIdentifier.length ? self.post.postIdentifier : self.post.identifier;
    NSString *path = [NSString stringWithFormat:@"%@/comments", objectID];
    [[KGOSocialMediaController sharedController] requestFacebookGraphPath:path
                                                                 receiver:self
                                                                 callback:@selector(didReceiveComments:)];
}

- (void)didReceiveComments:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *comments = [resultDict arrayForKey:@"data"];
        for (NSDictionary *commentData in comments) {
            FacebookComment *aComment = [FacebookComment commentWithDictionary:commentData];
            aComment.parent = self.post;
        }
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        [_comments release];
        _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
        
        [_tableView reloadData];
    }
}

- (void)uploadDidComplete:(FacebookPost *)result {
    FacebookComment *aComment = (FacebookComment *)result;
    aComment.parent = self.post;
    
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] dismissAppModalViewControllerAnimated:YES];
    [_tableView reloadData];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.rowHeight = 100;
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    if (self.post) {
        KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    }
    
    [self displayPost];
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

- (void)displayPost {
    // subclasses should override this
}

#pragma mark - KGODetailPager

- (void)pager:(KGODetailPager *)pager showContentForPage:(id<KGOSearchResult>)content {
    [[KGOSocialMediaController sharedController] disconnectFacebookRequests:self]; // stop getting data for previous post
    
    self.post = (FacebookParentPost *)content;
    [self displayPost];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    [_tableView reloadData];
}

- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.posts.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.posts objectAtIndex:indexPath.row];
}

#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FacebookComment *aComment = [_comments objectAtIndex:indexPath.row];
    NSLog(@"%@", [aComment description]);
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger commentTag = 80;
    NSInteger authorTag = 81;
    NSInteger dateTag = 82;
    
    UILabel *commentLabel = (UILabel *)[cell.contentView viewWithTag:commentTag];
    if (!commentLabel) {
        UIFont *commentFont = [UIFont systemFontOfSize:15];
        commentLabel = [UILabel multilineLabelWithText:aComment.text font:commentFont width:tableView.frame.size.width - 20];
        commentLabel.tag = commentTag;
        CGRect frame = commentLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 5;
        commentLabel.frame = frame;
    } else {
        commentLabel.text = aComment.text;
    }
    [cell.contentView addSubview:commentLabel];
    
    UILabel *authorLabel = (UILabel *)[cell.contentView viewWithTag:authorTag];
    if (!authorLabel) {
        UIFont *authorFont = [UIFont systemFontOfSize:13];
        authorLabel = [UILabel multilineLabelWithText:aComment.owner.name font:authorFont width:tableView.frame.size.width - 20];
        authorLabel.tag = authorTag;
        CGRect frame = authorLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 80;
        authorLabel.frame = frame;
    } else {
        authorLabel.text = aComment.owner.name;
    }
    [cell.contentView addSubview:authorLabel];
    
    UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:dateTag];
    // TODO: use nsdateformatter, not this
    NSString *dateString = [NSString stringWithFormat:@"%@", aComment.date];
    if (!dateLabel) {
        UIFont *dateFont = [UIFont systemFontOfSize:13];
        dateLabel = [UILabel multilineLabelWithText:dateString font:dateFont width:tableView.frame.size.width - 20];
        dateLabel.tag = dateTag;
        CGRect frame = dateLabel.frame;
        frame.origin.x = 160;
        frame.origin.y = 80;
        dateLabel.frame = frame;
    } else {
        dateLabel.text = dateString;
    }
    [cell.contentView addSubview:dateLabel];
    
    return cell;
}

@end
