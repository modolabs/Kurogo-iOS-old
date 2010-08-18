
#import "InfoDataSource.h"
#import "Foundation+MITAdditions.h"
#import "MultiLineTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "UITableViewCell+MITUIAdditions.h"
#import "MITUIConstants.h"

#define TIMES 0
#define DESCRIPTION 1
#define CREDITS 2
#define PREREQS 3
#define CROSS_REG 4
#define EXAM_GROUP 5
#define DEPARTMENT 6
#define SCHOOL 7

#define DESCRIPTION_PADDING 18


@implementation InfoDataSource

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 8;
}

 
- (NSString *) locationAndTime: (NSUInteger)index {
	/*NSString * loc = @"";
	for (int ind=0; ind < [self.viewController.times count]; ind++) {
		StellarClassTime *classTime = [self.viewController.times objectAtIndex:ind];
		
		if (ind == 0) {
			if(![classTime.location length])
				// no location set
				loc = [loc stringByAppendingFormat:@"%@", classTime.time];
			else
				loc = [loc stringByAppendingFormat:@"%@ (%@)", classTime.time, classTime.location];
		}
		
		else {
			if(![classTime.location length])
				// no location set
				loc = [loc stringByAppendingFormat:@"\n%@", classTime.time];
			else
				loc = [loc stringByAppendingFormat:@"\n%@ (%@)", classTime.time, classTime.location];
		}
	}
	
	return loc;*/
	
	StellarClassTime *classTime = [self.viewController.times objectAtIndex:index];
	if(![classTime.location length]) {
		// no location set
		return [NSString stringWithFormat:@"%@", classTime.time];
	} else {
		return [NSString stringWithFormat:@"%@ (%@)", classTime.time, classTime.location];
	}
}
		

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	MultiLineTableViewCell *cell = nil;
	 {
		switch (indexPath.section) {
				
			case TIMES:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarTimes"];
				if(cell == nil) {
					cell = [[[StellarLocationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarTimes"] autorelease];
					[cell applyStandardFonts];
					makeCellWhite(cell);
				}
				
				/*if (viewController.loadingState == YES) {
					//cell.textLabel.text = announcementsLoadingMessage;
					UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
					cell.accessoryView = spinner;
					[spinner startAnimating];
					[spinner release];
					break;					
				}*/
				
				StellarClassTime *classTime = [self.viewController.times objectAtIndex:indexPath.row];
				if([classTime.location length]) {
					if (![classTime.location isEqualToString:@"TBA"] && 
						![classTime.location isEqualToString:@"tba"] &&
						![classTime.location isEqualToString:@"TBD"] &&
						![classTime.location isEqualToString:@"tbd"] && 
						![classTime.location isEqualToString:@"Tbd"] && 
						![classTime.location isEqualToString:@"Tba"]) {
						
						cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
						cell.selectionStyle = UITableViewCellSelectionStyleGray;
					}
					else {
						cell.accessoryView = nil;
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					}					
				} else {
					cell.accessoryView = nil;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
				cell.textLabel.text = [self locationAndTime:indexPath.row];
				break;
				
				
			case DESCRIPTION:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarDescription"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarDescription"] autorelease];
					
					cell.textLabel.text = @"Description:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.blurb;
				break;
				
			case CREDITS:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarCredits"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarCredits"] autorelease];
					cell.textLabel.text = @"Credits:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.credits;
				break;
				
			case PREREQS:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarPreReqs"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarPreReqs"] autorelease];
					cell.textLabel.text = @"Pre-Requisites:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.preReqs;
				break;
				
			case CROSS_REG:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarCrossReg"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarCrossReg"] autorelease];
					cell.textLabel.text = @"Cross-Registration:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.cross_reg;
				break;
				
			case EXAM_GROUP:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarExamGroup"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarExamGroup"] autorelease];
					cell.textLabel.text = @"Exam Group:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.examGroup;
				break;
				
			case DEPARTMENT:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarDepartment"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarDepartment"] autorelease];
					cell.textLabel.text = @"Department:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.department;
				break;
				
			case SCHOOL:
				cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarSchool"];
				if(cell == nil) {
					cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarSchool"] autorelease];
					cell.textLabel.text = @"School:";
					[cell applyStandardFonts];
					makeCellWhite(cell);
					cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					//cell.topPadding = DESCRIPTION_PADDING;
				}
				cell.detailTextLabel.text = self.viewController.stellarClass.school;
				break;
		}
	}
	return cell;	
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	switch (section) {			
		case TIMES:
			return [self.viewController.times count];
		case DESCRIPTION:
			return 1;
		case CREDITS:
			if ([self.viewController.stellarClass.credits length] > 0)
				return 1;
			else 
				return 0;
		case PREREQS:
			if ([self.viewController.stellarClass.preReqs length] > 0)
				return 1;
			else 
				return 0;
		case CROSS_REG:
			if ([self.viewController.stellarClass.cross_reg length] > 0)
				return 1;
			else 
				return 0;
		case EXAM_GROUP:
			if ([self.viewController.stellarClass.examGroup length] > 0)
				return 1;
			else 
				return 0;
		case DEPARTMENT:
			if ([self.viewController.stellarClass.department length] > 0)
				return 1;
			else 
				return 0;
		case SCHOOL:
			if ([self.viewController.stellarClass.school length] > 0)
				return 1;
			else 
				return 0;
	}
	return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case TIMES:
            return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                        tableView:tableView 
                                                             text:StellarTag
                                                     maxTextLines:0
                                                       detailText:[self locationAndTime:indexPath.row]// something with one line
                                                   maxDetailLines:0
                                                             font:nil 
                                                       detailFont:nil 
                                                    accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                                        cellImage:NO];
			
		case DESCRIPTION:
            return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                        tableView:tableView 
                                                             text:@"Description"
                                                     maxTextLines:0
                                                       detailText:self.viewController.stellarClass.blurb
                                                   maxDetailLines:0
                                                             font:nil 
                                                       detailFont:nil 
                                                    accessoryType:UITableViewCellAccessoryNone
                                                        cellImage:NO] + DESCRIPTION_PADDING;
			
		case CREDITS:
			return [self getHeightForRows:@"Credits" detailedText:self.viewController.stellarClass.credits tableView:tableView];
		
		case PREREQS:
			return [self getHeightForRows:@"Pre-Requisites" detailedText:self.viewController.stellarClass.preReqs tableView:tableView];
 
		case CROSS_REG:
			return [self getHeightForRows:@"Cross-Regisration" detailedText:self.viewController.stellarClass.cross_reg tableView:tableView];
		
		case EXAM_GROUP:
			return [self getHeightForRows:@"Exam Group" detailedText:self.viewController.stellarClass.examGroup tableView:tableView];
			
		case DEPARTMENT:
			return [self getHeightForRows:@"Department" detailedText:self.viewController.stellarClass.department tableView:tableView];
		
		case SCHOOL:
			return [self getHeightForRows:@"School" detailedText:self.viewController.stellarClass.school tableView:tableView];
	}
	return 0;
}

