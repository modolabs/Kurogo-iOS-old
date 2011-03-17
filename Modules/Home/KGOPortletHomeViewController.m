#import "KGOPortletHomeViewController.h"
#import "KGOHomeScreenWidget.h"
#import "SpringboardIcon.h"
#import "KGOModule.h"

#define widgetIsAtTop(widget)  ((widget).gravity == KGOHomeScreenWidgetGravityTopLeft || (widget).gravity == KGOHomeScreenWidgetGravityTopLeft || (widget).gravity == KGOHomeScreenWidgetGravityTopRight)

@implementation KGOPortletHomeViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)loadView {
    [super loadView];
    /*
    CGFloat yOrigin = 0;
    if (_searchBar) {
        yOrigin = _searchBar.frame.size.height;
    }
    
    _occupiedAreas = malloc(sizeof(CGSize) * 4);
    _occupiedAreas[KGOLayoutGravityTopLeft] = CGSizeZero;
    _occupiedAreas[KGOLayoutGravityTopRight] = CGSizeZero;
    _occupiedAreas[KGOLayoutGravityBottomLeft] = CGSizeZero;
    _occupiedAreas[KGOLayoutGravityBottomRight] = CGSizeZero;

    KGOLayoutGravity neighborGravity;
    BOOL downward; // true if new views are laid out from the top
    
    // populate widgets at the top
    NSMutableArray *overlappingViews = [NSMutableArray array];
    NSArray *allModules = [self.primaryModules arrayByAddingObjectsFromArray:self.secondaryModules];
    
    for (KGOModule *aModule in allModules) {
        NSArray *moreViews = [aModule widgetViews];
        if (moreViews) {
            DLog(@"preparing widgets for module %@", aModule.tag);
            for (KGOHomeScreenWidget *aWidget in moreViews) {
                if (!aWidget.overlaps) {
                    switch (aWidget.gravity) {
                        case KGOLayoutGravityBottomLeft:
                            neighborGravity = KGOLayoutGravityBottomRight;
                            downward = NO;
                            break;
                        case KGOLayoutGravityBottomRight:
                            neighborGravity = KGOLayoutGravityBottomLeft;
                            downward = NO;
                            break;
                        case KGOLayoutGravityTopRight:
                            neighborGravity = KGOLayoutGravityTopLeft;
                            downward = YES;
                            break;
                        case KGOLayoutGravityTopLeft:
                        default:
                            neighborGravity = KGOLayoutGravityTopRight;
                            downward = YES;
                            break;
                    }
                    
                    CGRect frame = aWidget.frame;

                    CGFloat currentYForGravity;
                    if (frame.size.width + _occupiedAreas[neighborGravity].width <= self.view.frame.size.width) {
                        currentYForGravity = _occupiedAreas[aWidget.gravity].height;
                    } else {
                        currentYForGravity = fmax(_occupiedAreas[aWidget.gravity].height, _occupiedAreas[neighborGravity].height);
                    }

                    if (downward) {
                        frame.origin.y = yOrigin + currentYForGravity;
                        _occupiedAreas[aWidget.gravity].height = frame.origin.y - yOrigin + frame.size.height;
                    } else {
                        frame.origin.y = self.view.frame.size.height - currentYForGravity - aWidget.frame.size.height;
                        _occupiedAreas[aWidget.gravity].height = self.view.frame.size.height - frame.origin.y;
                    }

                    if (frame.size.width > _occupiedAreas[aWidget.gravity].width)
                        _occupiedAreas[aWidget.gravity].width = frame.size.width;

                    if (aWidget.gravity == KGOLayoutGravityTopRight || aWidget.gravity == KGOLayoutGravityBottomRight) {
                        frame.origin.x = self.view.frame.size.width - aWidget.frame.size.width;
                    }
                    aWidget.frame = frame;
                    aWidget.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                    
                    [self.view addSubview:aWidget];

                } else {
                    [overlappingViews addObject:aWidget];
                }
            }
        }
    }
    
    CGFloat topFreePixel = yOrigin + fmax(_occupiedAreas[KGOLayoutGravityTopLeft].height, _occupiedAreas[KGOLayoutGravityTopRight].height);
    CGFloat bottomFreePixel = self.view.frame.size.height - fmax(_occupiedAreas[KGOLayoutGravityBottomLeft].height, _occupiedAreas[KGOLayoutGravityBottomRight].height);
    
    free(_occupiedAreas);
    */
    
    //IconGrid *iconGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, topFreePixel, self.view.frame.size.width, bottomFreePixel - topFreePixel)] autorelease];
    
    CGFloat topFreePixel;
    CGFloat bottomFreePixel;
    NSArray *widgets = [self allWidgets:&topFreePixel :&bottomFreePixel];
    
    IconGrid *iconGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, topFreePixel,
                                                                     self.view.frame.size.width,
                                                                     bottomFreePixel - topFreePixel)] autorelease];
    iconGrid.padding = [self moduleListMargins];
    iconGrid.spacing = [self moduleListSpacing];
    iconGrid.icons = [self iconsForPrimaryModules:YES];
    [self.view addSubview:iconGrid];
    DLog(@"%@", [iconGrid description]);

    for (KGOHomeScreenWidget *aWidget in widgets) {
       [self.view addSubview:aWidget];
    }

    //for (KGOHomeScreenWidget *aWidget in overlappingViews) {
        // TODO: respect gravity property
    //    [self.view addSubview:aWidget];
    //}
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
