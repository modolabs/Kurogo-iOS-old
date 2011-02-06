#import <UIKit/UIKit.h>
#import "KGOTheme.h"

typedef void (^CellManipulator)(UITableViewCell *);

@protocol KGOTableViewDataSource <UITableViewDataSource>

@optional

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath;
- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath;
- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath;

@end

/*
 * This class is a UITableViewDatasource/UITableViewDelegate wrapper that serves the following purposes:
 * - take over implementation of tableView:heightForRowAtIndexPath
 * - take over implementation of tableView:viewForHeaderInSection and tableView:heightForHeaderInSection
 *
 * Eventually we will also include similar takeovers for section footers
 *
 * Subclasses should not implement the above methods (and subclasses that wouldn't otherwise need the above methods shold not use this class).
 * To achieve variable cell heights, subclasses shold implement tableView:viewsForCellAtIndexPath.
 * To use UIKit cell styles without allocating cells themself, subclasses should implement tableView:manipulatorForCellAtIndexPath to return a block that acts on allocated cells.
 * To use diffrent UIKit cell styles within the same tableView, implement tableView:styleForCellAtIndexPath.
 *
 * Subclasses may implement tableView:cellForRowAtIndexPath to override this class' behavior.
 *
 * Do not use this class for large (1000+ cell) tables due to documented performance pentalties associated with variable cell heights.
 */

@interface KGOTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, KGOTableViewDataSource> {
    NSMutableArray *_tableViews;
    NSMutableArray *_tableViewDataSources;
    
    NSMutableDictionary *_cellContentBuffer;
    id<KGOTableViewDataSource> _dataSource;
	UITableView *_tableView;
}

@property (nonatomic, assign) id<KGOTableViewDataSource> dataSource;
@property (nonatomic, retain) UITableView *tableView;

- (id)initWithStyle:(UITableViewStyle)style;
- (id)initWithDataSource:(id<KGOTableViewDataSource>)dataSource;

- (void)removeTableView:(UITableView *)tableView;

- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource;
- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style;
- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource;
- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource;

@end
