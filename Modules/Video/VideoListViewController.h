//
//  VideoListViewController.h
//  Universitas
//

#import <Foundation/Foundation.h>
#import "KGOTableViewController.h"
#import "VideoDataManager.h"
#import "KGOScrollingTabstrip.h"

@interface VideoListViewController : UITableViewController {

}

@property (nonatomic, retain) VideoDataManager *dataManager;
@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) KGOScrollingTabstrip *navScrollView;
@property (nonatomic, retain) NSArray *videos;
// Array of NSDictionaries containing title and value keys.
@property (nonatomic, retain) NSArray *videoSections;
@property (assign) NSInteger activeSectionIndex;
// Key: url string. Value: UIImage.
@property (nonatomic, retain) NSMutableDictionary *thumbnailCache;

@end
