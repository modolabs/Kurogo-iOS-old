#import "KGOAppDelegate.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "StoryThumbnailView.h"
#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "UIKit+KGOAdditions.h"
#import "NavScrollerView.h"
#import "KGOSearchDisplayController.h"
#import "MITUIConstants.h"
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

#define SEARCH_BUTTON_TAG 7947
#define BOOKMARK_BUTTON_TAG 7948

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
@synthesize searchResults;
@synthesize searchQuery;
@synthesize categories;
@synthesize activeCategoryId;
@synthesize xmlParser;
@synthesize featuredStory;
@synthesize totalAvailableResults;

static NSInteger numTries = 0;

- (void)loadView {
	[super loadView];
	
    self.navigationItem.title = @"News";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];
	
    self.stories = [NSArray array];
	self.searchQuery = nil;
	self.searchResults = nil;
    
    tempTableSelection = nil;
    
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pruneStories) name:@"UIApplicationWillTerminateNotification" object:nil];
    
	// Story Table view
	storyTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    storyTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	storyTable.delegate = self;
	storyTable.dataSource = self;
    storyTable.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    storyTable.rowHeight = 50;
	[self.view addSubview:storyTable];
	[storyTable release];
}

- (void)viewDidLoad {
    [self setupNavScroller];

	// set up results table
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height);

    // add drop shadow below nav scroller view
    UIImageView *dropShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/bar-drop-shadow.png"]];
    dropShadow.frame = CGRectMake(0, navScrollView.frame.size.height, dropShadow.frame.size.width, dropShadow.frame.size.height);
    [self.view addSubview:dropShadow];
    [dropShadow release];

    [self setupActivityIndicator];
    [self loadFromCache];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	// show / hide the bookmarks category
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    NSMutableArray *allBookmarkedStories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
	hasBookmarks = ([allBookmarkedStories count] > 0) ? YES : NO;
	[self setupNavScrollButtons];
	if (showingBookmarks) {
		[self loadFromCache];
		if (!hasBookmarks) {
			[self buttonPressed:[navButtons objectAtIndex:0]];
		}
	}
    // Unselect the selected row
    [tempTableSelection release];
	tempTableSelection = [[storyTable indexPathForSelectedRow] retain];
	if (tempTableSelection) {
        [storyTable beginUpdates];
		[storyTable deselectRowAtIndexPath:tempTableSelection animated:YES];
        [storyTable endUpdates];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (tempTableSelection) {
        [storyTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:tempTableSelection] withRowAnimation:UITableViewRowAnimationNone];
        [tempTableSelection release];
        tempTableSelection = nil;
	}
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
    [xmlParser release];
    xmlParser = nil;
    [super dealloc];
}

