#import "KGOTableViewController.h"
#import "KGOTheme.h"
#import "KGOSearchDisplayController.h"

#define GROUPED_SECTION_HEADER_VPADDING 22.0f
#define PLAIN_SECTION_HEADER_VPADDING 5.0f

#define MAX_CELL_PADDING 20.0f

// maximum number of cells to keep in memory above and below the current cell
#define MAX_CELL_BUFFER_IPHONE 12
#define MAX_CELL_BUFFER_IPAD 25


@interface KGOTableController (Private)

- (NSMutableDictionary *)contentBufferForTableView:(UITableView *)tableView;

@end



@implementation KGOTableViewController

// in this implementation file watch out for the distinction between _viewController, _searchController, and self.viewController

@synthesize tableView = _tableView;

- (id)init {
	if (self = [super init]) {
		_tableController = [[KGOTableController alloc] initWithViewController:self];
		_tableController.dataSource = self;
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super init]) {
		_tableController = [[KGOTableController alloc] initWithViewController:self];
		_tableController.dataSource = self;
		
		_didInitWithStyle = YES;
		_initStyle = style;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	
	if (_didInitWithStyle) {
        self.tableView = [_tableController addTableViewWithStyle:_initStyle];
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	if (_didInitWithStyle) {
        self.tableView = nil;
	}
}

- (void)removeTableView:(UITableView *)tableView {
	[_tableController removeTableView:tableView];
}

- (void)addTableView:(UITableView *)tableView {
	[_tableController addTableView:tableView];
}

- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource {
	[_tableController addTableView:tableView withDataSource:dataSource];
}

- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	return [_tableController addTableViewWithFrame:frame style:style];
}

- (void)reloadDataForTableView:(UITableView *)tableView {
	[_tableController reloadDataForTableView:tableView];
}

- (void)decacheTableView:(UITableView *)tableView {
	[_tableController decacheTableView:tableView];
}

- (void)dealloc {
	self.tableView = nil;
	[_tableController release];
	[super dealloc];
}

#pragma mark forwarding of UITableViewDataSource

// we need to implement here the exact same methods as KGOTableController
// and make sure none of KGOTableController's implementations make
// references back to us

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [_tableController tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

#pragma mark forwarding of UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [_tableController tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [_tableController tableView:tableView viewForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [_tableController tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end

#pragma mark -

@implementation KGOTableController

@synthesize dataSource = _dataSource, caching;

- (id)initWithSearchController:(KGOSearchDisplayController *)searchController {
	if (self = [super init]) {
		_searchController = searchController;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
		_cellContentBuffers = [[NSMutableArray alloc] init];
		_currentContentBuffer = nil;
		_currentTableView = nil;
	}
	return self;
}

- (id)initWithViewController:(KGOTableViewController *)viewController {
    if (self = [super init]) {
        _viewController = viewController;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
		_cellContentBuffers = [[NSMutableArray alloc] init];
		_currentContentBuffer = nil;
		_currentTableView = nil;
    }
    return self;
}

- (void)dealloc {
    self.dataSource = nil;
    _viewController = nil;
	_searchController = nil;
	
    [_tableViews release];
    [_tableViewDataSources release];
    [_cellContentBuffers release];
	
    [super dealloc];
}

- (UIViewController *)viewController {
    if (_viewController) {
        return _viewController;
    } else if (_searchController) {
        return _searchController.searchContentsController;
    }
    return nil;
}

#pragma mark Table view queue

- (UITableView *)topTableView {
    return [_tableViews lastObject];
}

- (NSArray *)tableViews {
    return [NSArray arrayWithArray:_tableViews];
}

- (void)removeTableView:(UITableView *)tableView {
	if (tableView == _currentTableView) {
		_currentTableView = nil;
	}

	NSInteger tableViewIndex = [_tableViews indexOfObject:tableView];
    if (tableViewIndex != NSNotFound) {
        [tableView removeFromSuperview];

        [_tableViews removeObjectAtIndex:tableViewIndex];
        [_tableViewDataSources removeObjectAtIndex:tableViewIndex];
		[_cellContentBuffers removeObjectAtIndex:tableViewIndex];
    }
}

- (void)removeTableViewAtIndex:(NSInteger)tableViewIndex {
    UITableView *tableView = [_tableViews objectAtIndex:tableViewIndex];
    [tableView removeFromSuperview];

    [_tableViews removeObjectAtIndex:tableViewIndex];
    [_tableViewDataSources removeObjectAtIndex:tableViewIndex];
    [_cellContentBuffers removeObjectAtIndex:tableViewIndex];
}

- (void)removeAllTableViews {
    for (UITableView *tableView in _tableViews) {
        [tableView removeFromSuperview];
    }
    [_tableViews removeAllObjects];
    [_tableViewDataSources removeAllObjects];
    [_cellContentBuffers removeAllObjects];
}

- (void)addTableView:(UITableView *)tableView {
	[self addTableView:tableView withDataSource:self.dataSource];
}

- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource {
	[_tableViews addObject:tableView];
	[_tableViewDataSources addObject:dataSource];
	[_cellContentBuffers addObject:[NSMutableDictionary dictionary]];
	
	[self.viewController.view addSubview:tableView];
}

- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style {
    return [self addTableViewWithStyle:style dataSource:self.dataSource];
}

- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource {
	CGRect frame;
	if (_viewController) {
		frame = CGRectMake(0, 0, _viewController.view.bounds.size.width, _viewController.view.bounds.size.height);
	} else if (_searchController) {
        UIViewController *vc = _searchController.searchContentsController;
		frame = CGRectMake(0, 0, vc.view.bounds.size.width, vc.view.bounds.size.height);
    } else {
		return nil;
	}
    return [self addTableViewWithFrame:frame style:style dataSource:dataSource];
}

- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	return [self addTableViewWithFrame:frame style:style dataSource:self.dataSource];
}

- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource {
    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame style:style] autorelease];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    if (style == UITableViewStyleGrouped) {
        tableView.backgroundColor = [UIColor clearColor];
    }
    
	if (_viewController) {
		tableView.delegate = _viewController;
		tableView.dataSource = _viewController;
	} else if (_searchController) {
		tableView.delegate = self;
		tableView.dataSource = _searchController;
	} else {
		return nil;
	}
	
	[self addTableView:tableView withDataSource:dataSource];
	
    return tableView;
}

- (void)reloadDataForTableView:(UITableView *)tableView {
	[self decacheTableView:tableView];
	[tableView reloadData];
}

- (void)decacheTableView:(UITableView *)tableView {
	NSMutableDictionary *dict = [self contentBufferForTableView:tableView];
	[dict removeAllObjects];
}

- (id<KGOTableViewDataSource>)dataSourceForTableView:(UITableView *)tableView {
    NSInteger tableViewIndex = [_tableViews indexOfObject:tableView];
    if (tableViewIndex != NSNotFound) {
        return [_tableViewDataSources objectAtIndex:tableViewIndex];
    }
    return nil;
}

- (NSMutableDictionary *)contentBufferForTableView:(UITableView *)tableView {
    NSInteger tableViewIndex = [_tableViews indexOfObject:tableView];
    if (tableViewIndex != NSNotFound) {
		return [_cellContentBuffers objectAtIndex:tableViewIndex];
    }
    return nil;
}

- (NSArray *)tableView:tableView cachedViewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.caching) {
        id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
		if ([dataSource respondsToSelector:@selector(tableView:viewsForCellAtIndexPath:)]) {
			return [dataSource tableView:tableView viewsForCellAtIndexPath:indexPath];
		}
        return nil;
    }
    
	if (tableView != _currentTableView) {
		_currentContentBuffer = [self contentBufferForTableView:tableView];
		_currentTableView = tableView;
	}
	
    NSString *key = [NSString stringWithFormat:@"%d.%d", indexPath.section, indexPath.row];
    NSArray *views = [_currentContentBuffer objectForKey:key];
    if (!views) {
        id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
		if ([dataSource respondsToSelector:@selector(tableView:viewsForCellAtIndexPath:)]) {
			views = [dataSource tableView:tableView viewsForCellAtIndexPath:indexPath];
		}
        if (!views) {
            views = [NSArray array]; // don't skip values so the cache stays continuous
        }
        
        [_currentContentBuffer setObject:views forKey:key];
        
        // clear the buffer if we've added too many things to it
        NSInteger maxCells = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? MAX_CELL_BUFFER_IPHONE : MAX_CELL_BUFFER_IPAD;
        while (_currentContentBuffer.count > maxCells * 2 + 1) {
            
            BOOL (^removeFromCellBuffer)(NSInteger, NSInteger) = ^(NSInteger section, NSInteger row) {
                NSString *key = [NSString stringWithFormat:@"%d.%d", section, row];
                if ([_currentContentBuffer objectForKey:key] != nil) {
                    [_currentContentBuffer removeObjectForKey:key];
                    return YES;
                }
                return NO;
            };
            
            BOOL didRemove = NO;
            NSInteger section;
            NSInteger startRow = indexPath.row - maxCells - 1;
            // clear out any cached cell data more than maxCells back
            for (section = indexPath.section; section >= 0; section--) {
                if (startRow >= 0) {
                    if (didRemove = removeFromCellBuffer(section, startRow)) {
                        break;
                    }
                } else if (section > 0) {
                    NSInteger numRows = [self tableView:tableView numberOfRowsInSection:section - 1];
                    startRow = numRows + startRow - 1;
                }
            }
            
            if (!didRemove) {
                // clear out cached cell data more than maxCells forward
                startRow = indexPath.row + maxCells;
                NSInteger numSections = [self numberOfSectionsInTableView:tableView];
                for (section = indexPath.section; section < numSections; section++) {
                    NSInteger numRowsInCurrentSection = [self tableView:tableView numberOfRowsInSection:indexPath.section];
                    if (startRow <= numRowsInCurrentSection) {
                        if (didRemove = removeFromCellBuffer(section, startRow)) {
                            break;
                        }
                    } else {
                        startRow -= numRowsInCurrentSection;
                    }
                }
            }
            
        }

    }
    return views;
}

