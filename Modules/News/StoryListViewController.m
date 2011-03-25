#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "NewsDataManager.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "UIKit+KGOAdditions.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchDisplayController.h"
#import "NewsCategory.h"
#import "AnalyticsWrapper.h"

#define THUMBNAIL_WIDTH 76.0
#define ACCESSORY_WIDTH_PLUS_PADDING 18.0
#define STORY_TEXT_PADDING_TOP 3.0 // with 15pt titles, makes for 8px of actual whitespace
#define STORY_TEXT_PADDING_BOTTOM 7.0 // from baseline of 12pt font, is roughly 5px
#define STORY_TEXT_PADDING_LEFT 7.0
#define STORY_TEXT_PADDING_RIGHT 7.0
#define STORY_TEXT_WIDTH (320.0 - STORY_TEXT_PADDING_LEFT - STORY_TEXT_PADDING_RIGHT - THUMBNAIL_WIDTH - ACCESSORY_WIDTH_PLUS_PADDING) // 8px horizontal padding
#define STORY_TEXT_HEIGHT (THUMBNAIL_WIDTH - STORY_TEXT_PADDING_TOP - STORY_TEXT_PADDING_BOTTOM) // 8px vertical padding (bottom is less because descenders on dekLabel go below baseline)
#define STORY_TITLE_FONT_SIZE 15.0
#define STORY_DEK_FONT_SIZE 12.0

#define MAX_ARTICLES 50

@interface StoryListViewController (Private)

- (void)setupNavScroller;
- (void)setupNavScrollButtons;

- (void)setupActivityIndicator;
- (void)setStatusText:(NSString *)text;
- (void)setLastUpdated:(NSDate *)date;
- (void)setProgress:(CGFloat)value;

- (void)showSearchBar;
- (void)releaseSearchBar;
- (void)hideSearchBar;

@end

@implementation StoryListViewController

@synthesize stories;
@synthesize categories;
@synthesize activeCategoryId;
@synthesize featuredStory;
@synthesize totalAvailableResults;

- (void)loadView {
	[super loadView];
	
    self.navigationItem.title = @"News";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];
	
    self.stories = [NSArray array];
    
    tempTableSelection = nil;
    
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pruneStories) name:@"UIApplicationWillTerminateNotification" object:nil];
    
	// Story Table view
	storyTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    storyTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyTable.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    storyTable.rowHeight = 50;
    [self addTableView:storyTable];
	[storyTable release];
    
}

- (void)viewDidLoad {
	// set up results table
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height);

    // add drop shadow below nav scroller view
    UIImageView *dropShadow = [[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"common/bar-drop-shadow.png"]];
    dropShadow.frame = CGRectMake(0, navScrollView.frame.size.height, dropShadow.frame.size.width, dropShadow.frame.size.height);
    [self.view addSubview:dropShadow];
    [dropShadow release];

    [self setupActivityIndicator];
    
    [[NewsDataManager sharedManager] registerDelegate:self];
    [[NewsDataManager sharedManager] requestCategories];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	if (showingBookmarks) {
		self.stories = [[NewsDataManager sharedManager] bookmarkedStories];
        
        // we might want to do something special if all bookmarks are gone
        // but i am skeptical
        [self reloadDataForTableView:storyTable];        
	} else if (self.stories.count) {
        [self reloadDataForTableView:storyTable];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    storyTable = nil;
    navScrollView = nil;
    [navButtons release];
    navButtons = nil;
    [activityView release];
    activityView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillTerminateNotification" object:nil];
    navScrollView = nil;
    storyTable = nil;
    [stories release];
    stories = nil;
    [categories release];
    categories = nil;
    [super dealloc];
}