- (NSArray *)fetchCategoriesFromCoreData {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isMainCategory = YES"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"category_id" ascending:YES];
    NSArray *categoryObjects = [[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    return categoryObjects;
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
    
    
    NSArray *categoryObjects = [self fetchCategoriesFromCoreData];
    if ([categoryObjects count]) {
		self.categories = categoryObjects;
    }
    
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
        aCategory.expectedCount = [NSNumber numberWithInteger:0];
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

-(void)refreshCategories {
	JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	BOOL success = [request requestObjectFromModule:@"news" command:@"channels" parameters:nil];
	if (!success) {
		DLog(@"failed to dispatch request");
	}
}

#pragma mark -
#pragma mark Category selector

- (void)setupNavScroller {
    if (!navScrollView) {
        navScrollView = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
        navScrollView.navScrollerDelegate = self;
        [self.view addSubview:navScrollView];
    }
    [self setupNavScrollButtons];
}

- (void)setupNavScrollButtons {
    
    [navScrollView removeAllButtons];

    UIButton *searchButton = [navScrollView buttonWithTag:SEARCH_BUTTON_TAG];
    if (!searchButton) {
        UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
        [searchButton setImage:searchImage forState:UIControlStateNormal];
        searchButton.tag = SEARCH_BUTTON_TAG;
        // TODO: adjust so that magnifying class lines up when searchbar is shown
        navScrollView.currentXOffset += 4.0;
        [navScrollView addButton:searchButton shouldHighlight:NO];
    }
	
	if (hasBookmarks) {
        UIButton *bookmarkButton = [navScrollView buttonWithTag:BOOKMARK_BUTTON_TAG];
        if (!bookmarkButton) {
            UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *bookmarkImage = [UIImage imageNamed:MITImageNameBookmark];
            [bookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
            bookmarkButton.tag = BOOKMARK_BUTTON_TAG;
            [navScrollView addButton:bookmarkButton shouldHighlight:YES];
        }
	}
    
    for (NewsCategory *aCategory in self.categories) {
        NewsCategoryId tagValue = (NewsCategoryId)[aCategory.category_id intValue];
        UIButton *aButton = [navScrollView buttonWithTag:tagValue];
        if (!aButton) {
            aButton = [UIButton buttonWithType:UIButtonTypeCustom];
            aButton.tag = tagValue;
            NSString *buttonTitle = aCategory.title;
            [aButton setTitle:buttonTitle forState:UIControlStateNormal];
            [navScrollView addButton:aButton shouldHighlight:YES];
        }
    }
    
    [navScrollView setNeedsLayout];

	// highlight active category
    UIButton *homeButton = [navScrollView buttonWithTag:self.activeCategoryId];
    [navScrollView buttonPressed:homeButton];
}

- (void)buttonPressed:(id)sender {
    
    UIButton *pressedButton = (UIButton *)sender;
    
    if (pressedButton.tag == SEARCH_BUTTON_TAG) {
        [self showSearchBar];
    } else {
        [self switchToCategory:pressedButton.tag];
    }
}

#pragma mark -
#pragma mark Search UI

- (void)presentSearchResults:(NSArray *)results searchText:(NSString *)searchText {
    [self showSearchBar];
    [searchController setActive:NO animated:NO];
    
    theSearchBar.text = searchText;
    self.searchQuery = searchText;
    self.searchResults = results;
    self.stories = results;
    // since we're coming in from federated search, manually set this
    searchIndex = 11;
    
    [storyTable reloadData];
}

- (void)showSearchBar {
	if (!theSearchBar) {
		theSearchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
		theSearchBar.delegate = self;
		theSearchBar.alpha = 0.0;
        CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width,
                                  self.view.frame.size.height - (theSearchBar.frame.size.height + activityView.frame.size.height));
        if (!searchController) {
            searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:theSearchBar delegate:self contentsController:self];
        }
        //searchController = [[KGOSearchDisplayController alloc] initWithFrame:frame searchBar:theSearchBar contentsController:self];
        //searchController.delegate = self;
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
}

- (void)searchOverlayTapped {
    // don't get rid of search results
	// if there is a search result already up
    if (!self.searchResults) {
        [self searchBarCancelButtonClicked:theSearchBar];
    }
}

#pragma mark UISearchBar delegation

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {	
	// cancel any outstanding search
	if (self.xmlParser) {
		[self.xmlParser abort]; // cancel previous category's request if it's still going
		self.xmlParser = nil;
	}
	
	// hide search interface
	[self hideSearchBar];
    self.searchResults = nil;
    [self loadFromCache];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	self.searchQuery = searchBar.text;
	[self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	// when query is cleared, clear search result and show category instead
	if ([searchText length] == 0) {
		if ([self.searchResults count] > 0) {
			[storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
		self.searchResults = nil;
		[self loadFromCache];
	}
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
    numTries = 0;
    if (category != self.activeCategoryId) {
		if (self.xmlParser) {
			[self.xmlParser abort]; // cancel previous category's request if it's still going
			self.xmlParser = nil;
		}
		self.activeCategoryId = category;
		//self.stories = nil;
		if ([self.stories count] > 0) {
			[storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
		//[storyTable reloadData];
		showingBookmarks = (category == BOOKMARK_BUTTON_TAG) ? YES : NO;
		[self loadFromCache]; // makes request to server if no request has been made this session
    }
}

- (void)refresh:(id)sender {
    numTries = 0;
    
	if (!self.searchResults) {
		// get active category
		NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];

		// set its expectedCount to 0
		[aCategory setValue:[NSNumber numberWithInteger:0] forKey:@"expectedCount"];
		
		// reload
		[self loadFromCache];
	}
	else {
		[self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
	}

}

- (void)loadFromCache {
	// if showing bookmarks, show those instead
	if (showingBookmarks) {
		[self setStatusText:@""];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
		NSMutableArray *allBookmarkedStories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
		self.stories = allBookmarkedStories;
		
	} else {
		// load what's in CoreData, up to categoryCount
		NSPredicate *predicate = nil;
		NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
		NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
		NSArray *sortDescriptors = [NSArray arrayWithObjects:/*featuredSortDescriptor,*/ postDateSortDescriptor, storyIdSortDescriptor, nil];
		[storyIdSortDescriptor release];
		[postDateSortDescriptor release];
		
		if (self.activeCategoryId == 0) {//NewsCategoryIdTopNews) {
			predicate = [NSPredicate predicateWithFormat:@"topStory == YES"];
		} else {
			predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", self.activeCategoryId];
		}
		
		// if maxLength == 0, nothing's been loaded from the server this session -- show up to 10 results from core data
		// else show up to maxLength
		NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
		NewsCategory *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];

		DLog(@"activecategoryid: %d", self.activeCategoryId);
        NSDate *lastUpdatedDate = [aCategory valueForKey:@"lastUpdated"];

		[self setLastUpdated:lastUpdatedDate];
		
		NSInteger maxLength = [[aCategory valueForKey:@"expectedCount"] integerValue];
		NSInteger resultsCount = [results count];
		if (maxLength == 0) {
			[self loadFromServer:NO]; // this creates a loop which will keep trying until there is at least something in this category
			// TODO: make sure this doesn't become an infinite loop.
			maxLength = 10;
		}
		if (maxLength > resultsCount) {
			maxLength = resultsCount;
		}
        
        // grab the first featured story from the list, regardless of pubdate
        NSArray *featuredStories = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(featured == YES)"]];
        if ([featuredStories count]) {
            self.featuredStory = [featuredStories objectAtIndex:0];
        }
        
        NSMutableArray *storyCandidates = [NSMutableArray arrayWithArray:[results subarrayWithRange:NSMakeRange(0, maxLength)]];
        
        if ([storyCandidates containsObject:self.featuredStory]) {
            [storyCandidates removeObject:self.featuredStory];
            self.stories = [[NSArray arrayWithObject:self.featuredStory] arrayByAddingObjectsFromArray:storyCandidates];
        } else {
            self.stories = storyCandidates;
        }
	}
	[storyTable reloadData];
    [storyTable flashScrollIndicators];
}

- (void)loadFromServer:(BOOL)loadMore {
    
    // make an asynchronous call for more stories
    
    // start new request
    NewsStory *lastStory = [self.stories lastObject];
    DLog(@"%@", [lastStory title]);
    NSInteger lastStoryId = (loadMore) ? [lastStory.story_id integerValue] : 0;
    if (self.xmlParser) {
		[self.xmlParser abort];
	}
    
    if (numTries < 3) {
        self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
        xmlParser.delegate = self;
        [xmlParser loadStoriesForCategory:self.activeCategoryId afterStoryId:lastStoryId count:10]; // count doesn't do anything at the moment (no server support)
        numTries++;
    }
}

- (void)loadSearchResultsFromCache {
	// make a predicate for everything with the search flag
    NSPredicate *predicate = nil;
    NSSortDescriptor *relevanceSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"searchResult" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:relevanceSortDescriptor];
    [relevanceSortDescriptor release];
    
	predicate = [NSPredicate predicateWithFormat:@"searchResult > 0"];
    
    // show everything that comes back
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
	
    NSInteger resultsCount = [results count];
	
	[self setStatusText:@""];
	if (resultsCount == 0) {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
															 message:@"No matching articles found."
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"OK", nil)
												   otherButtonTitles:nil] autorelease];
		[alertView show];
		self.searchResults = nil;
		self.stories = nil;
		[storyTable reloadData];
	} else {
		self.searchResults = results;
		self.stories = results;
		
		// hide translucent overlay
        [searchController hideSearchOverlayAnimated:YES];
		
		// show results
		[storyTable reloadData];
		[storyTable flashScrollIndicators];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController focusSearchBarAnimated:YES];
}

- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query {
    NewsStory *lastStory = [self.stories lastObject];
    NSInteger lastStoryId = (loadMore) ? [lastStory.story_id integerValue] : 0;
    if (!loadMore)
        searchIndex = 1;
    
	if (self.xmlParser) {
		[self.xmlParser abort];
	}
	self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
	xmlParser.delegate = self;
	
	[xmlParser loadStoriesforQuery:query afterStoryId:lastStoryId searchIndex:searchIndex count:10];
}

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)parserDidStartDownloading:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
		[self setProgress:0.02];
    }
}

