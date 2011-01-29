#import <UIKit/UIKit.h>

/*
 * initialize these with UITableViewCellStyleDefault
 * and use secondaryTextLabel instead of detailTextLabel
 *
 */

static const CGFloat kUsualContentViewWidth = 270.0f;
static const CGFloat kStandardSecondaryGroupCellHeight = 44.0f;
static const CGFloat kUsualDetailTextHeight = 16.0f;
#define kSecondaryGroupMainFont [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
#define kSecondaryGroupDetailFont [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]

@interface SecondaryGroupedTableViewCell : UITableViewCell {

	UILabel *secondaryTextLabel;
}

+ (CGFloat)suggestedHeightForCellWithTextLabel:(UILabel *)aTextLabel andDetailTextLabel:(UILabel *)detailLabel;
+ (CGFloat)suggestedHeightForCellWithText:(NSString *)mainText mainFont:(UIFont *)mainFont
							   detailText:(NSString *)detailText detailFont:(UIFont *)detailFont;
+ (CGFloat)willFitOnOneLineInCell:(UILabel *)aTextLabel andDetailTextLabel:(UILabel *)detailLabel;
+ (CGFloat)willFitOnOneLineInCell:(NSString *)mainText mainFont:(UIFont *)mainFont
					   detailText:(NSString *)detailText detailFont:(UIFont *)detailFont;

@property (nonatomic, retain) UILabel *secondaryTextLabel;

@end