#pragma mark -
#pragma mark UITableViewDataSource wrapper

// we do not implement titleForHeaderInSection and titleForFooterInSection

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
	
    NSArray *cachedViews = [self tableView:tableView cachedViewsForCellAtIndexPath:indexPath];
    UITableViewCell *cell = nil;
    UITableViewCellStyle style;
	
	if ([dataSource respondsToSelector:@selector(tableView:styleForCellAtIndexPath:)]) {
		style = [dataSource tableView:tableView styleForCellAtIndexPath:indexPath];
	} else {
		style = UITableViewCellStyleDefault;
	}
	NSString *cellID = [NSString stringWithFormat:@"%d", style];
	cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellID] autorelease];
		
	} else {
		for (UIView *aView in cell.contentView.subviews) {
			if (aView != cell.textLabel && aView != cell.detailTextLabel && aView != cell.imageView && aView != cell.accessoryView) {
				[aView removeFromSuperview];
			}
		}
	}
	
    if ([dataSource respondsToSelector:@selector(tableView:manipulatorForCellAtIndexPath:)]) {
        CellManipulator manipulateCell = [dataSource tableView:tableView manipulatorForCellAtIndexPath:indexPath];
        manipulateCell(cell);
    }
    
	if (cachedViews.count) {
		for (UIView *aView in cachedViews) {
			[cell.contentView addSubview:aView];
		}
	}
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

#pragma mark UITableViewDelegate methods

/*
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];

    NSString *title = nil;
    if ([dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        title = [dataSource tableView:tableView titleForHeaderInSection:section];
    }

    if (!title)
        return 0;
    
    if (tableView.style == UITableViewStylePlain) {
        return [[[KGOTheme sharedTheme] fontForPlainSectionHeader] pointSize] + PLAIN_SECTION_HEADER_VPADDING;
    } else {
        return [[[KGOTheme sharedTheme] fontForGroupedSectionHeader] pointSize] + GROUPED_SECTION_HEADER_VPADDING;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *views = [self tableView:tableView cachedViewsForCellAtIndexPath:indexPath];
    
    if (!views.count) {
        return tableView.rowHeight;
    }

    // the following assumes the cell has symmetrical minimum top padding and minimum bottom padding
    CGFloat ymin = MAX_CELL_PADDING;
    CGFloat ymax = 0.0;
    for (UIView *aView in views) {
        if (aView.frame.origin.y < ymin)
            ymin = aView.frame.origin.y;
        
        CGFloat bottom = aView.frame.origin.y + aView.frame.size.height;
        if (bottom > ymax)
            ymax = bottom;
    }
    return fmax(ymax + ymin, tableView.rowHeight);
}

/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
}
*/

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    NSString *title = nil;
    if ([dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        title = [dataSource tableView:tableView titleForHeaderInSection:section];
    }
    
    if (!title)
        return nil;
    
    UIFont *font;
    UIColor *textColor;
    UIColor *bgColor;
    CGFloat hPadding;
    CGFloat viewHeight;
    
    if (tableView.style == UITableViewStylePlain) {
        font = [[KGOTheme sharedTheme] fontForPlainSectionHeader];
        textColor = [[KGOTheme sharedTheme] textColorForPlainSectionHeader];
        bgColor = [[KGOTheme sharedTheme] backgroundColorForPlainSectionHeader];
        hPadding = 10.0f;
        viewHeight = font.pointSize + PLAIN_SECTION_HEADER_VPADDING;
    } else {
        font = [[KGOTheme sharedTheme] fontForGroupedSectionHeader];
        textColor = [[KGOTheme sharedTheme] textColorForGroupedSectionHeader];
        bgColor = [UIColor clearColor];
        hPadding = 20.0f;
        viewHeight = font.pointSize + GROUPED_SECTION_HEADER_VPADDING;
    }
    
    CGSize size = [title sizeWithFont:font];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(hPadding, 0.0, tableView.bounds.size.width - hPadding * 2, size.height)] autorelease];
	
	label.text = title;
	label.textColor = textColor;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.bounds.size.width, viewHeight)] autorelease];
	labelContainer.backgroundColor = bgColor;
	
	[labelContainer addSubview:label];	
	
	return labelContainer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [dataSource tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
*/

@end
