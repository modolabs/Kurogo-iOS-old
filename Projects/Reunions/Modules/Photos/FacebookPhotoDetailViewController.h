#import <UIKit/UIKit.h>
#import "FacebookModel.h"
#import "KGODetailPager.h"
#import "MITThumbnailView.h"
#import "FacebookCommentViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@interface FacebookPhotoDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
KGODetailPagerController, KGODetailPagerDelegate, FacebookUploadDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UIBarButtonItem *_commentButton;
    IBOutlet UIBarButtonItem *_likeButton;
    IBOutlet UIBarButtonItem *_bookmarkButton;
    
    MITThumbnailView *_thumbnail;
    NSArray *_comments;
}

@property(nonatomic, retain) NSArray *photos;
@property(nonatomic, retain) FacebookPhoto *photo;

- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)likeButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)bookmarkButtonPressed:(UIBarButtonItem *)sender;

- (void)displayPhoto;
- (void)didReceiveComments:(id)result;

- (void)didLikePhoto:(id)result;
- (void)didUnlikePhoto:(id)result;

@end
