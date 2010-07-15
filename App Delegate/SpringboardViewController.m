#import "SpringboardViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"

#define GRID_PADDING 30.0f

@implementation SpringboardViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    return self;
}

- (void)layoutIcons:(NSArray *)icons {
    
    CGFloat viewWidth = self.view.frame.size.width;
    
    CGFloat xOrigin = GRID_PADDING;
    CGFloat yOrigin = GRID_PADDING;// + navigationBar.frame.size.height;
    bottomRight = CGPointZero;
    
    for (UIView *anIcon in icons) {
        anIcon.frame = CGRectMake(xOrigin, yOrigin, anIcon.frame.size.width, anIcon.frame.size.height);
        xOrigin += anIcon.frame.size.width + GRID_PADDING;
        if (xOrigin + anIcon.frame.size.width + GRID_PADDING >= viewWidth) {
            xOrigin = GRID_PADDING;
            yOrigin += anIcon.frame.size.height + GRID_PADDING;
        }
        
        if (![anIcon isDescendantOfView:containingView]) {
            [containingView addSubview:anIcon];
        }

        if (bottomRight.x < xOrigin + anIcon.frame.size.width) {
            bottomRight.x = xOrigin + anIcon.frame.size.width;
        }
        
        if (bottomRight.y < yOrigin + anIcon.frame.size.height) {
            bottomRight.y = yOrigin + anIcon.frame.size.height;
        }
    }
    
    topLeft = ((SpringboardIcon *)[icons objectAtIndex:0]).frame.origin;
}

- (void)customizeIcons:(id)sender {
    CGRect frame = CGRectMake(0, /*navigationBar.frame.size.height*/0, self.view.frame.size.width, self.view.frame.size.height/* - navigationBar.frame.size.height*/);
    transparentOverlay = [[UIView alloc] initWithFrame:frame];
    transparentOverlay.backgroundColor = [UIColor clearColor];
    [containingView addSubview:transparentOverlay];
    
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(endCustomize)] autorelease];
    navigationBar.topItem.rightBarButtonItem = doneButton;
    
    editing = YES;
    editedIcons = [_icons copy];
    [self becomeFirstResponder];
}

- (void)endCustomize {
    _icons = editedIcons;
    [transparentOverlay removeFromSuperview];
    [transparentOverlay release];
    
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(customizeIcons:)] autorelease];
    navigationBar.topItem.rightBarButtonItem = editButton;
    
    [self resignFirstResponder];
    editing = NO;
}

- (void)loadView {
    [super loadView];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    //containingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    [self.view addSubview:containingView];
    
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(customizeIcons:)] autorelease];
    self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.title = @"Home";
    
    NSArray *modules = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    _icons = [[NSMutableArray alloc] initWithCapacity:[modules count]];
    
    for (MITModule *aModule in modules) {
        SpringboardIcon *anIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        UIImage *image = [aModule icon];
        anIcon.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        [anIcon setImage:image forState:UIControlStateNormal];
        anIcon.moduleTag = aModule.tag;
        [anIcon addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_icons addObject:anIcon];
    }
    
    [self layoutIcons:_icons];
}


- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[appDelegate switchContainerView];
    [appDelegate showModuleForTag:anIcon.moduleTag];
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
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark UIResponder

- (BOOL)canBecomeFirstResponder {
    return editing;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        selectedIcon = nil;
        UITouch *aTouch = [touches anyObject];
        for (SpringboardIcon *anIcon in editedIcons) {
            CGPoint point = [aTouch locationInView:containingView];
            CGFloat xOffset = point.x - anIcon.frame.origin.x;
            CGFloat yOffset = point.y - anIcon.frame.origin.y;
            if (xOffset > 0 && yOffset > 0
                && xOffset < anIcon.frame.size.width
                && yOffset < anIcon.frame.size.height)
            {
                selectedIcon = anIcon;
                startingPoint = anIcon.center;
                break;
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (selectedIcon) {
        
        NSArray *array = _icons;
        if (editedIcons) {
            [editedIcons removeObjectAtIndex:dummyIconIndex];
            [editedIcons insertObject:selectedIcon atIndex:dummyIconIndex];
            //editedIcons = tempIcons;
            array = editedIcons;
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self layoutIcons:array];
        [UIView commitAnimations];

        //tempIcons = nil;
    }
    selectedIcon = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (selectedIcon) {
        UITouch *aTouch = [touches anyObject];
        
        CGPoint before = [aTouch previousLocationInView:containingView];
        CGPoint after = [aTouch locationInView:containingView];
        
        CGFloat xTransition = after.x - before.x;
        CGFloat yTransition = after.y - before.y;

        selectedIcon.frame = CGRectMake(selectedIcon.frame.origin.x + xTransition,
                                        selectedIcon.frame.origin.y + yTransition,
                                        selectedIcon.frame.size.width, selectedIcon.frame.size.height);

        xTransition = selectedIcon.center.x - startingPoint.x;
        yTransition = selectedIcon.center.y - startingPoint.y;
        
        if (fabs(xTransition) > selectedIcon.frame.size.width
            || fabs(yTransition) > selectedIcon.frame.size.height)
        { // don't do anything if they didn't move far
            tempIcons = [editedIcons mutableCopy];
            [tempIcons removeObject:selectedIcon];
            [tempIcons removeObject:dummyIcon];
            
            dummyIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
            dummyIcon.frame = selectedIcon.frame;

            // just figure out where in the array to stick selectedIcon
            dummyIconIndex = 0;
            for (SpringboardIcon *anIcon in tempIcons) {
                CGFloat xDistance = anIcon.center.x - selectedIcon.center.x; // > 0 if aButton is to the right
                CGFloat yDistance = selectedIcon.center.y - anIcon.center.y;
                NSLog(@"%d %.1f %.1f %.1f %.1f", dummyIconIndex, xDistance, GRID_PADDING + anIcon.frame.size.width, yDistance, anIcon.frame.size.height / 2);// , aButton.center.x, selectedIcon.center.x);
                if (xDistance > 0 && xDistance < GRID_PADDING + anIcon.frame.size.width
                    && fabs(yDistance) < anIcon.frame.size.height / 2) {
                    break;
                }
                dummyIconIndex++;
            }
            
            [tempIcons insertObject:dummyIcon atIndex:dummyIconIndex];
            NSLog(@"moving: to %d", dummyIconIndex);

            editedIcons = tempIcons;
            tempIcons = nil;
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            [self layoutIcons:editedIcons];
            [UIView commitAnimations];
        }
    }
}

@end



@implementation SpringboardIcon

@synthesize moduleTag;

@end