- (void)pruneStories {
	// delete all cached news articles that aren't bookmarked
	if (![[NSUserDefaults standardUserDefaults] boolForKey:MITNewsTwoFirstRunKey]) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT bookmarked == YES"];
		NSArray *nonBookmarkedStories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
		[[CoreDataManager sharedManager] deleteObjects:nonBookmarkedStories];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:MITNewsTwoFirstRunKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
    // retain only the 10 most recent stories for each category plus anything bookmarked (here and when saving, because we may have crashed before having a chance to prune the story list last time)
    
    
    //NSArray *categoryObjects = [self fetchCategoriesFromCoreData];
    //if ([categoryObjects count]) {
	//	self.categories = categoryObjects;
    //}
    
    // because stories are added to Core Data in separate threads, there may be merge conflicts. this thread wins when we're pruning
    // TODO: check whether -saveWithTemporaryMergePolicy accomplishes this
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] managedObjectContext];
    id originalMergePolicy = [context mergePolicy];
    [context setMergePolicy:NSOverwriteMergePolicy];

    NSMutableSet *allStoriesToSave = [NSMutableSet setWithCapacity:100];

    for (NewsCategory *aCategory in self.categories) {
        NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
        NSArray *categoryStories = [aCategory.stories sortedArrayUsingDescriptors:[NSArray arrayWithObject:postDateSortDescriptor]];
        
        // only the 10 most recent
        if ([categoryStories count] > 10) {
            [allStoriesToSave addObjectsFromArray:[categoryStories subarrayWithRange:NSMakeRange(0, 10)]];
        } else {
            [allStoriesToSave addObjectsFromArray:categoryStories];
        }
        [postDateSortDescriptor release];
        aCategory.moreStories = [NSNumber numberWithBool:YES];
        aCategory.nextSeekId = [NSNumber numberWithInt:0];
    }

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT bookmarked == YES"];
    NSMutableArray *allStories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
    NSMutableSet *allStoriesToDelete = [NSMutableSet setWithArray:allStories];
    [allStoriesToDelete minusSet:allStoriesToSave];
    [[CoreDataManager sharedManager] deleteObjects:[allStoriesToDelete allObjects]];
    [[CoreDataManager sharedManager] saveData];
    
    // put merge policy back where it was before we started
    [[[CoreDataManager sharedManager] managedObjectContext] setMergePolicy:originalMergePolicy];
}

#pragma mark -
#pragma mark NewsDataManager delegate methods
- (void)categoriesUpdated:(NSArray *)newCategories {
    self.categories = newCategories;
    NewsCategory *category = [self.categories objectAtIndex:0];
    self.activeCategoryId = category.category_id;
    [self setupNavScroller];

    // now that we have categories load the stories
    [[NewsDataManager sharedManager] requestStoriesForCategory:self.activeCategoryId loadMore:NO forceRefresh:NO]; 
}

#pragma mark -
#pragma mark Category selector

- (void)setupNavScroller {
    if(navScrollView) {
        [navScrollView removeFromSuperview];
        navScrollView = nil;
    }
    
    navScrollView = [[KGOScrollingTabstrip alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0) delegate:self buttonTitles:nil];
    navScrollView.delegate = self;
    [self.view addSubview:navScrollView];
    [self setupNavScrollButtons];
}

- (void)setupNavScrollButtons {
    navScrollView.showsSearchButton = YES;
    navScrollView.showsBookmarkButton = YES;
    for (NewsCategory *aCategory in self.categories) {
        [navScrollView addButtonWithTitle:aCategory.title];
    }
    
    [navScrollView setNeedsLayout];

	// highlight active category
    if (self.categories.count) {
        NewsCategory *firstCategory = [self.categories objectAtIndex:0];
        for (NSInteger i = 0; i < navScrollView.numberOfButtons; i++) {
            if ([[navScrollView buttonTitleAtIndex:i] isEqualToString:firstCategory.title]) {
                [navScrollView selectButtonAtIndex:i];
                break;
            }
        }
    }
}

- (void)tabstripSearchButtonPressed:(KGOScrollingTabstrip *)tabstrip {
    [self showSearchBar];
}

- (void)tabstripBookmarkButtonPressed:(KGOScrollingTabstrip *)tabstrip {
    [self switchToBookmarks];
}

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index {
    NSString *title = [tabstrip buttonTitleAtIndex:index];
    for (NewsCategory *aCategory in self.categories) {
        if ([aCategory.title isEqualToString:title]) {
            NewsCategoryId tagValue = aCategory.category_id;
            [self switchToCategory:tagValue];
            break;
        }
    }
}

#pragma mark -
#pragma mark Search UI

