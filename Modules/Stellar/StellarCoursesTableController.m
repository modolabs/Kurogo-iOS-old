#import "StellarCoursesTableController.h"
#import "StellarCourse.h"
#import "StellarClassesTableController.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "UITableView+MITUIAdditions.h"
#import "UITableViewCell+MITUIAdditions.h"
#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"


@implementation StellarCoursesTableController
@synthesize courseGroup;
@synthesize url;

- (id) initWithCourseGroup: (StellarCourseGroup *)aCourseGroup {
	if(self = [super initWithStyle:UITableViewStylePlain]) {
		self.courseGroup = aCourseGroup;
		NSString *path = [NSString stringWithFormat:@"courses/%@", [courseGroup serialize]];
		url = [[MITModuleURL alloc] initWithTag:StellarTag path:path query:nil];
		self.title = aCourseGroup.title;
	}
	return self;
}

- (void) dealloc {
	[url release];
	[courseGroup release];
	[super dealloc];
}

- (void) viewDidLoad {
	//self.tableView applyStandardColors];
	[self.tableView applyStandardCellHeight];
}

- (void) viewDidAppear:(BOOL)animated {
	[url setAsModulePath];
}
	
// "DataSource" methods
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return [self.courseGroup.courses count];//1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarCourses"];
	if(cell == nil) {
		cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StellarCourses"] autorelease];
		[cell applyStandardFonts];
	}
	
	//StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row];
	StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section];
	
	cell.textLabelNumberOfLines = 2;
	cell.textLabel.text = stellarCourse.title;
	cell.textLabel.font =  [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
	
	if ([self.courseGroup.courses count] < 10)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return 1;//[self.courseGroup.courses count];
}


- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row];
	StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section];
    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                tableView:tableView 
                                                     text:stellarCourse.title //was nil
                                             maxTextLines:2 //was 1
                                               detailText:nil // was stellarCourse.title
                                           maxDetailLines:0
                                                     font:nil 
                                               detailFont:nil 
                                            accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                                cellImage:NO] + 2.0; // was 2.0;
}


- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[self.navigationController
		pushViewController: [[[StellarClassesTableController alloc] 
			//initWithCourse: (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row]] autorelease]
			initWithCourse: (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section]] autorelease]				  
		animated:YES];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	if ([self.courseGroup.courses count] < 10)
		return nil;
	
	NSArray  *indexArray = [NSArray arrayWithObjects:@"A",
							@"B",
							@"C",
							@"D",
							@"E",
							@"F",
							@"G",
							@"H",
							@"I",
							@"J",
							@"K",
							@"L",
							@"M",
							@"N",
							@"O",
							@"P",
							@"Q",
							@"R",
							@"S",
							@"T",
							@"U",
							@"V",
							@"W",
							@"X",
							@"Y",
							@"Z",
							nil];
	
	return indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	
	int ind = 0;
	
	for(StellarCourse *course in self.courseGroup.courses) {
		if ([[course.title substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}

@end
