/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "SpringboardViewController.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"

#import "PersonDetails.h"

// extra vertical padding above top row of main icons
#define GRID_TOP_MARGIN 4.0f

// horizontal spacing between main icons
// 0.0 for four icons per row
// 20.0 for three icons per row
#define MAIN_GRID_HPADDING 0.0f

// horizontal spacing between secondary icons
// 20.0 for four icons per row
#define SECONDARY_GRID_HPADDING 20.0f

// vertical spacing between icons
#define GRID_VPADDING 20.0f

// height to allocate to icon text label
#define ICON_LABEL_HEIGHT 23.0f

// internal padding within each icon (allows longer text labels)
#define ICON_PADDING 5.0f

// vertical padding above secondary (utility) icons
#define SECONDARY_GRID_TOP_PADDING 39.0f

@interface SpringboardViewController (Private)

- (void)setupSearchController;

@end


@implementation SpringboardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_scrollView];
    
    NSArray *modules = ((KGOAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    NSMutableArray *primaryIcons = [NSMutableArray arrayWithCapacity:[modules count]];
    NSMutableArray *secondIcons = [NSMutableArray array];

    CGRect primaryFrame = CGRectZero;
    CGRect secondaryFrame = CGRectZero;
    
    // assume all primary/secondary modules have same image size
    KGOModule *aModule = [self.primaryModules lastObject];
    CGSize labelSize = [self moduleLabelMaxDimensions];
    primaryFrame.size = [aModule iconImage].size;
    primaryFrame.size.width = fmax(primaryFrame.size.width, labelSize.width);
    primaryFrame.size.height += labelSize.height + [self moduleLabelTitleMargin];

    aModule = [self.secondaryModules lastObject];
    labelSize = [self secondaryModuleLabelMaxDimensions];
    secondaryFrame.size = [aModule iconImage].size;
    secondaryFrame.size.width = fmax(secondaryFrame.size.width, labelSize.width);
    secondaryFrame.size.height += labelSize.height + [self secondaryModuleLabelTitleMargin];
    
    for (aModule in modules) {
        //SpringboardIcon *anIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        if (![aModule iconImage])
            continue;
        
        SpringboardIcon *anIcon;
        if (aModule.secondary) {
            anIcon = [[[SpringboardIcon alloc] initWithFrame:secondaryFrame] autorelease];
            [secondIcons addObject:anIcon];
        } else {
            anIcon = [[[SpringboardIcon alloc] initWithFrame:primaryFrame] autorelease];
            [primaryIcons addObject:anIcon];
        }
        anIcon.springboard = self;
        anIcon.module = aModule;
        
        // Add properties for accessibility/automation visibility.
        anIcon.isAccessibilityElement = YES;
        anIcon.accessibilityLabel = aModule.longName;
    }
    
    
    if (!primaryGrid) {
        primaryGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, _searchBar.frame.size.height, self.view.bounds.size.width, 1)] autorelease];
        //primaryGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        primaryGrid.padding = [self moduleListMargins];
        primaryGrid.spacing = [self moduleListSpacing];
        primaryGrid.icons = primaryIcons;
        primaryGrid.delegate = self;
    }
    
    if (!secondGrid) {
        secondGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, primaryGrid.frame.origin.y + primaryGrid.frame.size.height,
                                                                 self.view.bounds.size.width, 1)] autorelease];
        //secondGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        secondGrid.padding = [self secondaryModuleListMargins];
        secondGrid.spacing = [self secondaryModuleListSpacing];
        secondGrid.icons = secondIcons;
    }
    
    [_scrollView addSubview:primaryGrid];
    [_scrollView addSubview:secondGrid];
}

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
    CGRect frame = secondGrid.frame;
    frame.origin.y = iconGrid.frame.origin.y + iconGrid.frame.size.height;
    secondGrid.frame = frame;
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
	// special case for full web link
	if ([anIcon.moduleTag isEqualToString:FullWebTag]) {
		// TODO: add this string to config
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.harvard.edu/?fullsite=yes"]];
		return;
	}
    
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameHome forModuleTag:anIcon.moduleTag params:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    //[_searchController release];
    //_searchController = nil;
}

- (void)dealloc {
    [_scrollView release];
    //[_searchBar release];
    //[_searchController release];
    [super dealloc];
}

@end



