#import "KGOAppDelegate+ModuleAdditions.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "NewsDataController.h"
#import "NewsStory.h"
#import "NewsImage.h"
#import "CoreDataManager.h"
#import "UIKit+KGOAdditions.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchDisplayController.h"
#import "NewsCategory.h"
#import "AnalyticsWrapper.h"
#import "NewsStoryTableViewCell.h"

@interface StoryListViewController (Private)

- (void)setupNavScrollButtons;

- (void)setStatusText:(NSString *)text;
- (void)setLastUpdated:(NSDate *)date;
- (void)setProgress:(CGFloat)value;

- (void)showSearchBar;
- (void)hideSearchBar;

- (NewsCategory *)activeCategory;

@end

@implementation StoryListViewController

@synthesize dataManager;
@synthesize stories;
@synthesize categories;
@synthesize activeCategoryId;
@synthesize featuredStory;

- (void)loadView {
	[super loadView];
}

- (void)viewDidLoad {
    
    _navScrollView.delegate = self;
	
    _storyTable.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self addTableView:_storyTable];
	
    // TODO: configure these strings
    self.navigationItem.title = @"News";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Headlines"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:nil
                                                                             action:nil] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                            target:self
                                                                                            action:@selector(refresh:)] autorelease];
    [self.dataManager fetchCategories];
}

- (void)viewWillAppear:(BOOL)animated {
    //[self setupNavScrollButtons]; // This is called from dataConroller:didRetrieveCategories: once the categories are retrieved
    
    [super viewWillAppear:animated];
    /*
	if (showingBookmarks) {
		self.stories = [self.dataManager bookmarkedStories];
        
        // we might want to do something special if all bookmarks are gone
        // but i am skeptical
        [self reloadDataForTableView:storyTable];        
	} else if (self.stories.count) {
        [self reloadDataForTableView:storyTable];
    }
     */
}

// TODO: flash last updated text in viewDidAppear
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillTerminateNotification" object:nil];
    
    [stories release];
    [categories release];
    [super dealloc];
}

#pragma mark -
#pragma mark NewsDataController delegate methods

- (void)dataController:(NewsDataController *)controller didFailWithCategoryId:(NSString *)categoryId
{
    if([self.activeCategoryId isEqualToString:categoryId]) {
        [self setStatusText:NSLocalizedString(@"Update failed", @"news story update failed")];
    }
}

- (void)dataController:(NewsDataController *)controller didMakeProgress:(CGFloat)progress
{
    [self setProgress:progress];
}
/*
- (void)dataController:(NewsDataController *)controller didPruneStoriesForCategoryId:(NSString *)categoryId
{
}
*/
- (void)dataController:(NewsDataController *)controller didReceiveSearchResults:(NSArray *)results
{
}

- (void)dataController:(NewsDataController *)controller didRetrieveCategories:(NSArray *)theCategories
{
    self.categories = theCategories;
    
   /* This is decided again later in setupNavScrollButtons
    if (!self.activeCategoryId && theCategories.count) {
        NewsCategory *category = [theCategories objectAtIndex:0];
        self.activeCategoryId = category.category_id;
    }
    */
    [self setupNavScrollButtons]; // update button pressed states
    
    // now that we have categories load the stories
    if (self.activeCategoryId) {
        [self.dataManager fetchStoriesForCategory:self.activeCategoryId startId:nil];
    }
}

- (void)dataController:(NewsDataController *)controller didRetrieveStories:(NSArray *)theStories
{
    self.stories = theStories;
    [self setLastUpdated:[NSDate date]];
    [self reloadDataForTableView:_storyTable];
    [_storyTable flashScrollIndicators];
}

#pragma mark -
#pragma mark Category selector

- (void)setupNavScrollButtons {
    BOOL bookmarksExist = [self.dataManager bookmarkedStories].count > 0;
    if (self.categories.count > 1 || bookmarksExist) {
        // TODO: need criteria for showing search button
        _navScrollView.showsSearchButton = YES;
        _navScrollView.showsBookmarkButton = bookmarksExist;
        
        NewsCategory *activeCategory = nil;
        for (NewsCategory *aCategory in self.categories) {
            [_navScrollView addButtonWithTitle:aCategory.title];
            
            if (!activeCategory // choose the first category if nothing matches
                || [aCategory.category_id isEqualToString:self.activeCategoryId])
            {
                activeCategory = aCategory;
            }
        }
        
        [_navScrollView setNeedsLayout];
        
        for (NSInteger i = 0; i < _navScrollView.numberOfButtons; i++) {
            if ([[_navScrollView buttonTitleAtIndex:i] isEqualToString:activeCategory.title]) {
                [_navScrollView selectButtonAtIndex:i];
                break;
            }
        }
        
    } else {
        [_navScrollView removeFromSuperview];
        _navScrollView = nil;
        
        CGFloat dh = _activityView.hidden ? 0 : _activityView.frame.size.height;
        _storyTable.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - dh);
    }
}

- (void)tabstripSearchButtonPressed:(KGOScrollingTabstrip *)tabstrip {
    [self showSearchBar];
}

- (void)tabstripBookmarkButtonPressed:(KGOScrollingTabstrip *)tabstrip {
    self.activeCategoryId = nil; 
    [self switchToBookmarks];
}

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index {
    NSString *title = [tabstrip buttonTitleAtIndex:index];
    for (NewsCategory *aCategory in self.categories) {
        if ([aCategory.title isEqualToString:title]) {
            NSString *tagValue = aCategory.category_id;
            [self switchToCategory:tagValue];
            break;
        }
    }
}

