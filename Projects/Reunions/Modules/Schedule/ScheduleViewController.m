#import "ScheduleViewController.h"


@implementation ScheduleViewController

- (void)dealloc
{
    [_fakeSchedule release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    NSLog(@"%@", [self.view.subviews description]);
    
    self.title = @"Schedule";
    
    _fakeSchedule = [[NSArray alloc] initWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      @"Friday, May 27, 2011", @"date",
                      [NSArray arrayWithObjects:
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Sample Event Title Goes Here", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Vivamus, Atque Amemus", @"title",
                        @"6:00-7:30pm", @"time",
                        @"yes", @"bookmarked",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Soles Occidire et Redire Possunt", @"title",
                        @"6:00-7:30pm", @"time",
                        @"yes", @"bookmarked",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Nobis, Cum Semel Occidit Brevis Lux", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Some Formal Event for Alumni and Guests", @"title",
                        @"6:00-7:30pm", @"time",
                        @"yes", @"bookmarked",
                        @"yes", @"notes",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Gala Evening Reunion Event", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       nil], @"events",
                      nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      @"Saturday, May 28, 2011", @"date",
                      [NSArray arrayWithObjects:
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Nobis, Cum Semel Occidit Brevis Lux", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Vivamus, Atque Amemus", @"title",
                        @"6:00-7:30pm", @"time",
                        @"yes", @"bookmarked",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Gala Evening Reunion Event", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Soles Occidire et Redire Possunt", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Sample Event Title Goes Here", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Some Formal Event for Alumni and Guests", @"title",
                        @"6:00-7:30pm", @"time",
                        nil],
                       nil], @"events",
                      nil],
                     nil];
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

#pragma mark Table view methods

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dayEvents = [_fakeSchedule objectAtIndex:indexPath.section];
    NSArray *events = [dayEvents objectForKey:@"events"];
    NSDictionary *event = [events objectAtIndex:indexPath.row];
    NSString *title = [event objectForKey:@"title"];
    NSString *subtitle = [event objectForKey:@"time"];
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = title;
        cell.detailTextLabel.text = subtitle;
    } copy] autorelease];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *dayEvents = [_fakeSchedule objectAtIndex:section];
    return [dayEvents objectForKey:@"date"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dayEvents = [_fakeSchedule objectAtIndex:section];
    NSArray *events = [dayEvents objectForKey:@"events"];
    return events.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _fakeSchedule.count;
}

@end
