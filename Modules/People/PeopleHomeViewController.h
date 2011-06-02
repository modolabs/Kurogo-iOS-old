#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"
#import "KGODetailPager.h"
#import "KGORequestManager.h"

@class KGOSearchBar, PeopleModule;

@interface PeopleHomeViewController : KGOTableViewController <
KGORequestDelegate, // TODO: separate this from view logic
UIActionSheetDelegate, KGOSearchDisplayDelegate, KGODetailPagerController> {
    
    KGORequest *_request;
	
    KGOSearchDisplayController *_searchController;
	NSString *_searchTerms;
	NSArray *_searchTokens;
    KGOSearchBar *_searchBar;
    NSArray *_recentlyViewed;

    NSArray *_phoneDirectoryEntries;
}

@property (nonatomic, retain) KGOSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) KGOSearchBar *searchBar;

@property (nonatomic, assign) PeopleModule *module;

@end
