#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor (KGOAdditions)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImageView (KGOAdditions)

- (void)showLoadingIndicator;
- (void)hideLoadingIndicator;

@end

@interface UILabel (KGOAdditions)

+ (UILabel *)multilineLabelWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width;

@end

