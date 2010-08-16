#import "SchoolsViewController.h"

#define ICON_LABEL_HEIGHT 26
#define GRID_HPADDING 16
#define GRID_VPADDING 11


@implementation SchoolsViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)layoutIcons {
    
    NSArray *schools = [NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:
                                                         @"schools.plist"]];
    
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:[schools count]];
    
    for (NSInteger i = 0; i < [schools count]; i++) {
         
        NSDictionary *schoolData = [schools objectAtIndex:i];
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:[schoolData objectForKey:@"iconName"]];
        NSString *title = [schoolData objectForKey:@"name"];

        if (image) {
            aButton.frame = CGRectMake(0, 0, image.size.width, image.size.height + ICON_LABEL_HEIGHT);
            
            aButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, ICON_LABEL_HEIGHT, 0);
            [aButton setImage:image forState:UIControlStateNormal];
            
            // title by default is placed to the right of the image, we want it below
            aButton.titleEdgeInsets = UIEdgeInsetsMake(image.size.height, -image.size.width, 0, 0);
        } else {
            aButton.frame = CGRectMake(0, 0, 80, 80);
        }
        
        [aButton setTitle:title forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        aButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        aButton.tag = i + 1; // don't use zero for tag
        
        [aButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [icons addObject:aButton];
        
        // Add properties for accessibility/automation visibility.
        aButton.isAccessibilityElement = YES;
        aButton.accessibilityLabel = [aButton titleForState:UIControlStateNormal];
    }
    
    CGSize viewSize = self.view.frame.size;
    
    // figure out number of icons per row to fit on screen
    UIButton *aButton = [icons objectAtIndex:0];
    CGSize iconSize = aButton.frame.size;
    
    NSInteger iconsPerRow = (int)floor((viewSize.width - GRID_HPADDING) / (iconSize.width + GRID_HPADDING));
    div_t result = div([icons count], iconsPerRow);
    NSInteger numRows = (result.rem == 0) ? result.quot : result.quot + 1;
    CGFloat rowHeight = aButton.frame.size.height + GRID_VPADDING;
    
    if ((rowHeight + GRID_VPADDING) * numRows > viewSize.height - GRID_VPADDING) {
        iconsPerRow++;
        CGFloat iconWidth = floor((viewSize.width - GRID_HPADDING) / iconsPerRow) - GRID_HPADDING;
        iconSize.height = floor(iconSize.height * (iconWidth / iconSize.width));
        iconSize.width = iconWidth;
    }
    
    // calculate xOrigin to keep icons centered
    CGFloat xOriginInitial = (viewSize.width - ((iconSize.width + GRID_HPADDING) * iconsPerRow - GRID_HPADDING)) / 2;
    CGFloat xOrigin = xOriginInitial;
    CGFloat yOrigin = GRID_VPADDING + 16.0;
    
    for (aButton in icons) {
        aButton.frame = CGRectMake(xOrigin, yOrigin, iconSize.width, iconSize.height);
        
        xOrigin += aButton.frame.size.width + GRID_HPADDING;
        if (xOrigin + aButton.frame.size.width + GRID_HPADDING >= viewSize.width) {
            xOrigin = xOriginInitial;
            yOrigin += aButton.frame.size.height + GRID_VPADDING;
        }
        
        if (![aButton isDescendantOfView:self.view]) {
            [self.view addSubview:aButton];
        }
    }
        
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    //[super viewDidLoad];
    
    self.navigationItem.title = @"Home";
    [self layoutIcons];
    
}


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


@end
