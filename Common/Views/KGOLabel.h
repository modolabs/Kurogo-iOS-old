#import <UIKit/UIKit.h>

// this is a trivial subclass of UILabel that draws text top aligned.
// TODO: create arguments for top, center, and bottom alignment

@interface KGOLabel : UILabel {
    
}

+ (KGOLabel *)multilineLabelWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width;

@end
