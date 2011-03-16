#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import "MITThumbnailView.h"
#import "FacebookCommentViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@class FacebookParentPost;

@interface FacebookMediaDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
KGODetailPagerController, KGODetailPagerDelegate, FacebookUploadDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UIBarButtonItem *_commentButton;
    IBOutlet UIBarButtonItem *_likeButton;
    IBOutlet UIBarButtonItem *_bookmarkButton;
    
    NSArray *_comments;
}

@property(nonatomic, retain) NSArray *posts;
@property(nonatomic, retain) FacebookParentPost *post;
@property(nonatomic, retain) UITableView *tableView;

- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)likeButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)bookmarkButtonPressed:(UIBarButtonItem *)sender;

- (void)displayPost;

- (void)getCommentsForPost;
- (void)didReceiveComments:(id)result;

- (void)didLikePost:(id)result;
- (void)didUnlikePost:(id)result;

@end
