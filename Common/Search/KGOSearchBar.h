/*
 * this class is an improved version of ModoSearchBar from Harvard.
 */

#import <UIKit/UIKit.h>


@interface KGOSearchBar : UISearchBar {
    
    UIView *backgroundView;
    UIView *dropShadow;

}

@property (nonatomic, retain) UIImage *backgroundImage;
@property (nonatomic, retain) UIImage *dropShadowImage;

@end
