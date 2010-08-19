#import "StellarClassTableCell.h"
#import "UITableViewCell+MITUIAdditions.h"
#import "MITUIConstants.h"


@implementation StellarClassTableCell

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class previousClassInList: (StellarClass *)prevClass{
	NSString *name;
	if([class.name length]) {
		name = class.name;
		
	} else {
		name = class.masterSubjectId;
	}
	/*NSArray *instructors = [[[class.staff allObjects]
	  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type like 'instructor'"]]
	 sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
	
	(StellarStaffMember *)[instructors objectAtIndex:indexPath.row]
	
	if (prevClass != nil) {
		if ([prevClass.name length]) {
			if ([prevClass.name isEqualToString:[class.name]])
				name = [name stringByAppendingFormat:@" (%@)", [[[class.staff allObjects]]   ];
		}
	}*/
	
	/*if ([[name substringToIndex:1] isEqualToString:@"0"])
		name = [name substringFromIndex:1];*/
	
	if ([[name substringToIndex:1] isEqualToString:@"0"])
		cell.detailTextLabel.text = [name substringFromIndex:1];
	
	else {
		cell.detailTextLabel.text = name;
	}


	
	cell.textLabel.text = class.title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:13];

	return cell;
}

- (id) initWithReusableCellIdentifier: (NSString *)identifer {
	return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
}
	
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView class: (StellarClass *)stellarClass {
	NSString *name = @"name"; // a single line
	NSString *title = nil; // a single line
	if (stellarClass.name) {
		name = stellarClass.name;
	}
	if (stellarClass.title) {
		title = stellarClass.title;
	}
    
	return 2.0 + [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
                                                      tableView:tableView 
                                                           text:title
                                                   maxTextLines:0
                                                     detailText:name
                                                 maxDetailLines:0
                                                           font:nil 
                                                     detailFont:nil 
                                                  accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                                      cellImage:NO];
}
	
@end
