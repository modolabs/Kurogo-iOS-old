#import "KGOSpringboardViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"


@implementation KGOSpringboardViewController

#pragma mark -

- (void)loadView {
    [super loadView];
    
    CGRect frame = self.view.bounds;
    if (_searchBar) {
        frame.origin.y = _searchBar.frame.size.height;
        frame.size.height -= _searchBar.frame.size.height;
    }
    _scrollView = [[UIScrollView alloc] initWithFrame:frame];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.contentSize = self.view.bounds.size;
    [self.view addSubview:_scrollView];
    
    if (!primaryGrid) {
        primaryGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)] autorelease];
        primaryGrid.padding = [self moduleListMargins];
        primaryGrid.spacing = [self moduleListSpacing];
        primaryGrid.icons = [self iconsForPrimaryModules:YES];
        primaryGrid.delegate = self;
    }
    
    if (!secondGrid) {
        secondGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, primaryGrid.frame.origin.y + primaryGrid.frame.size.height,
                                                                 self.view.bounds.size.width, 1)] autorelease];
        secondGrid.padding = [self secondaryModuleListMargins];
        secondGrid.spacing = [self secondaryModuleListSpacing];
        secondGrid.icons = [self iconsForPrimaryModules:NO];
    }
    
    [_scrollView addSubview:primaryGrid];
    [_scrollView addSubview:secondGrid];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self iconGridFrameDidChange:secondGrid];
}

- (void)refreshModules
{
    [super refreshModules];

    primaryGrid.icons = [self iconsForPrimaryModules:YES];
    secondGrid.icons = [self iconsForPrimaryModules:NO];
    
    [primaryGrid setNeedsLayout];
    [secondGrid setNeedsLayout];
}

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
    if (iconGrid == primaryGrid) {
        CGRect frame = secondGrid.frame;
        frame.origin.y = iconGrid.frame.origin.y + iconGrid.frame.size.height;
        secondGrid.frame = frame;
    }
    
    CGFloat scrollHeight = secondGrid.frame.origin.y + secondGrid.frame.size.height; // pad bottom
    if (_searchBar) {
        scrollHeight += _searchBar.frame.size.height;
    }
    if (scrollHeight != _scrollView.contentSize.height) {
        _scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width, scrollHeight);
    }
    
    [_scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollView release];
    [super dealloc];
}

@end



