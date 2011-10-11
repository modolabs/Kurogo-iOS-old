#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"
#import "KGODetailPager.h"
#import "KGORequestManager.h"
#import "PeopleDataManager.h"

@class KGOSearchBar, PeopleModule;

@interface PeopleHomeViewController : KGOTableViewController <
UIActionSheetDelegate, KGOSearchDisplayDelegate, KGODetailPagerController,
PeopleDataDelegate> {
    
    KGOSearchDisplayController *_searchController;
	NSString *_searchTerms;
	NSArray *_searchTokens;
    KGOSearchBar *_searchBar;
    NSArray *_recentlyViewed;

    NSArray *_phoneDirectoryEntries;
}

@property (nonatomic, retain) KGOSearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) KGOSearchBar *searchBar;

@property (nonatomic, retain) NSString *federatedSearchTerms;
@property (nonatomic, retain) NSArray *federatedSearchResults;

@property (nonatomic, assign) PeopleModule *module; 
@property (nonatomic, retain) PeopleDataManager *dataManager;

@end
