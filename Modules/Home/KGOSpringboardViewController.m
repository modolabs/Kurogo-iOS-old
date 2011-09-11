#import "KGOSpringboardViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"


@implementation KGOSpringboardViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self adjustScrollView];
}

- (void)loadView {
    [super loadView];

    //[self adjustScrollView];
}

- (void) adjustScrollView {

    
    if (primaryGrid) {
        [primaryGrid removeFromSuperview];
        primaryGrid = nil;
    }
    
    if (secondGrid) {
        [secondGrid removeFromSuperview];   
        secondGrid = nil;
    }
    
    if (_scrollView) {
        [_scrollView removeFromSuperview];
        _scrollView = nil;
    }
    
    
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
    
    if ((secondGrid.frame.origin.y + secondGrid.frame.size.height) > self.view.bounds.size.height) {
                
        CGRect contentRect = CGRectZero;
        for (UIView *view in _scrollView.subviews)
            contentRect = CGRectUnion(contentRect, view.frame);
        
        contentRect.size.height += 20;
        _scrollView.contentSize = contentRect.size;
    }
}

- (void)dealloc {
    [_scrollView release];
    [super dealloc];
}

@end



