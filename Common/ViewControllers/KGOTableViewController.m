#import "KGOTableViewController.h"
#import "KGOTheme.h"

#define GROUPED_SECTION_HEADER_VPADDING 22.0f
#define PLAIN_SECTION_HEADER_VPADDING 5.0f

#define MAX_CELL_PADDING 20.0f

// maximum number of cells to keep in memory above and below the current cell
#define MAX_CELL_BUFFER_IPHONE 12
#define MAX_CELL_BUFFER_IPAD 25

@implementation KGOTableViewController

@synthesize dataSource = _dataSource, tableView = _tableView;

- (id)init {
	if (self = [super init]) {
        self.dataSource = self;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
        _cellContentBuffer = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super init]) {
        self.dataSource = self;
		
        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
        _cellContentBuffer = [[NSMutableDictionary alloc] init];
		
        [self addTableViewWithStyle:style];
    }
    return self;
}

- (id)initWithDataSource:(id<KGOTableViewDataSource>)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;

        _tableViews = [[NSMutableArray alloc] init];
        _tableViewDataSources = [[NSMutableArray alloc] init];
        _cellContentBuffer = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)removeTableView:(UITableView *)tableView {
    NSInteger tableViewIndex = [_tableViews indexOfObject:tableView];
    if (tableViewIndex != NSNotFound) {
        [tableView removeFromSuperview];

        [_tableViews removeObjectAtIndex:tableViewIndex];
        [_tableViewDataSources removeObjectAtIndex:tableViewIndex];
    }
}

- (void)addTableView:(UITableView *)tableView withDataSource:(id<KGOTableViewDataSource>)dataSource {
	[_tableViews addObject:tableView];
	[_tableViewDataSources addObject:dataSource];
	
	[self.view addSubview:tableView];
}

- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style {
    return [self addTableViewWithStyle:style dataSource:self.dataSource];
}

- (UITableView *)addTableViewWithStyle:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource {
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    return [self addTableViewWithFrame:frame style:style dataSource:dataSource];
}

- (UITableView *)addTableViewWithFrame:(CGRect)frame style:(UITableViewStyle)style dataSource:(id<KGOTableViewDataSource>)dataSource {
    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame style:style] autorelease];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    if (style == UITableViewStyleGrouped) {
        tableView.backgroundColor = [UIColor clearColor];
    }
    
    tableView.delegate = self;
    tableView.dataSource = self;

    [_tableViews addObject:tableView];
    [_tableViewDataSources addObject:dataSource];
    
    [self.view addSubview:tableView];
    return tableView;
}

- (void)dealloc {
    self.dataSource = nil;
    
    [_tableViews release];
    [_tableViewDataSources release];
    [_cellContentBuffer release];

    [super dealloc];
}

- (id<KGOTableViewDataSource>)dataSourceForTableView:(UITableView *)tableView {
    NSInteger tableViewIndex = [_tableViews indexOfObject:tableView];
    if (tableViewIndex != NSNotFound) {
        return [_tableViewDataSources objectAtIndex:tableViewIndex];
    }
    return nil;
}

- (NSArray *)tableView:tableView cachedViewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [NSString stringWithFormat:@"%d.%d", indexPath.section, indexPath.row];
    NSArray *views = [_cellContentBuffer objectForKey:key];
    if (!views) {
        id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
		if ([dataSource respondsToSelector:@selector(tableView:viewsForCellAtIndexPath:)]) {
			views = [dataSource tableView:tableView viewsForCellAtIndexPath:indexPath];
		}
        if (!views) {
            views = [NSArray array]; // don't skip values so the cache stays continuous
        }
        
        [_cellContentBuffer setObject:views forKey:key];
        
        // clear the buffer if we've added too many things to it
        NSInteger maxCells = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? MAX_CELL_BUFFER_IPHONE : MAX_CELL_BUFFER_IPAD;
        while (_cellContentBuffer.count > maxCells * 2 + 1) {
            
            BOOL (^removeFromCellBuffer)(NSInteger, NSInteger) = ^(NSInteger section, NSInteger row) {
                NSString *key = [NSString stringWithFormat:@"%d.%d", section, row];
                if ([_cellContentBuffer objectForKey:key] != nil) {
                    [_cellContentBuffer removeObjectForKey:key];
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
	// subclasses that implement this take priority
	id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
	
    static NSString *CellIdentifier = @"Cell";

    NSArray *cachedViews = [self tableView:tableView cachedViewsForCellAtIndexPath:indexPath];
    UITableViewCell *cell = nil;
    UITableViewCellStyle style;
    
    if (cachedViews.count) {
        style = UITableViewCellStyleDefault;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        } else {
            for (UIView *aView in cell.contentView.subviews) {
                if (aView != cell.textLabel && aView != cell.detailTextLabel && aView != cell.imageView && aView != cell.accessoryView) {
                    [aView removeFromSuperview];
                }
            }
        }

    } else {
        if ([dataSource respondsToSelector:@selector(tableView:styleForCellAtIndexPath:)]) {
            style = [dataSource tableView:tableView styleForCellAtIndexPath:indexPath];
        } else {
            style = UITableViewCellStyleDefault;
        }
        
        NSString *cellID = [NSString stringWithFormat:@"%d", style];
        cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellID] autorelease];
        }
    }

    if ([dataSource respondsToSelector:@selector(tableView:manipulatorForCellAtIndexPath:)]) {
        CellManipulator manipulateCell = [dataSource tableView:tableView manipulatorForCellAtIndexPath:indexPath];
        manipulateCell(cell);
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:sectionForSectionIndexTitle:atIndex:)]) {
        return [dataSource tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    return [dataSource tableView:tableView numberOfRowsInSection:section];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
        [dataSource tableView:tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
        return [dataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
        return [dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    return NO;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(sectionIndexTitlesForTableView:)]) {
        return [dataSource sectionIndexTitlesForTableView:tableView];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id<KGOTableViewDataSource> dataSource = [self dataSourceForTableView:tableView];
    if ([dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return [dataSource numberOfSectionsInTableView:tableView];
    }
    return 1;
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

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
        bgColor = [[KGOTheme sharedTheme] plainSectionHeaderBackgroundColor];
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
