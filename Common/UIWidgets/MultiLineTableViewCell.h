#import <UIKit/UIKit.h>


@interface MultiLineTableViewCell : UITableViewCell {
    UITableViewCellStyle _style;
    NSInteger textLabelNumberOfLines;
    NSInteger detailTextLabelNumberOfLines;
    BOOL _hasIndex;
}

@property NSInteger textLabelNumberOfLines;
@property NSInteger detailTextLabelNumberOfLines;
@property BOOL hasIndex;

+ (CGFloat)widthForTextLabel:(BOOL)isPrimary
                   cellStyle:(UITableViewCellStyle)style
                   tableView:(UITableView *)tableView 
               accessoryType:(UITableViewCellAccessoryType)accessoryType
                   cellImage:(BOOL)cellImage
                    hasIndex:(BOOL)hadIndex;

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

+ (CGFloat)heightForCellWithStyle:(UITableViewCellStyle)style
                        tableView:(UITableView *)tableView 
                             text:(NSString *)text
                     maxTextLines:(NSInteger)maxTextLines
                       detailText:(NSString *)detailText
                   maxDetailLines:(NSInteger)maxDetailLines
                             font:(UIFont *)font 
                       detailFont:(UIFont *)detailFont 
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
                        cellImage:(BOOL)cellImage
						 hasIndex:(BOOL)indexPane;

@end

