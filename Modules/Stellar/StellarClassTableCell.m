#import "StellarClassTableCell.h"
#import "UITableViewCell+MITUIAdditions.h"


@implementation StellarClassTableCell

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class {
	NSString *name;
	if([class.name length]) {
		name = class.name;
	} else {
		name = class.masterSubjectId;
	}
	cell.textLabel.text = name;
	
	cell.detailTextLabel.text = class.title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	[cell applyStandardFonts];
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
                                                           text:name
                                                   maxTextLines:0
                                                     detailText:title
                                                 maxDetailLines:0
                                                           font:nil 
                                                     detailFont:nil 
                                                  accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                                      cellImage:NO];
}
	
@end
