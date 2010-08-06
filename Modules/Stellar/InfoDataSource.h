
#import <Foundation/Foundation.h>
#import "StellarDetailViewController.h"
#import "MultiLineTableViewCell.h"

@interface InfoDataSource : StellarDetailViewControllerComponent <StellarDetailTableViewDelegate> {

}
-(CGFloat)getHeightForRows:(NSString *)text detailedText:(NSString *) detailedText tableView:(UITableView *)tableView;

@end

@interface StellarLocationTableViewCell : MultiLineTableViewCell
{ }

@end
