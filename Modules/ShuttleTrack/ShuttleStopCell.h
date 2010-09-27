
#import <UIKit/UIKit.h>
@class ShuttleStop;

@interface ShuttleStopCell : UITableViewCell 
{
	IBOutlet UIImageView* _shuttleStopImageView;
	IBOutlet UILabel* _shuttleNameLabel;
	IBOutlet UILabel* _shuttleTimeLabel;
	IBOutlet UILabel* _shuttleNextLabel;
	
	NSString *urlForImage;
}

@property (nonatomic, retain) NSString *urlForImage;

-(void) setShuttleInfo:(ShuttleStop*)shuttleStop urlLinkForImage:(UIImage *)urlLinkForImage;

@end
