#import <UIKit/UIKit.h>


@interface DiningMultiLineCell : UITableViewCell {
    UITableViewCellStyle _style;
    NSInteger textLabelNumberOfLines;
    NSInteger detailTextLabelNumberOfLines;
}

@property NSInteger textLabelNumberOfLines;
@property NSInteger detailTextLabelNumberOfLines;

+ (CGFloat)widthForTextLabel:(BOOL)isPrimary
                   cellStyle:(UITableViewCellStyle)style
                   tableView:(UITableView *)tableView 
               accessoryType:(UITableViewCellAccessoryType)accessoryType
                   cellImage:(BOOL)cellImage;

+ (CGFloat)heightForCellWithStyle:(UITableViewCellStyle)style
                        tableView:(UITableView *)tableView 
                             text:(NSString *)text
                     maxTextLines:(NSInteger)maxTextLines
                       detailText:(NSString *)detailText
                   maxDetailLines:(NSInteger)maxDetailLines
                             font:(UIFont *)font 
                       detailFont:(UIFont *)detailFont 
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
                        cellImage:(BOOL)cellImage;

@end

