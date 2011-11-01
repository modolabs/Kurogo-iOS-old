#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"

@class KGOLabel, NewsStory;

@interface NewsStoryTableViewCell : UITableViewCell <MITThumbnailDelegate> {
    
    IBOutlet KGOLabel *_titleLabel;
    IBOutlet KGOLabel *_dekLabel;
    IBOutlet MITThumbnailView *_thumbnailView;
    NewsStory *_story;
}

@property (nonatomic, retain) NewsStory *story;

- (void)configureLabelsTheme;

+ (NSString *)commonReuseIdentifier;

@end
