#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"

@class KGOSearchBar;

@interface PeopleSearchViewController : KGOTableViewController <//JSONAPIDelegate,
UIActionSheetDelegate, KGOSearchDisplayDelegate> {
	
    KGOSearchDisplayController *searchController;
	NSString *searchTerms;
	NSArray *searchTokens;
    KGOSearchBar *theSearchBar;

    NSArray *phoneDirectoryEntries;
    // uncomment this after we have API for directory numbers
	//JSONAPIRequest *api;
    
	UIView *recentlyViewedHeader;
}

- (void)showActionSheet:(id)sender;

@property (nonatomic, retain) KGOSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) KGOSearchBar *searchBar;

@end
