#import "KGOSpringboardViewController.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"


@implementation KGOSpringboardViewController

- (void)loadView {
    [super loadView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_scrollView];
    
    if (!primaryGrid) {
        primaryGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, _searchBar.frame.size.height, self.view.bounds.size.width, 1)] autorelease];
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

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
    CGRect frame = secondGrid.frame;
    frame.origin.y = iconGrid.frame.origin.y + iconGrid.frame.size.height;
    secondGrid.frame = frame;
}

- (void)dealloc {
    [_scrollView release];
    [super dealloc];
}

@end



