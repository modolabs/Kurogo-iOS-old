#import <Foundation/Foundation.h>
#import "StellarClass.h"
#import "MultiLineTableViewCell.h"

@interface StellarClassTableCell : MultiLineTableViewCell {

}

+(NSString *)setStaffNames:(StellarClass *)class previousClassInList: (StellarClass *)prevClass;
- (id) initWithReusableCellIdentifier: (NSString *)identifer;

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class previousClassInList: (StellarClass *)prevClass;

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView class: (StellarClass *)stellarClass;
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView class: (StellarClass *)stellarClass detailString:(NSString *)detail;
@end
