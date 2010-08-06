#import "StellarCourseGroup.h"
#import "StellarCourse.h"
#import "StellarModel.h"

NSInteger courseNameCompare(id course1, id course2, void *context);

@implementation StellarCourseGroup
@synthesize title, courses;

- (id) initWithTitle: (NSString *)aTitle courses:(NSMutableArray *)aCourseGroup {
	if(self = [super init]) {
		self.title = aTitle;
		self.courses = aCourseGroup;
	}
	return self;
}

+ (NSArray *) allCourseGroups:(NSArray *)stellarCourses {
	/*NSArray *courseCriterias = [NSArray arrayWithObjects:
		[CourseGroupCriteria numericLower:@"1" upper:@"11"],
		[CourseGroupCriteria numericLower:@"11" upper:@"21"],
		[CourseGroupCriteria numericLower:@"21"],
		[CourseGroupCriteria nonNumeric],
		nil];
	
	
	NSMutableArray *courseGroups = [NSMutableArray array];
	for(CourseGroupCriteria *criteria in courseCriterias) {
		NSMutableArray *courseGroup = [NSMutableArray array];
		for(StellarCourse *course in stellarCourses) {
			if([criteria isInGroup:course.number]) {
				[courseGroup addObject:course];
			}
		}
		
		NSArray *sortedCourseGroup = [courseGroup sortedArrayUsingFunction:courseNameCompare context:NULL];
		if([sortedCourseGroup count] > 0) {
			NSString *title;
			if([criteria isNumeric]) {
				title = [@"Courses " stringByAppendingString:((StellarCourse *)[sortedCourseGroup objectAtIndex:0]).number];
				title = [title stringByAppendingString:@"-"];
				title = [title stringByAppendingString:((StellarCourse *)[sortedCourseGroup lastObject]).number];
			} else {
				title = @"Other Courses";
			}
				
			[courseGroups addObject:[[[StellarCourseGroup alloc] initWithTitle:title courses:sortedCourseGroup] autorelease]];
		}	
	}
	return courseGroups;*/
	
	NSMutableDictionary *courseGroups = [[NSMutableDictionary alloc] init];
	NSMutableArray *courseGroupNames = [[NSMutableArray alloc] init];
	
	for (StellarCourse *course in stellarCourses) {
		
		if (![[courseGroups allKeys] containsObject:course.courseGroup]) {
			
			[courseGroupNames addObject:course.courseGroup];
			
			StellarCourseGroup *group = [[StellarCourseGroup alloc] init];
			group.title = course.courseGroup;
			
			NSMutableArray * cArray = [[NSMutableArray alloc] init];
			group.courses = cArray;
			
			if ([course.title length] >= 1) {
				[group.courses addObject:course];
			}
			
			[courseGroups setObject:group forKey:course.courseGroup];
		}
		
		else {
			StellarCourseGroup *group = [courseGroups objectForKey:course.courseGroup];
			[courseGroups removeObjectForKey:course.courseGroup];
			if ([course.title length] >= 1)
				[group.courses addObject:course];
			[courseGroups setObject:group forKey:course.courseGroup];
		}

	}

	NSMutableArray *courseGroupArray = [[NSMutableArray alloc] init];
		for (NSString *groupName in [courseGroups allKeys]) {
			
			StellarCourseGroup *group = [courseGroups objectForKey:groupName];
			
			NSMutableArray *temp = group.courses;
			[temp sortUsingSelector:@selector(compare:)];
			group.courses = temp;
			[courseGroupArray addObject:group]; 
	}
	
	
	return [courseGroupArray sortedArrayUsingSelector:@selector(compare:)];
}

- (NSString *) serialize {
	BOOL first = YES;
	NSMutableString *coursesString = [NSMutableString string];
	for (StellarCourse *course in courses) {
		if (!first) {
			[coursesString appendString:@"-"];
		} else {
			first = NO;
		}
		[coursesString appendString:course.number];
	}
	
	return [NSString stringWithFormat:@"%@:%@", title, coursesString];
}
	
+ (StellarCourseGroup *) deserialize: (NSString *)serializedCourseGroup {
	NSArray *partsByColon = [serializedCourseGroup componentsSeparatedByString:@":"];
	NSString *title = [partsByColon objectAtIndex:0];
	NSArray *courseIds = [[partsByColon objectAtIndex:1] componentsSeparatedByString:@"-"];
	NSMutableArray *courses = [NSMutableArray arrayWithCapacity:courseIds.count];
	for (NSString *courseId in courseIds) {
		StellarCourse *course = [StellarModel courseWithId:courseId];
		if (course) {
			[courses addObject:course];
		} else {
			// if we fail to look up a course
			// consider the whole deserialization a failure
			return nil;
		}
	}
	return [[[StellarCourseGroup alloc] initWithTitle:title courses:courses] autorelease];
}

- (void) dealloc {
	[title release];
	[courses release];
	[super dealloc];
}

- (NSComparisonResult)compare:(StellarCourseGroup *)otherObject {
    return [self.title compare:otherObject.title];
}

@end

@implementation CourseGroupCriteria
@synthesize lower, upper;

+ (CourseGroupCriteria *) numericLower: (NSString *)lower {
		return [[[CourseGroupCriteria alloc] initNumeric:YES lower:lower upper:nil] autorelease];
}

+ (CourseGroupCriteria *) numericLower: (NSString *)lower upper: (NSString *)upper {
	return [[[CourseGroupCriteria alloc] initNumeric:YES lower:lower upper:upper] autorelease];
}

+ (CourseGroupCriteria *) nonNumeric {
	return [[[CourseGroupCriteria alloc] initNumeric:NO lower:nil upper:nil] autorelease];
}

- (id) initNumeric: (BOOL)aNumeric lower: (NSString *)aLower upper: (NSString *)aUpper {
	[super init];
	self.lower = aLower;
	self.upper = aUpper;
	numeric = aNumeric;
	return self;
}
	
- (BOOL) isInGroup: (NSString *)groupName {
	BOOL isNumeric;
	
	if([groupName compare:@"0"] == NSOrderedAscending) {
		isNumeric = NO;
	} else if([groupName compare:@"9"] == NSOrderedDescending) {
		isNumeric = NO;
	} else {
		isNumeric = YES;
	}
	
	if(numeric) {
		if(!isNumeric) {
			return NO;
		}
		
		if([groupName compare:lower options:NSNumericSearch] == NSOrderedAscending) {
			return NO;
		}
		
		if(upper == nil) {
			return YES;
		}
		
		return ([groupName compare:upper options:NSNumericSearch] == NSOrderedAscending);
	} else {
		return !isNumeric;
	}
}

- (BOOL) isNumeric {
	return numeric;
}

@end

NSInteger courseNameCompare(id course1, id course2, void *context) {
	return [((StellarCourse *)course1).title compare:((StellarCourse *)course2).title options:NSNumericSearch];
}



