#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"

#define SECONDARY_GROUP_VIEW_TAG 999

@implementation SecondaryGroupedTableViewCell

@synthesize secondaryTextLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		secondaryTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// remove nonstandard views previously rendered
	UIView *extra = [self.contentView viewWithTag:SECONDARY_GROUP_VIEW_TAG];
	[extra removeFromSuperview];
	
	self.backgroundColor = SECONDARY_GROUP_BACKGROUND_COLOR;
	
	self.textLabel.font = kSecondaryGroupMainFont;
	self.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
	self.textLabel.backgroundColor = [UIColor clearColor];
	
	if (self.secondaryTextLabel.text != nil) {
		self.secondaryTextLabel.font = kSecondaryGroupDetailFont;
		self.secondaryTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
        self.secondaryTextLabel.highlightedTextColor = [UIColor whiteColor];
		self.secondaryTextLabel.backgroundColor = [UIColor clearColor];		
		self.secondaryTextLabel.tag = SECONDARY_GROUP_VIEW_TAG;
		
		CGSize textSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
		CGSize detailTextSize = [self.secondaryTextLabel.text sizeWithFont:self.secondaryTextLabel.font];
		
		CGFloat detailTextLabelX = textSize.width + self.textLabel.frame.origin.x + 4.0;
		CGFloat detailTextLabelY = self.textLabel.frame.origin.y;
		
		if (![SecondaryGroupedTableViewCell willFitOnOneLineInCell:self.textLabel 
											   andDetailTextLabel:self.secondaryTextLabel]) {
			// The main text and the detail text are too wide to fit in the cell, so the detail text 
			// label is going to go to the next line.
			CGRect mainTextFrame = 	self.textLabel.frame;
			// TODO: Explain why this has to be a negative value.
			mainTextFrame.origin.y = - (self.contentView.frame.size.height - textSize.height - detailTextSize.height)/2;
			self.textLabel.frame = mainTextFrame;
			
			detailTextLabelX = self.textLabel.frame.origin.x;
			detailTextLabelY = self.textLabel.frame.origin.y + textSize.height;
			// tableView:heightForRowAtIndexPath: should return a different height for this row by using suggestedHeightForCellWithText:...
		}
		
		self.secondaryTextLabel.frame = CGRectMake(detailTextLabelX, 
												   detailTextLabelY,
												   detailTextSize.width, 
												   self.textLabel.frame.size.height);
		[self.contentView addSubview:self.secondaryTextLabel];
	}
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
	[secondaryTextLabel release];
    [super dealloc];
}

+ (CGFloat)suggestedHeightForCellWithTextLabel:(UILabel *)aTextLabel andDetailTextLabel:(UILabel *)detailLabel {

	if ([SecondaryGroupedTableViewCell willFitOnOneLineInCell:aTextLabel andDetailTextLabel:detailLabel]) {
		return kStandardSecondaryGroupCellHeight;
	}
	else {
		CGSize detailTextSize = [detailLabel.text sizeWithFont:detailLabel.font];
		return kStandardSecondaryGroupCellHeight + detailTextSize.height;
	}
}

+ (CGFloat)suggestedHeightForCellWithText:(NSString *)mainText mainFont:(UIFont *)mainFont
							   detailText:(NSString *)detailText detailFont:(UIFont *)detailFont {
	
	if ([SecondaryGroupedTableViewCell willFitOnOneLineInCell:mainText
													 mainFont:mainFont
												   detailText:detailText
												   detailFont:detailFont]) {
		return kStandardSecondaryGroupCellHeight;
	}
	else {
		return kStandardSecondaryGroupCellHeight + kUsualDetailTextHeight;
	}
}

+ (CGFloat)willFitOnOneLineInCell:(UILabel *)aTextLabel andDetailTextLabel:(UILabel *)detailLabel {
	
	return [SecondaryGroupedTableViewCell willFitOnOneLineInCell:aTextLabel.text
														mainFont:aTextLabel.font
													  detailText:detailLabel.text
													  detailFont:detailLabel.font];
}	

+ (CGFloat)willFitOnOneLineInCell:(NSString *)mainText mainFont:(UIFont *)mainFont
					   detailText:(NSString *)detailText detailFont:(UIFont *)detailFont {
	
	CGSize textSize = [mainText sizeWithFont:mainFont];
	CGSize detailTextSize = [detailText sizeWithFont:detailFont];
	
	return (textSize.width + detailTextSize.width < kUsualContentViewWidth);
}	

@end
