#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"
#import "KGODetailPager.h"

@class KGOSearchBar;

@interface PeopleSearchViewController : KGOTableViewController <
UIActionSheetDelegate, KGOSearchDisplayDelegate, KGODetailPagerController> {
	
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

@end
