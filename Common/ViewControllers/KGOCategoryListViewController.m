#import "KGOCategoryListViewController.h"
#import "KGOSearchModel.h"
#import "KGOMapCategory.h"
#import "KGOEventCategory.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"

@implementation KGOCategoryListViewController

@synthesize parentCategory, request, entityName;

- (void)loadView {
	[super loadView];
    
    self.title = NSLocalizedString(@"Browse", nil);
	
	if (!self.tableView) {
		CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
		self.tableView = [self addTableViewWithFrame:frame style:UITableViewStyleGrouped];
	}
    
    if (!self.categories && self.request) {
        [self.request connect];
    }
}

- (NSArray *)categories {
	return _categories;
}

- (void)setCategories:(NSArray *)categories {
	[_categories release];
	_categories = [categories retain];
	
	if ([self isViewLoaded]) {
		[self reloadDataForTableView:self.tableView];
	}
}

- (UIView *)headerView {
	return _headerView;
}

- (void)setHeaderView:(UIView *)headerView {
	[_headerView release];
	_headerView = [headerView retain];
	self.tableView.tableHeaderView = _headerView;
}

#pragma KGORequestDelegate

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    self.request = nil;
    
    NSArray *categories = nil;
    if (self.parentCategory == nil) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"parentCategory = NULL"];
        categories = [[CoreDataManager sharedManager] objectsForEntity:self.entityName matchingPredicate:pred];
    } else {
        categories = [self.parentCategory children];
    }

    self.categories = categories;
    [self reloadDataForTableView:self.tableView];
}

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.categories count];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellStyleDefault;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
	id<KGOCategory> category = [self.categories objectAtIndex:indexPath.row];
	NSString *title = category.title;
    NSString *accessory = KGOAccessoryTypeNone;
    if ([category children].count) {
        accessory = KGOAccessoryTypeChevron;
    }
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id<KGOCategory> category = [self.categories objectAtIndex:indexPath.row];
	NSString *moduleTag = nil;
	if ([category isKindOfClass:[KGOMapCategory class]]) {
		moduleTag = MapTag;
	} else if ([category isKindOfClass:[KGOEventCategory class]]) {
		moduleTag = CalendarTag;
	}
	
	NSArray *subcategories = category.children;
	if (subcategories) {
		NSDictionary *params = [NSDictionary dictionaryWithObject:subcategories forKey:@"categories"];
		[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameCategoryList forModuleTag:moduleTag params:params];
		
	} else {
		NSArray *items = category.items;
		if (items) {
			NSDictionary *params = [NSDictionary dictionaryWithObject:items forKey:@"items"];
			[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameItemList forModuleTag:moduleTag params:params];
		}
	}
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.headerView = nil;
	self.categories = nil;
    [super dealloc];
}

@end