- (void)showSearchBar {
	if (!theSearchBar) {
		theSearchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
		theSearchBar.alpha = 0.0;
        if (!searchController) {
            searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:theSearchBar delegate:self contentsController:self];
        }
		[self.view addSubview:theSearchBar];
	}
	[self.view bringSubviewToFront:theSearchBar];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	theSearchBar.alpha = 1.0;
	[UIView commitAnimations];
    [searchController setActive:YES animated:YES];
}

- (void)hideSearchBar {
	if (theSearchBar) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchBar)];
		theSearchBar.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (void)releaseSearchBar {
    [theSearchBar removeFromSuperview];
    [theSearchBar release];
    theSearchBar = nil;
    [searchController release];
    searchController = nil;
}

#pragma mark -
#pragma mark News activity indicator

- (void)setupActivityIndicator {
    activityView = [[UIView alloc] initWithFrame:CGRectZero];
    activityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    activityView.tag = 9;
    activityView.backgroundColor = [UIColor blackColor];
    activityView.userInteractionEnabled = NO;
    
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 0, 0)];
    loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    loadingLabel.tag = 10;
    loadingLabel.text = @"Loading...";
    loadingLabel.textColor = [UIColor colorWithHexString:@"#DDDDDD"];
    loadingLabel.font = [UIFont boldSystemFontOfSize:14.0];
    loadingLabel.backgroundColor = [UIColor blackColor];
    loadingLabel.opaque = YES;
    [activityView addSubview:loadingLabel];
    loadingLabel.hidden = YES;
    [loadingLabel release];
    
    CGSize labelSize = [loadingLabel.text sizeWithFont:loadingLabel.font forWidth:self.view.bounds.size.width lineBreakMode:UILineBreakModeTailTruncation];
    
    [self.view addSubview:activityView];
    
    CGFloat bottom = CGRectGetMaxY(storyTable.frame);
    CGFloat height = labelSize.height + 8;
    activityView.frame = CGRectMake(0, bottom - height, self.view.bounds.size.width, height);
    
    UIProgressView *progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    progressBar.tag = 11;
    progressBar.frame = CGRectMake((8 + (NSInteger)labelSize.width) + 5, 0, activityView.frame.size.width - (8 + (NSInteger)labelSize.width) - 13, progressBar.frame.size.height);
    progressBar.center = CGPointMake(progressBar.center.x, (NSInteger)(activityView.frame.size.height / 2) + 1);
    [activityView addSubview:progressBar];
    progressBar.progress = 0.0;
    progressBar.hidden = YES;
    [progressBar release];

    UILabel *updatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, activityView.frame.size.width - 16, activityView.frame.size.height)];
    updatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    updatedLabel.tag = 12;
    updatedLabel.text = @"";
    updatedLabel.textColor = [UIColor colorWithHexString:@"#DDDDDD"];
    updatedLabel.font = [UIFont boldSystemFontOfSize:14.0];
    updatedLabel.textAlignment = UITextAlignmentRight;
    updatedLabel.backgroundColor = [UIColor blackColor];
    updatedLabel.opaque = YES;
    [activityView addSubview:updatedLabel];
    [updatedLabel release];
    
    // shrink table down to accomodate
    CGRect frame = storyTable.frame;
    frame.size.height = frame.size.height - height;
    storyTable.frame = frame;
}

#pragma mark -
#pragma mark Story loading

// TODO break off all of the story loading and paging mechanics into a separate NewsDataManager
// Having all of the CoreData logic stuffed into here makes for ugly connections from story views back to this list view
// It also forces odd behavior of the paging controls when a memory warning occurs while looking at a story

