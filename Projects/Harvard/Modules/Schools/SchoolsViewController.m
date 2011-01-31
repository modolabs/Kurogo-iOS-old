/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "SchoolsViewController.h"

// height to allocate to icon text label
#define ICON_LABEL_HEIGHT 22

// horizontal spacing between icons
#define GRID_HPADDING 6

// vertical spacing between icons
#define GRID_VPADDING 16

// internal padding within each icon
#define ICON_HPADDING 10

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

- (void)buttonPressed:(id)sender {
    UIButton *aButton = (UIButton *)sender;
    NSInteger tag = aButton.tag;

    NSArray *schools = [NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:
                                                         @"schools/schools.plist"]];
    
    NSDictionary *schoolData = [schools objectAtIndex:tag - 1];
    NSURL *url = [NSURL URLWithString:[schoolData objectForKey:@"url"]];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}


// TODO: refactor this with springboard code
- (void)layoutIcons {
    
    NSArray *schools = [NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:
                                                         @"schools/schools.plist"]];
    
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:[schools count]];
    
    for (NSInteger i = 0; i < [schools count]; i++) {
         
        NSDictionary *schoolData = [schools objectAtIndex:i];
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *imageName = [NSString stringWithFormat:@"schools/%@.png", [schoolData objectForKey:@"iconName"]];
        UIImage *image = [UIImage imageNamed:imageName];
        NSString *title = [schoolData objectForKey:@"name"];

        if (image) {
            aButton.frame = CGRectMake(0, 0, image.size.width + ICON_HPADDING * 2, image.size.height + ICON_LABEL_HEIGHT);
            
            aButton.imageEdgeInsets = UIEdgeInsetsMake(0, ICON_HPADDING, ICON_LABEL_HEIGHT, ICON_HPADDING);
            [aButton setImage:image forState:UIControlStateNormal];
            
            // title by default is placed to the right of the image, we want it below
            aButton.titleEdgeInsets = UIEdgeInsetsMake(image.size.height, -image.size.width, 0, 0);
        } else {
            aButton.frame = CGRectMake(0, 0, 50, 50);
        }
        
        aButton.titleLabel.numberOfLines = 0;
        aButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        aButton.titleLabel.textAlignment = UITextAlignmentCenter;
        
        [aButton setTitle:title forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        aButton.titleLabel.font = [UIFont systemFontOfSize:11.0];
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
    CGFloat yOrigin = GRID_VPADDING + hintLabel.frame.origin.y + hintLabel.frame.size.height;
    
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


- (void)loadView {
    [super loadView];
    
    static NSString *hint = @"Links to websites for each Harvard school.\n"
        "Note: many of these sites are not mobile-optimized.";

    UIFont *hintFont = [UIFont systemFontOfSize:12.0];
    CGFloat width = self.view.frame.size.width;
    CGSize textSize = [hint sizeWithFont:hintFont constrainedToSize:CGSizeMake(width, 2010.0)];

    hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10.0, width, textSize.height)];
    hintLabel.text = hint;
    hintLabel.font = hintFont;
    hintLabel.textAlignment = UITextAlignmentCenter;
    hintLabel.numberOfLines = 0;
    hintLabel.lineBreakMode = UILineBreakModeWordWrap;
    hintLabel.backgroundColor = [UIColor clearColor];
    hintLabel.textColor = [UIColor blackColor];
}


- (void)viewDidLoad {
    //[super viewDidLoad];
    
    self.navigationItem.title = @"Schools";
    
    [self.view addSubview:hintLabel];
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
    [hintLabel release];
    [super dealloc];
}


@end
