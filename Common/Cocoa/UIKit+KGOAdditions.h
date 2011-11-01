#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KGOHTMLTemplate.h"

@interface UIImage (KGOAdditions)

+ (UIImage *)imageWithPathName:(NSString *)pathName;
+ (UIImage *)blankImageOfSize:(CGSize)size;

@end

@interface UIColor (KGOAdditions)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImageView (KGOAdditions)

- (void)showLoadingIndicator;
- (void)hideLoadingIndicator;

@end

@interface UIButton (KGOAdditions)

+ (UIButton *)genericButtonWithTitle:(NSString *)title;
+ (UIButton *)genericButtonWithImage:(UIImage *)image;

@end

@interface UITableViewCell (KGOAdditions)

- (void)applyBackgroundThemeColorForIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end

@interface UIWebView (KGOAdditions)

- (void)loadTemplate:(KGOHTMLTemplate *)template values:(NSDictionary *)values;

@end

@interface UITableView (KGOAdditions)

- (CGFloat)marginWidth;

@end

