//
//  VideoListViewController.h
//  Universitas
//

#import <Foundation/Foundation.h>
#import "KGOTableViewController.h"
#import "VideoDataManager.h"
#import "KGOScrollingTabstrip.h"
#import "MITThumbnailView.h"

@interface VideoListViewController : UITableViewController <MITThumbnailDelegate,
KGOScrollingTabstripDelegate> {

}

@property (nonatomic, retain) VideoDataManager *dataManager;
@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) KGOScrollingTabstrip *navScrollView;
@property (nonatomic, retain) NSArray *videos;
// Array of NSDictionaries containing title and value keys.
@property (nonatomic, retain) NSArray *videoSections;
@property (assign) NSInteger activeSectionIndex;

@end
