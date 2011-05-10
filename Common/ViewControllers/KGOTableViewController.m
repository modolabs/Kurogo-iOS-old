#import "KGOTableViewController.h"
#import "KGOTheme.h"
#import "KGOSearchDisplayController.h"
#import "Foundation+KGOAdditions.h"

#define GROUPED_SECTION_HEADER_VPADDING 24
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
    self = [super init];
    if (self) {
		_tableController = [[KGOTableController alloc] initWithViewController:self];
		_tableController.dataSource = self;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_tableController = [[KGOTableController alloc] initWithViewController:self];
		_tableController.dataSource = self;
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super init];
    if (self) {
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
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
    self.tableView = [_tableController topTableView];
}

- (void)addTableView:(UITableView *)tableView {
	[_tableController addTableView:tableView];
    self.tableView = [_tableController topTableView];
}

- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource {
	[_tableController addTableView:tableView withDataSource:dataSource];
    self.tableView = [_tableController topTableView];
}

- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	return [_tableController addTableViewWithFrame:frame style:style];
}

- (void)bringTableViewToFront:(UITableView *)tableView {
    if (tableView != [_tableController topTableView]) {
        [tableView retain];
        [_tableController removeTableView:tableView];
        [_tableController addTableView:tableView];
        [tableView release];
    }
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

- (id)initWithTableView:(UITableView *)tableView dataSource:(id<KGOTableViewDataSource>)dataSource {
    self = [super init];
    if (self) {
		_currentTableView = tableView;
        _currentTableView.delegate = self;
        _currentTableView.dataSource = dataSource;
        _tableViewDataSources = [[NSMutableArray alloc] initWithObjects:dataSource, nil];
        _tableViews = [[NSMutableArray alloc] initWithObjects:_currentTableView, nil];
		_currentContentBuffer = [NSMutableDictionary dictionary];
		_cellContentBuffers = [[NSMutableArray alloc] initWithObjects:_currentContentBuffer, nil];
        _currentTableWidth = 0;
        
        _lastCachedRow = _lastCachedSection = 0;
	}
	return self;
}

- (id)initWithSearchController:(KGOSearchDisplayController *)searchController {
    self = [super init];
    if (self) {
		_searchController = searchController;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
		_cellContentBuffers = [[NSMutableArray alloc] init];
		_currentContentBuffer = nil;
		_currentTableView = nil;
        _currentTableWidth = 0;

        _lastCachedRow = _lastCachedSection = 0;
	}
	return self;
}

- (id)initWithViewController:(KGOTableViewController *)viewController {
    self = [super init];
    if (self) {
        _viewController = viewController;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
		_cellContentBuffers = [[NSMutableArray alloc] init];
		_currentContentBuffer = nil;
		_currentTableView = nil;
        _currentTableWidth = 0;

        _lastCachedRow = _lastCachedSection = 0;
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
    
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
	if (_viewController) {
		tableView.delegate = _viewController;
		tableView.dataSource = _viewController;
	} else if (_searchController) {
		tableView.delegate = self;
		tableView.dataSource = _searchController;
	}
	
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

    if (style == UITableViewStyleGrouped) {
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
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

- (BOOL)removeCachedViewsInSection:(NSInteger)section row:(NSInteger)row
{
    DLog(@"removing %d %d", section, row);
    NSString *key = [NSString stringWithFormat:@"%d.%d", section, row];
    if ([_currentContentBuffer objectForKey:key] != nil) {
        [_currentContentBuffer removeObjectForKey:key];
        DLog(@"removed %d %d", section, row);
        
        return YES;
    }
    return NO;
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
        
        // clear the buffer if we're too far away from where we last cached
        // e.g. if the tableview is long, we will have cached cells at the very end
        // from heightForRowAtIndexPath by the time we start calling
        // cellForRowAtIndexPath at the beginning
        NSInteger maxCells = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? MAX_CELL_BUFFER_IPHONE : MAX_CELL_BUFFER_IPAD;
        NSInteger maxCellsInBuffer = 2 * maxCells + 1;
        
        KGOSign sign = KGOSignZero;
        
        if (_lastCachedSection == indexPath.section) { // most common
            if (abs(indexPath.row - _lastCachedRow) > maxCellsInBuffer) {
                DLog(@"%d %d %@", _lastCachedSection, _lastCachedRow, indexPath);
                [_currentContentBuffer removeAllObjects];
            }
            sign = KGOGetIntegerSign(indexPath.row - _lastCachedRow);
            
        } else if (_lastCachedSection > indexPath.section) { // second most common for use case mentioned above
            sign = KGOSignNegative;
            
            if (_lastCachedRow > maxCells) {
                [_currentContentBuffer removeAllObjects];
                
            } else {
                NSInteger numRowsBetween = _lastCachedRow + 1;
                for (int i = _lastCachedSection; i > indexPath.section; i--) {
                    numRowsBetween += [dataSource tableView:tableView numberOfRowsInSection:i];
                    if (numRowsBetween > maxCells) {
                        [_currentContentBuffer removeAllObjects];
                        break;
                    }
                }
            }
            
        } else { // can't think of a use case for this
            sign = KGOSignPositive;
            
            NSInteger rowsInSection = [dataSource tableView:tableView numberOfRowsInSection:_lastCachedSection];
            NSInteger numRowsBetween = rowsInSection - _lastCachedRow;
            if (numRowsBetween > maxCells) {
                [_currentContentBuffer removeAllObjects];
                
            } else {
                for (int i = _lastCachedSection; i < indexPath.section; i++) {
                    numRowsBetween += [dataSource tableView:tableView numberOfRowsInSection:i];
                    if (numRowsBetween > maxCells) {
                        [_currentContentBuffer removeAllObjects];
                        break;
                    }
                }
            }
        }
        
        // retrieve cached views.
		if ([dataSource respondsToSelector:@selector(tableView:viewsForCellAtIndexPath:)]) {
			views = [dataSource tableView:tableView viewsForCellAtIndexPath:indexPath];
		}
        if (!views) {
            views = [NSArray array]; // don't skip values so the cache stays continuous
        }
        
        [_currentContentBuffer setObject:views forKey:key];
        
        // clear the buffer if we've added too many things to it
        NSInteger numSections = 1;
        if ([dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            numSections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        DLog(@"%d", _currentContentBuffer.count);
        if (_currentContentBuffer.count > maxCellsInBuffer) {
            
            if (sign == KGOSignPositive) {
                // clear cached cells before current cell
                NSInteger startRow = indexPath.row - maxCells - 1;
                NSInteger section = indexPath.section;
                while (startRow < 0 && section >= 0) {
                    section--;
                    if (section >= 0) {
                        startRow += [dataSource tableView:tableView numberOfRowsInSection:section] - 1;
                    }
                }
                
                while (startRow >= 0 && section >= 0 && [self removeCachedViewsInSection:section row:startRow]) {
                    startRow--;
                    if (startRow < 0) {
                        section--;
                        if (section >= 0) {
                            startRow = [dataSource tableView:tableView numberOfRowsInSection:section] - 1;
                        }
                    }
                }
                
            } else {
                // clear cached cells after current cell
                NSInteger startRow = indexPath.row + maxCells;
                NSInteger section = indexPath.section;
                NSInteger numRows = [dataSource tableView:tableView numberOfRowsInSection:section];
                while (startRow >= numRows && section < numSections) {
                    startRow -= numRows;
                    section++;
                    if (section < numSections) {
                        numRows = [dataSource tableView:tableView numberOfRowsInSection:section];
                    }
                }
                
                while (startRow < numRows && section < numSections && [self removeCachedViewsInSection:section row:startRow]) {
                    startRow++;
                    if (startRow >= numRows) {
                        startRow = 0;
                        section++;
                        if (section < numSections) {
                            numRows = [dataSource tableView:tableView numberOfRowsInSection:section];
                        }
                    }
                }
            }
        }
        
        _lastCachedSection = indexPath.section;
        _lastCachedRow = indexPath.row;

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
    KGOTableCellStyle internalStyle;
    UITableViewCellStyle style;
    UIFont *titleFont = nil;
    UIFont *subtitleFont = nil;
	
	if ([dataSource respondsToSelector:@selector(tableView:styleForCellAtIndexPath:)]) {
		internalStyle = [dataSource tableView:tableView styleForCellAtIndexPath:indexPath];
	} else {
		internalStyle = KGOTableCellStyleDefault;
	}
    
    switch (internalStyle) {
        case KGOTableCellStyleValue1:
            style = UITableViewCellStyleValue1;
            titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
            break;
        case KGOTableCellStyleValue2:
            style = UITableViewCellStyleValue2;
            titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListLabel];
            subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListValue];
            break;
        case KGOTableCellStyleSubtitle:
            titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            style = UITableViewCellStyleSubtitle;
            break;
        default:
            titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            style = UITableViewCellStyleDefault;
            break;
    }
    
	NSString *cellID = [NSString stringWithFormat:@"%d.%d", indexPath.section, internalStyle];
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
    
    // TODO: set theme colors as well
    
    cell.textLabel.font = titleFont;
    if (subtitleFont) {
        cell.detailTextLabel.font = subtitleFont;
    }
	
    if ([dataSource respondsToSelector:@selector(tableView:manipulatorForCellAtIndexPath:)]) {
        CellManipulator manipulateCell = [dataSource tableView:tableView manipulatorForCellAtIndexPath:indexPath];
        if (manipulateCell) {
            manipulateCell(cell);
        }
    }
    
	if (cachedViews.count) {
		for (UIView *aView in cachedViews) {
			[cell.contentView addSubview:aView];
		}
	}
    
    return cell;
}

// implementing this only because it is required by the protocol
// but it will never be called because the table view's dataSource property
// is not us but either a search display controller or table view controller
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

#pragma mark UITableViewDelegate methods

/*
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // UITableView will call this early on since it needs heights for the whole
    // table before it can start drawing, so we put this check here
    CGFloat width = tableView.frame.size.width;
    if (_currentTableWidth && width != _currentTableWidth) {
        [self decacheTableView:tableView];
    }
    _currentTableWidth = width;
    
    CGFloat height = 0;
    
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];

    NSString *title = nil;
    if ([dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        title = [dataSource tableView:tableView titleForHeaderInSection:section];
    }

    if (title) {
        if (tableView.style == UITableViewStylePlain) {
            height = [[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeader] lineHeight] + PLAIN_SECTION_HEADER_VPADDING;
        } else {
            height = [[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeaderGrouped] lineHeight] + GROUPED_SECTION_HEADER_VPADDING;
        }
    }
    return height;
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
    CGFloat hPadding = 10;
    CGFloat viewHeight;
    
    if (tableView.style == UITableViewStylePlain) {
        font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeader];
        textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySectionHeader];
        bgColor = [[KGOTheme sharedTheme] backgroundColorForPlainSectionHeader];
        viewHeight = font.lineHeight + PLAIN_SECTION_HEADER_VPADDING;
    } else {
        font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeaderGrouped];
        textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySectionHeaderGrouped];
        bgColor = [UIColor clearColor];
        viewHeight = font.lineHeight + GROUPED_SECTION_HEADER_VPADDING;
    }
    
    CGSize size = [title sizeWithFont:font];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(hPadding, floor((viewHeight - size.height) / 2), tableView.bounds.size.width - hPadding * 2, size.height)] autorelease];
	
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
