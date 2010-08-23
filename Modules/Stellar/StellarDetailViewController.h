#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "TabViewControl.h"
#import "MITModuleURL.h"


@class StellarDetailViewController;
@interface ClassInfoLoader : NSObject <ClassInfoLoadedDelegate>
{
	StellarDetailViewController *viewController;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;
@end

@interface MyStellarStatusDelegate : NSObject <JSONAPIDelegate>
{
	StellarDetailViewController *viewController;
	BOOL status;
	StellarClass *stellarClass;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;

- (id) initWithClass: (StellarClass *)class status: (BOOL)newStatus viewController: (StellarDetailViewController *)controller;
@end

typedef enum {
	StellarNewsLoadingInProcess,
	StellarNewsLoadingSucceeded,
	StellarNewsLoadingFailed
} StellarNewsLoadingState;
	
@interface StellarDetailViewController : UITableViewController <TabViewControlDelegate> {
	ClassInfoLoader *currentClassInfoLoader;
	MyStellarStatusDelegate *myStellarStatusDelegate;
	
	StellarClass *stellarClass;
	
	NSArray *news;
	NSArray *instructors;
	NSArray *tas;
	NSArray *times;
	
	NSMutableArray *dataSources;
	
	UILabel *titleView;
	UILabel *termView;
	UILabel *classNumberView;
	UIBarButtonItem *actionButton;
	UIButton *myStellarButton;
	
	TabViewControl *tabViewControl;
	NSString *currentTabName;
	NSMutableArray *currentTabNames; 

	BOOL refreshClass;
	StellarNewsLoadingState loadingState;
	MITModuleURL *url;
	
	BOOL classDetailsLoaded;
	UIView *loadingView;
	UIView *nothingToDisplay;
}

@property (nonatomic, retain) ClassInfoLoader *currentClassInfoLoader;
@property (nonatomic, retain) MyStellarStatusDelegate *myStellarStatusDelegate;

@property (nonatomic, retain) StellarClass *stellarClass;

@property (nonatomic, retain) NSArray *news;
@property (nonatomic, retain) NSArray *instructors;
@property (nonatomic, retain) NSArray *tas;
@property (nonatomic, retain) NSArray *times;

@property (nonatomic, assign) UILabel *titleView;
@property (nonatomic, assign) UILabel *termView;
@property (nonatomic, assign) UILabel *classNumberView;
@property (nonatomic, assign) UIButton *myStellarButton;

@property (nonatomic, retain) NSMutableArray *dataSources;

@property (nonatomic, assign) BOOL refreshClass;
@property (nonatomic, assign) StellarNewsLoadingState loadingState;

@property (readonly) MITModuleURL *url;

@property (nonatomic, assign) BOOL classDetailsLoaded;

@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UIView *nothingToDisplay;

@property (nonatomic, retain) NSString *currentTabName;

+ (StellarDetailViewController *) launchClass: (StellarClass *)stellarClass viewController: (UIViewController *)controller;

- (id) initWithClass: (StellarClass *)stellarClass;

- (void) loadClassInfo:(StellarClass *)class;

- (void) setCurrentTab: (NSString *)tabName;

- (void) openSite;

- (BOOL) dataLoadingComplete;

- (void) showLoadingView;

- (void) hideLoadingView;

@end

@interface StellarDetailViewControllerComponent : NSObject {
	StellarDetailViewController *viewController;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;
+ (StellarDetailViewControllerComponent *)viewController: (StellarDetailViewController *)controller;
@end

void makeCellWhite(UITableViewCell *cell);

@protocol StellarDetailTableViewDelegate <UITableViewDelegate, UITableViewDataSource>
- (CGFloat) heightOfTableView: (UITableView *)tableView;
@end