- (void)switchToCategory:(NewsCategoryId)category {
    if (category != self.activeCategoryId) {
		//if (self.xmlParser) {
		//	[self.xmlParser abort]; // cancel previous category's request if it's still going
		//	self.xmlParser = nil;
		//}
		self.activeCategoryId = category;
        activeCategoryHasMoreStories = YES;
		self.stories = [NSArray array];
		if ([self.stories count] > 0) {
			[storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
		[self reloadDataForTableView:storyTable];
		showingBookmarks = NO;
        
        // makes request to server if no request has been made this session
        [[NewsDataManager sharedManager] requestStoriesForCategory:self.activeCategoryId loadMore:NO forceRefresh:NO];
    }
}

- (void)switchToBookmarks {
    self.stories = [[NewsDataManager sharedManager] bookmarkedStories];
    showingBookmarks = YES;
    [self reloadDataForTableView:storyTable];
}

- (void)refresh:(id)sender {    
    if (!showingBookmarks) {
        [[NewsDataManager sharedManager] requestStoriesForCategory:self.activeCategoryId loadMore:NO forceRefresh:YES];
        return;
    }
}

- (void) storiesUpdated:(NSArray *)theStories forCategory:(NewsCategory *)category {
    if([self.activeCategoryId isEqualToString:category.category_id]) {
        self.stories = theStories;
        [self setLastUpdated:category.lastUpdated];
        activeCategoryHasMoreStories = [category.moreStories boolValue];
        [self reloadDataForTableView:storyTable];
        [storyTable flashScrollIndicators];
    }
}

- (void) storiesDidMakeProgress:(CGFloat)progress forCategoryId:(NewsCategoryId)categoryID {
    if([self.activeCategoryId isEqualToString:categoryID]) {
        [self setProgress:progress];
    }
}

- (void) storiesDidFailWithCategoryId:(NewsCategoryId)categoryID {
    if([self.activeCategoryId isEqualToString:categoryID]) {
        [self setStatusText:@"Most recent update failed!"];
    }    
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController focusSearchBarAnimated:YES];
}

#pragma mark -
#pragma mark Bottom status bar

- (void)setStatusText:(NSString *)text {
	UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
	UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
	UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
	loadingLabel.hidden = YES;
	progressBar.hidden = YES;
    activityView.alpha = 1.0;
	updatedLabel.hidden = NO;
	updatedLabel.text = text;
    
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height);
    
    [UIView beginAnimations:@"hideLastUpdated" context:nil];
    [UIView setAnimationDelay:2.0];
    [UIView setAnimationDuration:1.0];
    activityView.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)setLastUpdated:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
	[self setStatusText:(date) ? [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Last Updated", nil), [formatter stringFromDate:date]] : nil];
    [formatter release];
}

- (void)setProgress:(CGFloat)value {
	UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
	UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
	UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
	loadingLabel.hidden = NO;
	progressBar.hidden = NO;
	updatedLabel.hidden = YES;
	progressBar.progress = value;

    activityView.alpha = 1.0;
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height - activityView.frame.size.height);
     
}

#pragma mark -
#pragma mark KGOTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.stories.count > 0) ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = 0;
    switch (section) {
        case 0:
            n = self.stories.count;
            
            if(!showingBookmarks) {
                NSInteger moreStories = [[NewsDataManager sharedManager] loadMoreStoriesQuantityForCategoryId:activeCategoryId];
                // don't show "load x more" row if
                if (moreStories > 0 ) { // category has more stories
                    n += 1; // + 1 for the "Load more articles..." row
                }
                break;
            }
    }
	return n;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.stories.count) {

        NSInteger loadMoreQuantity = [[NewsDataManager sharedManager] loadMoreStoriesQuantityForCategoryId:self.activeCategoryId];

        NSString *title = [NSString stringWithFormat:@"Load %d more articles...", loadMoreQuantity];
        UIColor *textColor;
        
        //
        if (![[NewsDataManager sharedManager] busy]) { // disable when a load is already in progress
            textColor = [UIColor colorWithHexString:@"#1A1611"]; // enable
        } else {
            textColor = [UIColor colorWithHexString:@"#999999"]; // disable
        }
        //
        
        return [[^(UITableViewCell *cell) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.textLabel.textColor = textColor;
        } copy] autorelease];
        
    } else {
        return [[^(UITableViewCell *cell) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } copy] autorelease];
    }
}

