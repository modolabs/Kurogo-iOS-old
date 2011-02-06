#import <UIKit/UIKit.h>
#import "KGOTheme.h"

typedef void (^CellManipulator)(UITableViewCell *);

@protocol KGOTableViewDataSource <UITableViewDataSource>

@optional

/*
 * if you implement -tableView:viewsForCellAtIndexPath:
 * then you must clear the view cache before you reload anything
 * you can use -decacheTableView: before reloading rows/sections
 * or -reloadDataForTableView: in place of [tableView reloadData]
 */
- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath;
- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath;

/*
 * this is a cheap way to make the delegate return something and have this class perform
 * all those actions on the cell instead of calling something like -[tableView:doSomethingOnCell:]
 * and not be the one in control at the end of the function.
 *
 * obviously the receiver could still return a code block that can do any crazy thing it wants
 * which isn't any different in practice.
 */
- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@class KGOTableController;
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
@interface KGOTableViewController : UIViewController <UITableViewDelegate, KGOTableViewDataSource> {
	KGOTableController *_tableController;
	UITableView *_tableView;
}

@property (nonatomic, retain) UITableView *tableView;

- (id)initWithStyle:(UITableViewStyle)style;

- (void)removeTableView:(UITableView *)tableView;

- (void)addTableView:(UITableView *)tableView;
- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource;
- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style;

- (void)reloadDataForTableView:(UITableView *)tableView;
- (void)decacheTableView:(UITableView *)tableView;

@end

//@interface KGOTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, KGOTableViewDataSource> {
@interface KGOTableController : NSObject <UITableViewDelegate, UITableViewDataSource> {
	KGOTableViewController *_viewController;
	id<UITableViewDelegate, UITableViewDataSource> _searchController;
	
    NSMutableArray *_tableViews;
    NSMutableArray *_tableViewDataSources;
    
	NSMutableArray *_cellContentBuffers;
	
	UITableView *_currentTableView;
    NSMutableDictionary *_currentContentBuffer;

    id<KGOTableViewDataSource> _dataSource;
}

@property (nonatomic, readonly) KGOTableViewController *viewController;
@property (nonatomic, assign) id<KGOTableViewDataSource> dataSource;

//- (id)initWithStyle:(UITableViewStyle)style;
//- (id)initWithDataSource:(id<KGOTableViewDataSource>)dataSource;
- (id)initWithViewController:(KGOTableViewController *)viewController;
- (id)initWithSearchController:(id<UITableViewDelegate, UITableViewDataSource>)searchController;

- (void)removeTableView:(UITableView *)tableView;

- (void)addTableView:(UITableView *)tableView;
- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource;
- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style;
- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource;
- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style;
- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource;

- (void)reloadDataForTableView:(UITableView *)tableView;
- (void)decacheTableView:(UITableView *)tableView;

@end
