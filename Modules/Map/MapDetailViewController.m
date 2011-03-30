#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"

@implementation MapDetailViewController

@synthesize placemark, pager;

#pragma mark TabbedViewDelegate

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index {
    UIView *view = nil;
    NSString *title = [control titleForTabAtIndex:index];
    if ([title isEqualToString:@"Photo"]) {

    
    } else if ([title isEqualToString:@"Details"]) {
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.tabViewContainer.frame.size.width, self.tabViewContainer.frame.size.height)] autorelease];
        [webView loadHTMLString:self.placemark.info baseURL:nil];
        view = webView;
    }
    return view;
}

- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control {
    return [NSArray arrayWithObjects:@"Photo", @"Details", nil];
}

- (CGFloat)headerWidthWithButtons
{
    CGFloat result = self.view.bounds.size.width - 10;
    if (_bookmarkButton) {
        result -= _bookmarkButton.frame.size.width + 10;
    }
    return result;
}

- (void)showBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - placeholder.size.width;
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(buttonX, 10, placeholder.size.width, placeholder.size.height);
        
        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabViewHeader addSubview:_bookmarkButton];
    }
    
    UIImage *buttonImage, *pressedButtonImage;
    if ([self.placemark isBookmarked]) {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_on.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_on_pressed.png"];
    } else {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_off_pressed.png"];
    }
    [_bookmarkButton setImage:buttonImage forState:UIControlStateNormal];
    [_bookmarkButton setImage:pressedButtonImage forState:UIControlStateHighlighted];
}

- (void)hideBookmarkButton
{
    if (_bookmarkButton) {
        [_bookmarkButton removeFromSuperview];
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent {
    NSLog(@"%@", [self.placemark description]);
    
    _titleLabel.text = self.placemark.title;
    [self reloadTabContent];
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.placemark = content;
        [self loadAnnotationContent];
    }
}

#pragma mark -

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
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForContentTitle];
    CGFloat width = self.view.frame.size.width - 80;
    _titleLabel = [UILabel multilineLabelWithText:self.placemark.title font:titleFont width:width];
    
    [self.tabViewHeader addSubview:_titleLabel];
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

@end
