#import "DatePickerViewController.h"


@implementation DatePickerViewController

@synthesize delegate, date = _date;
@synthesize datePicker;

- (void)loadView {
    [super loadView];
	self.title = NSLocalizedString(@"Jump to a Date", nil);
	
    self.view.backgroundColor = [UIColor clearColor];
    if (!self.date) {
        self.date = [NSDate date];
    }
    
    UIControl *scrim = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	scrim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrim.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    [scrim addTarget:self.delegate action:@selector(datePickerViewControllerDidCancel:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:scrim];
    [scrim release];
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Go", @"DatePickerViewController nav bar")
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(navBarButtonPressed:)];
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"DatePickerViewController nav bar")
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(navBarButtonPressed:)];
    
	if (!self.navigationController) {
		UINavigationItem *navItem = [[[UINavigationItem alloc] initWithTitle:self.title] autorelease];
		navItem.rightBarButtonItem = doneButton;
		navItem.leftBarButtonItem = cancelButton;

		UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)] autorelease];
		navBar.barStyle = UIBarStyleBlack;
		[navBar pushNavigationItem:navItem animated:NO];
		[self.view addSubview:navBar];

	} else {
		self.navigationItem.leftBarButtonItem = cancelButton;
		self.navigationItem.rightBarButtonItem = doneButton;
	}
    
    datePicker = [[UIDatePicker alloc] init];
    datePicker.frame = CGRectMake(0.0, self.view.frame.size.height - datePicker.frame.size.height, datePicker.frame.size.width, datePicker.frame.size.height);
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.date = self.date;
	datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:2 * 366 * 24 * 3600];
	datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-10 * 366 * 24 * 3600];
    [datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
}

- (void)navBarButtonPressed:(id)sender
{
    if (sender == doneButton) {
        [self.delegate datePickerViewController:self didSelectDate:datePicker.date];
    } else if (sender == cancelButton) {
        [self.delegate datePickerViewControllerDidCancel:self];
    }
}

- (void)datePickerValueChanged:(id)sender {
    [self.delegate datePickerViewController:self valueChanged:datePicker.date];
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
    [_date release];
    [datePicker release];
    [doneButton release];
    [cancelButton release];
    
    [super dealloc];
}


@end
