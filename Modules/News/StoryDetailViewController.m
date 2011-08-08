#import "StoryDetailViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOHTMLTemplate.h"
#import "StoryListViewController.h"
#import "NewsImage.h"
#import "KGOShareButtonController.h"
#import "KGOToolbar.h"

@interface StoryDetailViewController (Private) 

- (void)displayCurrentStory;
- (UIButton *)toolbarCloseButton;

@end

@implementation StoryDetailViewController

@synthesize newsController, story, stories, storyView, multiplePages, category;
@synthesize dataManager;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
	
	shareController = [[KGOShareButtonController alloc] initWithContentsController:self];
    shareController.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook | KGOShareControllerShareTypeTwitter;
}

- (void)viewDidLoad {
    self.navigationItem.title = @"Story";
    
    [super viewDidLoad];
	
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGRect storyViewFrame;
    KGOToolbar *alternateToolbar = nil;
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
        alternateToolbar = [[[KGOToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] autorelease];
        alternateToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // left bar item
        UIBarButtonItem *leftBarItem = [[[UIBarButtonItem alloc] initWithCustomView:[self toolbarCloseButton]] autorelease];
        UIBarButtonItem *flexibleMiddleItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];

        alternateToolbar.items = [NSArray arrayWithObjects:leftBarItem, flexibleMiddleItem, nil];
        
        [self.view addSubview:alternateToolbar];
        
        storyViewFrame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
    } else {
        storyViewFrame = self.view.bounds;
    }

	storyView = [[UIWebView alloc] initWithFrame:storyViewFrame];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
    
    if (multiplePages) {
        storyPager = [[KGODetailPager alloc] initWithPagerController:self delegate:self];
        
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: storyPager];
        if(alternateToolbar) {
            alternateToolbar.items = [alternateToolbar.items arrayByAddingObject:segmentBarItem];
        } else {
            self.navigationItem.rightBarButtonItem = segmentBarItem;
        }
        
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
    
    if ([self.story.hasBody boolValue]) {
        KGOHTMLTemplate *template = [KGOHTMLTemplate templateWithPathName:@"modules/news/news_story_template.html"];
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        
        if (story.title)          [values setValue:story.title forKey:@"TITLE"];
        if (story.author)         [values setValue:story.author forKey:@"AUTHOR"];
        if (story.thumbImage.url) [values setValue:story.thumbImage.url forKey:@"THUMBNAIL_URL"];
        if (story.body)           [values setValue:story.body forKey:@"BODY"];
        if (story.summary)        [values setValue:story.summary forKey:@"DEK"];

        if (story.postDate) {
            NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setDateFormat:@"MMM d, y"];
            NSString *postDate = [dateFormatter stringFromDate:story.postDate];
            [values setValue:postDate forKey:@"DATE"];
        }
        
        NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
        [values setValue:isBookmarked forKey:@"BOOKMARKED"];
        
        NSString *maxWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? @"140" : @"320";
        [values setValue:maxWidth forKey:@"THUMBNAIL_MAX_WIDTH"];
        
        [storyView loadTemplate:template values:values];

    } else {
        NSURL *url = [NSURL URLWithString:story.link];
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [storyView loadRequest:request];
        }
    }
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
    [[CoreDataManager sharedManager] saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
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
                if ([self.story isBookmarked]) {
                    [self.story removeBookmark];
                } else {
                    [self.story addBookmark];
                }
                
			} else if ([[url path] rangeOfString:@"share" options:NSBackwardsSearch].location != NSNotFound) {
                shareController.actionSheetTitle = @"Share article with a friend";
                shareController.shareTitle = story.title;
                shareController.shareBody = story.summary;
                shareController.shareURL = story.link;
				[shareController shareInView:self.view];
			}
            result = NO;
		}
	}
	return result;
}

- (void)goHome:(id)sender {
    NSDictionary *params = nil;
    if (self.category) {
        params = [NSDictionary dictionaryWithObject:self.category forKey:@"category"];
    }
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:self.dataManager.moduleTag params:params];
}
     
- (UIButton *)toolbarCloseButton {
    NSString *title = NSLocalizedString(@"News", @"News Module Home");
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(goHome:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor]
                  forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor]
                  forState:UIControlStateHighlighted];
    
    button.titleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyScrollTabSelected];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
    CGSize size = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
    
    UIImage *stretchableButtonImage = [[UIImage imageWithPathName:@"common/secondary-toolbar-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    UIImage *stretchableButtonImagePressed = [[UIImage imageWithPathName:@"common/secondary-toolbar-button-pressed.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    
    [button setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
    [button setBackgroundImage:stretchableButtonImagePressed forState:UIControlStateHighlighted];
    
    button.frame = CGRectMake(0, 0, size.width +15, stretchableButtonImage.size.height);
    
    return button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[shareController release];
	shareController = nil;
}

- (void)dealloc {
    [shareController release];
	[storyView release];
    self.story = nil;
    self.stories = nil;
    self.category = nil;
    [initialIndexPath release];
    [super dealloc];
}

@end
