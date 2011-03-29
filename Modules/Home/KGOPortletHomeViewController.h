#import <UIKit/UIKit.h>
#import "KGOHomeScreenViewController.h"

@class IconGrid;

@interface KGOPortletHomeViewController : KGOHomeScreenViewController {
    
    NSArray *_visibleWidgets;
    IconGrid *_iconGrid;

    CGFloat _topFreePixel;
    CGFloat _bottomFreePixel;
}

@end
