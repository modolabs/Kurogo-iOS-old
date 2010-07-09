#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "MITSearchEffects.h"

NSInteger strLenSort(NSString *str1, NSString *str2, void *context);

@interface PeopleSearchViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, JSONAPIDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
	
	UISearchDisplayController *searchController;
	NSArray *searchResults;
	NSString *searchTerms;
	NSArray *searchTokens;
	UIView *loadingView;
	MITSearchEffects *searchBackground;
	UISearchBar *theSearchBar;
	BOOL requestWasDispatched;
	JSONAPIRequest *api;
	UIView *recentlyViewedHeader;
	SEL actionAfterAppearing;
	BOOL viewAppeared;
}

- (void)prepSearchBar;
- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)searchOverlayTapped;
- (void)performSearch;
- (void)showLoadingView;
- (void)cleanUpConnection;
- (void)phoneIconTapped;
- (void)showActionSheet;

@property (nonatomic, readonly) BOOL viewAppeared;
@property (nonatomic, assign) SEL actionAfterAppearing;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) MITSearchEffects *searchBackground;

@end
