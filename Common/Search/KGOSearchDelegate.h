#import <UIKit/UIKit.h>


@protocol KGOSearchDelegate

- (void)searcher:(id)searcher didReceiveResults:(NSArray *)results;

@end
