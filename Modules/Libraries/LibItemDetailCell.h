//
//  LibItemDetailCell.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/23/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LibItemDetailCell : UITableViewCell {

    UITableViewCellStyle _style;
    NSInteger textLabelNumberOfLines;
    NSInteger detailTextLabelNumberOfLines;
	
	
	NSDictionary *itemAvailabilityStringAndStatus;
}

@property NSInteger textLabelNumberOfLines;
@property NSInteger detailTextLabelNumberOfLines;

-(id) initWithStyle:(UITableViewCellStyle)cellStyle 
	reuseIdentifier:(NSString *)reuseIdentifier 
	itemAvailability: (NSDictionary *) availabilityStringAndStatus;


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
                        cellImage:(BOOL)cellImage
	   itemAvailabilityDictionary:(NSDictionary *)itemAvailabilityDictionary;

@end