-(CGFloat)getHeightForRows:(NSString *)text detailedText:(NSString *) detailedText tableView:(UITableView *)tableView{
	
	return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:text
											 maxTextLines:0
											   detailText:detailedText
										   maxDetailLines:0
													 font:nil 
											   detailFont:nil 
											accessoryType:UITableViewCellAccessoryNone
												cellImage:NO];
}

- (CGFloat) heightOfTableView: (UITableView *)tableView {
	NSInteger timeRows = [self.viewController.times count];
	CGFloat height = 0;
	NSInteger rowsIndex;
	for(rowsIndex=0; rowsIndex < timeRows; rowsIndex++) {
		height = height + [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:rowsIndex inSection:TIMES]];
	}
	
	height = height + [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:DESCRIPTION]];
	return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == TIMES) {
		StellarClassTime *classTime = [self.viewController.times objectAtIndex:indexPath.row];
		if([classTime.location length]) {
			if (![classTime.location isEqualToString:@"TBA"] && 
				![classTime.location isEqualToString:@"tba"] &&
				![classTime.location isEqualToString:@"TBD"] &&
				![classTime.location isEqualToString:@"tbd"] && 
				![classTime.location isEqualToString:@"Tbd"] && 
				![classTime.location isEqualToString:@"Tba"]) {
				StellarClassTime *classTime = [self.viewController.times objectAtIndex:indexPath.row];
				if([classTime.location length]) {
                    NSString *courseQuery = [NSString stringWithFormat:@"%@&loc=course", classTime.location];
					[[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:courseQuery]];
				}
			}
		}
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

@end

@implementation StellarLocationTableViewCell

- (void) layoutSubviews {
	[super layoutSubviews];
	CGRect frame = self.accessoryView.frame;
	frame.origin.x = 287;
	self.accessoryView.frame = frame;
}

@end


