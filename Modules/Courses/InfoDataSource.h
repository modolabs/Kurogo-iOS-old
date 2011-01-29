
#import <Foundation/Foundation.h>
#import "StellarDetailViewController.h"
#import "MultiLineTableViewCell.h"
#import "JSONAPIRequest.h"

@interface InfoDataSource : StellarDetailViewControllerComponent <StellarDetailTableViewDelegate, JSONAPIDelegate> {
    
    NSMutableDictionary *mapAnnotations;

}
-(CGFloat)getHeightForRows:(NSString *)text detailedText:(NSString *) detailedText tableView:(UITableView *)tableView;
- (void)searchMapForTimes:(NSArray *)times;

@property (nonatomic, retain) NSMutableDictionary *mapAnnotations;

@end

@interface StellarLocationTableViewCell : MultiLineTableViewCell
{ }

@end