- (void)switchToCategory:(NSString *)category {
    showingBookmarks = NO;
    if (![category isEqualToString:self.activeCategoryId]) {
		self.activeCategoryId = category;
        [self.dataManager fetchStoriesForCategory:self.activeCategoryId startId:nil];
        
        // makes request to server if no request has been made this session
        //[self.dataManager requestStoriesForCategory:self.activeCategoryId loadMore:NO forceRefresh:NO];
    }
}

- (void)switchToBookmarks {
    showingBookmarks = YES;
    [self.dataManager fetchBookmarks];
}
//START HERE TO DEBUG NEWS BOOKMARK ISSUE
- (void)refresh:(id)sender {    
    if (!showingBookmarks) {
        [self.dataManager requestStoriesForCategory:self.activeCategoryId afterId:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController focusSearchBarAnimated:YES];
}

#pragma mark -
#pragma mark Search UI

- (void)showSearchBar {
	if (!theSearchBar) {
		theSearchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0)];
        theSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		theSearchBar.alpha = 0.0;
        if (!searchController) {
            searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:theSearchBar
                                                                            delegate:self
                                                                  contentsController:self];
            
            if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
                searchController.showsSearchOverlay = NO;
            }
        }
		[self.view addSubview:theSearchBar];
	}
	[self.view bringSubviewToFront:theSearchBar];
    [UIView animateWithDuration:0.4 animations:^(void) {
        theSearchBar.alpha = 1.0;
    }];
    [searchController setActive:YES animated:YES];
}

- (void)hideSearchBar {
	if (theSearchBar) {
        [UIView animateWithDuration:0.4 animations:^(void) {
            theSearchBar.alpha = 0;
        } completion:^(BOOL finished) {
            [theSearchBar removeFromSuperview];
            [theSearchBar release];
            theSearchBar = nil;
            [searchController release];
            searchController = nil;
        }];
	}
}

#pragma mark -
#pragma mark Bottom status bar

- (void)setStatusText:(NSString *)text {
    _loadingLabel.hidden = YES;
    _progressView.hidden = YES;
    _activityView.alpha = 1.0;
	_lastUpdateLabel.hidden = NO;
	_lastUpdateLabel.text = text;
    
    CGFloat y = _navScrollView != nil ? _navScrollView.frame.size.height : 0;
    _storyTable.frame = CGRectMake(0, y, self.view.bounds.size.width, self.view.bounds.size.height - y);
    
    [UIView animateWithDuration:1.0 delay:2.0 options:0 animations:^(void) {
        _activityView.alpha = 0;
    } completion:^(BOOL finished) {
        _activityView.hidden = YES;
    }];
}

- (void)setLastUpdated:(NSDate *)date {
    if (date) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [self setStatusText:[NSString stringWithFormat:@"%@ %@",
                             NSLocalizedString(@"Last Updated", nil),
                             [formatter stringFromDate:date]]];
        [formatter release];
    }
}

- (void)setProgress:(CGFloat)value {
	_loadingLabel.hidden = NO;
	_progressView.hidden = NO;
	_lastUpdateLabel.hidden = YES;
	_progressView.progress = value;

    _activityView.hidden = NO;
    _activityView.alpha = 1.0;
    CGFloat y = _navScrollView != nil ? _navScrollView.frame.size.height : 0;
    _storyTable.frame = CGRectMake(0, y, self.view.bounds.size.width,
                                   self.view.bounds.size.height - y - _activityView.frame.size.height);
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.stories.count > 0) ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = self.stories.count;
    if ([self.dataManager canLoadMoreStories]) {
        n++;
    }
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row == self.stories.count) {
        static NSString *loadMoreIdentifier = @"loadmore";
        cell = [tableView dequeueReusableCellWithIdentifier:loadMoreIdentifier];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:loadMoreIdentifier] autorelease];
        }
        cell.textLabel.text = NSLocalizedString(@"Load more stories", @"new story list");
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        // TODO: set color to #999999 while things are loading
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#1A1611"];
        
    } else {
        NSString *cellIdentifier = [NewsStoryTableViewCell commonReuseIdentifier];
        cell = (NewsStoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            [[NSBundle mainBundle] loadNibNamed:@"NewsStoryTableViewCell" owner:self options:nil];
            cell = _storyCell;
        }
        [(NewsStoryTableViewCell *)cell setStory:[self.stories objectAtIndex:indexPath.row]];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.stories.count) {
        NewsStory *story = [self.stories lastObject];
        NSString *lastId = story.identifier;
        self.dataManager.currentStories = self.stories; 
        [self.dataManager requestStoriesForCategory:self.activeCategoryId afterId:lastId];

	} else {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:indexPath forKey:@"indexPath"];
        [params setObject:self.stories forKey:@"stories"];
        [params setObject:self.dataManager.currentCategory forKey:@"category"];
        
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.dataManager.moduleTag params:params];
	}
}

#pragma mark - KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return NO;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:self.dataManager.moduleTag];
}
      
- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return self.dataManager.moduleTag;
}
          
- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder didSelectResult:(id<KGOSearchResult>)aResult {
    NewsStory *story = aResult;
    if([[story hasBody] boolValue]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"story", nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.dataManager.moduleTag params:params];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:story.link]];
    }
}
      
- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self hideSearchBar];
}

@end
