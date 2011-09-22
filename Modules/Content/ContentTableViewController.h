#import <UIKit/UIKit.h>
#import "KGORequestManager.h"


@interface ContentTableViewController : UIViewController <KGORequestDelegate,
UITableViewDataSource, UITableViewDelegate> {
	
    NSMutableDictionary * listOfFeeds;
    NSMutableArray * feedKeys;
    UIView * loadingView;

    NSString * moduleTag;
    
}

@property (nonatomic, retain) NSMutableDictionary *listOfFeeds;
@property (nonatomic, retain) NSMutableArray *feedKeys;

@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) UIView *loadingView;

@property (nonatomic, retain) NSString *feedKey;
@property (nonatomic, retain) KGORequest *request;

// if there are multiple feeds, show a list
@property (nonatomic, retain) UITableView *tableView;

// if there's only one feed, show it directly
@property (nonatomic, retain) UIWebView *contentView;
@property (nonatomic, retain) NSString *contentTitle;

- (void)addLoadingView;
- (void)removeLoadingView;

- (void)requestPageContent;

@end