#define FEATURE_IMAGE_HEIGHT 180.0
#define FEATURE_TEXT_HEIGHT 60.0

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == self.stories.count) {
        return nil;
        
    } else {
        NSMutableArray *views = [NSMutableArray array];
        
        CGFloat yOffset;
        NSString *placeholderImageName = nil;
        NewsImage *image = nil;
        NewsStory *story;
        CGRect thumbnailFrame;
        
        if (self.featuredStory != nil  // we have a featured story
            && !showingBookmarks          // we are not looking at bookmarks
            && indexPath.row == 0)
        {
            yOffset = FEATURE_IMAGE_HEIGHT - FEATURE_TEXT_HEIGHT;
            story = self.featuredStory;
            image = story.featuredImage;
            placeholderImageName = @"news/news-placeholder-a1.png";
            thumbnailFrame = CGRectMake(0, 0, tableView.frame.size.width, FEATURE_IMAGE_HEIGHT);
        } else {
            yOffset = 0;
            story = [self.stories objectAtIndex:indexPath.row];
        }
        
        UIFont *titleFont = [UIFont boldSystemFontOfSize:STORY_TITLE_FONT_SIZE];
        UIColor *titleColor = [story.read boolValue] ? [UIColor colorWithHexString:@"#666666"] : [UIColor blackColor];
        UIFont *dekFont = [UIFont systemFontOfSize:STORY_DEK_FONT_SIZE];
        UIColor *dekColor = [UIColor colorWithHexString:@"#0D0D0D"];
        
        // Calculate height
        CGFloat availableHeight = FEATURE_TEXT_HEIGHT;
        CGSize titleDimensions = [story.title sizeWithFont:titleFont constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
        availableHeight -= titleDimensions.height;
        
        CGSize dekDimensions = CGSizeZero;
        // if not even one line will fit, don't show the deck at all
        if (availableHeight > dekFont.lineHeight) {
            dekDimensions = [story.summary sizeWithFont:dekFont constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
        }
        
        CGRect titleFrame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                                       STORY_TEXT_PADDING_TOP + yOffset, 
                                       STORY_TEXT_WIDTH, 
                                       titleDimensions.height);
        
        CGRect dekFrame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                                     ceil(CGRectGetMaxY(titleFrame)), 
                                     STORY_TEXT_WIDTH, 
                                     dekDimensions.height);
        
        
        // Title View
        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:titleFrame] autorelease];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = titleFont;
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        titleLabel.text = story.title;
        titleLabel.textColor = titleColor;
        titleLabel.highlightedTextColor = [UIColor whiteColor];

        [views addObject:titleLabel];
        
        // Summary View
        UILabel *dekLabel = [[[UILabel alloc] initWithFrame:dekFrame] autorelease];
        dekLabel.text = story.summary;
        dekLabel.font = dekFont;
        dekLabel.textColor = dekColor;
        dekLabel.numberOfLines = 0;
        dekLabel.lineBreakMode = UILineBreakModeTailTruncation;
        dekLabel.highlightedTextColor = [UIColor whiteColor];
        dekLabel.backgroundColor = [UIColor clearColor];
        
        [views addObject:dekLabel];
        
        // ThumbnailView
        MITThumbnailView *thumbnailView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(0, 0, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH)] autorelease];
        //thumbnailView.placeholderImageName = placeholderImageName;
        if(story.thumbImage) {
            thumbnailView.imageURL = story.thumbImage.url;
            if(story.thumbImage.data) {
                thumbnailView.imageData = story.thumbImage.data;
            }
            thumbnailView.delegate = self;
            [thumbnailView loadImage];
        }
        
        [views addObject:thumbnailView];
        
        return views;
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    [[NewsDataManager sharedManager] saveImageData:data url:thumbnail.imageURL];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.row == self.stories.count) {
        if(![[NewsDataManager sharedManager] busy]) {
            [[NewsDataManager sharedManager] requestStoriesForCategory:self.activeCategoryId loadMore:YES forceRefresh:NO];
        }
	} else {
        //if (self.featuredStory != nil  // we have a featured story
        //    && !showingBookmarks          // we are not looking at bookmarks
        //    && indexPath.row == 0)
        //{
        //    story = self.featuredStory;
        //} else {
        //    story = [self.stories objectAtIndex:indexPath.row];
        //}
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:indexPath forKey:@"indexPath"];
        [params setObject:self.stories forKey:@"stories"];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:NewsTag params:params];
	}
}


#pragma KGOSearchDisplayDelegate
- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return NO;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:NewsTag];
}
      
- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return NewsTag;
}
          
- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"story", nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:NewsTag params:params];
}
      
- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self hideSearchBar];
}
@end
