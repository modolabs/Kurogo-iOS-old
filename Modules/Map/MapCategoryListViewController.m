#import "MapCategoryListViewController.h"
#import "KGOSearchModel.h"
#import "MapModel.h"
#import "KGOCalendar.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "UIKit+KGOAdditions.h"

@implementation MapCategoryListViewController

@synthesize parentCategory,
dataManager,
listItems,
headerView = _headerView;

- (void)showDetailPageForItem:(id<KGOSearchResult>)leafItem
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:leafItem, @"detailItem", nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.dataManager.moduleTag params:params];
}

- (void)loadView {
	[super loadView];
    
    self.title = NSLocalizedString(@"Browse", nil);

    UITableViewStyle style = UITableViewStyleGrouped;
    BOOL isPopulated = NO;

    // auto-expand if there is only one category at this level
    while (self.listItems.count == 1) {
        id object = [self.listItems objectAtIndex:0];
        if ([object conformsToProtocol:@protocol(KGOCategory)]) {
            id<KGOCategory> category = (id<KGOCategory>)object;
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
            NSArray *categories = [category.children sortedArrayUsingDescriptors:sortDescriptors];
            NSArray *items = [category.items sortedArrayUsingDescriptors:sortDescriptors];
            if (categories) {
                self.listItems = [categories arrayByAddingObjectsFromArray:items];
            } else if (items) {
                self.listItems = items;
            }
        } else if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
            // if we got to this point and there's only a single result, just display it
            // otherwise the user might just see a modal view controller animate in and out
            break;
        }
    }

    if (self.listItems.count) {
        id object = [self.listItems objectAtIndex:0];
        if ([object conformsToProtocol:@protocol(KGOCategory)]) {
            isPopulated = YES;
        } else if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
            style = UITableViewStylePlain;
            isPopulated = YES;
        }
    }

	if (isPopulated && !self.tableView) {
		CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
		self.tableView = [self addTableViewWithFrame:frame style:style];

	} else {
        self.dataManager.delegate = self;
        if (self.parentCategory) {
            [self.dataManager requestChildrenForCategory:self.parentCategory.identifier];
        } else {
            [self.dataManager requestBrowseIndex];
        }
        [self showLoadingView];
    }
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark KGORequestDelegate

- (void)showLoadingView
{
    if (!_loadingView) {
        UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];

        NSString *text = NSLocalizedString(@"Loading...", nil);
        UIFont *font = [UIFont systemFontOfSize:15];
        CGSize size = [text sizeWithFont:font];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width, 0, size.width, size.height)] autorelease];
        label.text = text;
        label.font = font;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
                
        CGFloat totalWidth = spinny.frame.size.width + label.frame.size.width;
        CGFloat totalHeight = fmaxf(spinny.frame.size.height, label.frame.size.height);
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth + 20, totalHeight + 20)];
        _loadingView.center = self.view.center;
        _loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _loadingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        _loadingView.layer.cornerRadius = 10;

        spinny.frame = CGRectMake(10, 10, spinny.frame.size.width, spinny.frame.size.height);
        label.frame = CGRectMake(label.frame.origin.x + 10, 10, label.frame.size.width, label.frame.size.height);
        
        [spinny startAnimating];
        [_loadingView addSubview:spinny];
        [_loadingView addSubview:label];
        
        [self.view addSubview:_loadingView];
    }
}

- (void)hideLoadingView
{
    if (_loadingView) {
        [_loadingView removeFromSuperview];
        [_loadingView release];
        _loadingView = nil;
    }
}

- (void)mapDataManager:(MapDataManager *)dataManager
    didReceiveChildren:(NSArray *)children
           forCategory:(NSString *)categoryID
{
    self.listItems = children;
    id object = [self.listItems objectAtIndex:0];
    
    if (self.listItems.count == 1) {
        if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
            [self showDetailPageForItem:object];
        } else {
            [self.dataManager requestChildrenForCategory:[object identifier]];
        }
    
    } else {
        [self hideLoadingView];
        
        UITableViewStyle style = UITableViewStyleGrouped;
        if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
            style = UITableViewStylePlain;
        }
        
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        self.tableView = [self addTableViewWithFrame:frame style:style];
    }
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listItems.count;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleDefault;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = nil;
    NSString *accessory = nil;
    
    id object = [self.listItems objectAtIndex:indexPath.row];
    if ([object conformsToProtocol:@protocol(KGOCategory)]) {
        title = [(id<KGOCategory>)object title];
        accessory = KGOAccessoryTypeChevron;
    } else if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
        title = [(id<KGOCategory>)object title];
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = title;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.listItems objectAtIndex:indexPath.row];
    if ([object conformsToProtocol:@protocol(KGOCategory)]) {
        id<KGOCategory> category = (id<KGOCategory>)object;
        if ([category respondsToSelector:@selector(moduleTag)]) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:category, @"parentCategory", nil];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
            if (category.children.count) {
                [params setObject:[category.children sortedArrayUsingDescriptors:sortDescriptors]
                           forKey:@"listItems"];
                
            } else if (category.items.count) {
                [params setObject:[category.items sortedArrayUsingDescriptors:sortDescriptors]
                           forKey:@"listItems"];
            }
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameCategoryList forModuleTag:self.dataManager.moduleTag params:params];
        }
    } else if ([object conformsToProtocol:@protocol(KGOSearchResult)]) {
        [self showDetailPageForItem:object];
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
    self.listItems = nil;
    self.parentCategory = nil;
    
    self.dataManager.delegate = nil;
    self.dataManager = nil;
    
    [super dealloc];
}

@end
