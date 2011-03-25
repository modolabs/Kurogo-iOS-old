#import "StoryDetailViewController.h"
#import "KGOAppDelegate.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOHTMLTemplate.h"
#import "StoryListViewController.h"
#import "StoryGalleryViewController.h"
#import "NewsImage.h"
#import "AnalyticsWrapper.h"

@interface StoryDetailViewController (Private) 

- (void)displayCurrentStory;

@end

@implementation StoryDetailViewController

@synthesize newsController, story, stories, storyView, multiplePages;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
	
	//shareController = [[KGOShareButtonController alloc] initWithShareDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	storyView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
    
    if(multiplePages) {
        storyPager = [[KGODetailPager alloc] initWithPagerController:self delegate:self];
        
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: storyPager];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
        [segmentBarItem release];
        
        [storyPager selectPageAtSection:initialIndexPath.section row:initialIndexPath.row];
    } else {
        [self displayCurrentStory];
    }
}

- (void) setInitialIndexPath:(NSIndexPath *)theInitialIndexPath  {
    initialIndexPath = [theInitialIndexPath retain];
}

# pragma KGODetailPagerController methods
- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.stories.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.stories objectAtIndex:indexPath.row];
}

# pragma 
- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if(self.story == content) {
        // story already being shown
        return;
    }
    
    self.story = (NewsStory *)content;
    [self displayCurrentStory];
}

- (void)displayCurrentStory {

    KGOHTMLTemplate *template = [KGOHTMLTemplate templateWithPathName:@"modules/news/news_story_template.html"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.postDate];
	[dateFormatter release];
    
    NSString *thumbnailURL = story.thumbImage.url;
    
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    
	NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
	
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    [values setValue:story.title forKey:@"TITLE"];
    [values setValue:story.author forKey:@"AUTHOR"];
    [values setValue:isBookmarked forKey:@"BOOKMARKED"];
    [values setValue:postDate forKey:@"DATE"];
    [values setValue:thumbnailURL forKey:@"THUMBNAIL_URL"];
    [values setValue:story.body forKey:@"BODY"];
    [values setValue:story.summary forKey:@"DEK"];
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
	[[CoreDataManager sharedManager] saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [storyView loadTemplate:template values:values];
    
    // analytics
    NSString *detailString = [NSString stringWithFormat:@"/news/story?id=%@", self.story.identifier];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;

	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];

		if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
            if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
				// toggle bookmarked state
                BOOL newBookmarkState = [self.story.bookmarked boolValue] ? NO : YES;
                [[NewsDataManager sharedManager] story:self.story bookmarked:newBookmarkState];
			} else if ([[url path] rangeOfString:@"share" options:NSBackwardsSearch].location != NSNotFound) {
                // some how call the share controller
				//[shareController shareInView:self.view];
			}
            result = NO;
		}
	}
	return result;
}

- (void)share:(id)sender {
	[shareController shareInView:self.view];
}

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share article with a friend"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"Harvard Gazette: %@", story.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this story found on the Harvard Gazette:\n\n\"%@\"\n%@\n\n%@\n\nTo view this story, click the link above or paste it into your browser.", story.title, story.summary, story.link];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            //"\"caption\":\"%@\","
                            "\"description\":\"%@\","
                            "\"media\":["
                            "{\"type\":\"image\","
                            "\"src\":\"%@\","
                            "\"href\":\"%@\"}]}",
                            story.title, story.link, story.summary, story.featuredImage.url, story.link];    
	return attachment;
}

- (NSString *)twitterUrl {
	return story.link;
}

- (NSString *)twitterTitle {
	return story.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[shareController release];
	shareController = nil;
}

- (void)dealloc {
	//[shareController release];
	[storyView release];
    self.story = nil;
    self.stories = nil;
    [initialIndexPath release];
    [super dealloc];
}

@end