- (void)parserDidMakeConnection:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
		[self setProgress:0.1];
		[storyTable reloadData];
    }
}

- (void)parser:(StoryXMLParser *)parser downloadMadeProgress:(CGFloat)progress {
    if (parser == self.xmlParser) {
		[self setProgress:0.1 + 0.2 * progress];
    }
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
		[self setProgress:0.3];
    }
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone {
    if (parser == self.xmlParser) {
		[self setProgress:0.3 + 0.7 * percentDone * 0.01];
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error {
    if (parser == self.xmlParser) {
		// TODO: make sure we aren't showing redundant alert views in addition to ConnectionWrapper
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            DLog(@"News download failed because there's no net connection");
        } else {
            DLog(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }
		[self setStatusText:@"Update failed"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update failed"
														message:@"Please check your connection and try again."
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
        if ([self.stories count] > 0) {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error {
    if (parser == self.xmlParser) {
		// TODO: make sure we aren't showing redundant alert views in addition to ConnectionWrapper
		[self setStatusText:@"Update failed"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update failed"
														message:@"Please check your connection and try again."
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
        if ([self.stories count] > 0) {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
		// basic category request
		if (!parser.isSearch) {
			NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
			NSInteger length = [[aCategory valueForKey:@"expectedCount"] integerValue];
			if (length == 0) { // fresh load of category, set its updated date
				[aCategory setValue:[NSDate date] forKey:@"lastUpdated"];
			} else {
                numTries = 0;
            }
			length += [self.xmlParser.newStories count];
            
            DLog(@"setting expectedCount = %d", length);            
			[aCategory setValue:[NSNumber numberWithInteger:length] forKey:@"expectedCount"];
			if (!parser.loadingMore && [self.stories count] > 0) {
				[storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
			}
            searchIndex = 1;
			self.xmlParser = nil;
			[self loadFromCache];
		}
		// result of a search request
		else {
            if (!parser.loadingMore) {
                totalAvailableResults = self.xmlParser.totalAvailableResults;
                if ([self.stories count] > 0) {
                    [storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
            }
            
            searchIndex = self.xmlParser.searchIndex;
			self.xmlParser = nil;
			[self loadSearchResultsFromCache];
		}
    }
    
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
			// don't show "load x more" row if
			if (!showingBookmarks && // showing bookmarks
				!(searchResults && n >= totalAvailableResults) && // showing all search results
				!(!searchResults && n >= MAX_ARTICLES)) { // showing all of a category
				n += 1; // + 1 for the "Load more articles..." row
			}
            break;
    }
	return n;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0 && self.searchResults) {
		return [NSString stringWithFormat:@"Showing %d of %d", [self.searchResults count], totalAvailableResults];
	}
    return nil;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0 && self.searchResults) {
		return UNGROUPED_SECTION_HEADER_HEIGHT;
	} else {
		return 0.0;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
	
	if (section == 0 && self.searchResults) {
		titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"Showing %d of %d", [self.searchResults count], totalAvailableResults]];
	}
	
    return titleView;
	
}
*/

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.stories.count) {

        NSInteger remainingArticlesToLoad = (!searchResults) ? (200 - [self.stories count]) : (totalAvailableResults - [self.stories count]);

        NSString *title = [NSString stringWithFormat:@"Load %d more articles...", (remainingArticlesToLoad > 10) ? 10 : remainingArticlesToLoad];
        UIColor *textColor;
        
        if (!self.xmlParser) { // disable when a load is already in progress
            textColor = [UIColor colorWithHexString:@"#1A1611"]; // enable
        } else {
            textColor = [UIColor colorWithHexString:@"#999999"]; // disable
        }
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.textLabel.textColor = textColor;
        } copy] autorelease];
        
    } else {
        return [[^(UITableViewCell *cell) {
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
        NSString *placeholderImageName;
        NewsImage *image;
        NewsStory *story;
        CGRect thumbnailFrame;
        
        if (self.searchResults == nil     // this is not a search
            && self.featuredStory != nil  // we have a featured story
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

        StoryThumbnailView *thumbnailView = [[[StoryThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 320.0, FEATURE_IMAGE_HEIGHT)] autorelease];
        thumbnailView.placeholderImageName = placeholderImageName;
        thumbnailView.image = image;
        [thumbnailView loadImage];

        [views addObject:thumbnailView];
        
        // Calculate height
        CGFloat availableHeight = FEATURE_TEXT_HEIGHT;
        CGSize titleDimensions = [story.title sizeWithFont:titleFont constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
        availableHeight -= titleDimensions.height;
        
        CGSize dekDimensions = CGSizeZero;
        // if not even one line will fit, don't show the deck at all
        if (availableHeight > dekFont.lineHeight) {
            dekDimensions = [story.summary sizeWithFont:dekFont constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
        }
        
        CGRect titleFrame = CGRectMake(STORY_TEXT_PADDING_LEFT,
                                       STORY_TEXT_PADDING_TOP + yOffset, 
                                       STORY_TEXT_WIDTH + THUMBNAIL_WIDTH, 
                                       titleDimensions.height);
        
        CGRect dekFrame = CGRectMake(STORY_TEXT_PADDING_LEFT,
                                     ceil(CGRectGetMaxY(titleFrame)), 
                                     STORY_TEXT_WIDTH + THUMBNAIL_WIDTH, 
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
        
        return views;
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.row == self.stories.count) {
		if (!self.xmlParser) { // only "load x more..." if no other load is going on
			if (!self.searchResults) {
				[self loadFromServer:YES];
			} else {
				[self loadSearchResultsFromServer:YES forQuery:self.searchQuery];
			}
		}
	} else {
        StoryDetailViewController *detailViewController = [[StoryDetailViewController alloc] init];
		detailViewController.newsController = self;
		NewsStory *story = nil;
        if (self.searchResults == nil     // this is not a search
            && self.featuredStory != nil  // we have a featured story
            && !showingBookmarks          // we are not looking at bookmarks
            && indexPath.row == 0)
        {
            story = self.featuredStory;
        } else {
            story = [self.stories objectAtIndex:indexPath.row];
        }
        detailViewController.story = story;
        
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
	}
}

#pragma mark -
#pragma mark Browsing hooks

- (BOOL)canSelectPreviousStory {
	NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
	if (currentIndexPath.row > 0) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)canSelectNextStory {
	NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
	if (currentIndexPath.row + 1 < [self.stories count]) {
		return YES;
	} else {
		return NO;
	}
}

- (NewsStory *)selectPreviousStory {
	NewsStory *prevStory = nil;
	if ([self canSelectPreviousStory]) {
		NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
		NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:currentIndexPath.section];
		prevStory = [self.stories objectAtIndex:prevIndexPath.row];
		[storyTable selectRowAtIndexPath:prevIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return prevStory;
}

- (NewsStory *)selectNextStory {
	NewsStory *nextStory = nil;
	if ([self canSelectNextStory]) {
		NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
		NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:currentIndexPath.section];
		nextStory = [self.stories objectAtIndex:nextIndexPath.row];
		[storyTable selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return nextStory;
}

#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    if (result && [result isKindOfClass:[NSArray class]]) {
		NSArray *newCategoryTitles = result;
		NSArray *oldCategories = [self fetchCategoriesFromCoreData];
		
		// check if the new categories are the same as the old categories
		BOOL categoriesChanged = NO;
		if([newCategoryTitles count] == [oldCategories count]) {
			for (NSUInteger i=0; i < [newCategoryTitles count]; i++) {
				NSString *newCategoryTitle = [newCategoryTitles objectAtIndex:i];
				NSString *oldCategoryTitle = ((NewsCategory *)[oldCategories objectAtIndex:i]).title;
				if (![newCategoryTitle isEqualToString:oldCategoryTitle]) {
					categoriesChanged = YES;
					break;
				}
			}
		} else {
			categoriesChanged = YES;
		}
		
		if(!categoriesChanged) {
			// categories do not need to be updated
			return;
		}
		
		
		[[CoreDataManager sharedManager] deleteObjects:oldCategories];		
		NSMutableArray *newCategories = [NSMutableArray arrayWithCapacity:[result count]];
		
        for (NewsCategoryId i = 0; i < [result count]; i++) {
            NSString *categoryTitle = [result objectAtIndex:i];
            NewsCategory *aCategory = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            aCategory.title = categoryTitle;
            aCategory.category_id = [NSNumber numberWithInt:i];
            aCategory.isMainCategory = [NSNumber numberWithBool:YES];
            [newCategories addObject:aCategory];
        }
        self.categories = newCategories;
        [[CoreDataManager sharedManager] saveData];
        
        [self setupNavScroller];
    }
}



@end
