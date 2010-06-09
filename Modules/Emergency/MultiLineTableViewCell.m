#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"
#define DEFAULT_TOP_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_BOTTOM_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_MAIN_FONT [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
#define DEFAULT_DETAIL_FONT [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]

@implementation MultiLineTableViewCell
@synthesize topPadding, bottomPadding;
@synthesize textLabelLineBreakMode, textLabelNumberOfLines, detailTextLabelLineBreakMode, detailTextLabelNumberOfLines;

- (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height {
    CGSize labelSize = [label.text sizeWithFont:label.font 
                              constrainedToSize:CGSizeMake(label.frame.size.width, 600.0) 
                                  lineBreakMode:UILineBreakModeWordWrap];
    
    if (label == self.textLabel && textLabelLineBreakMode == UILineBreakModeTailTruncation) {
        CGSize oneLineSize = [label.text sizeWithFont:label.font];
        labelSize.height = (labelSize.height > oneLineSize.height) ? oneLineSize.height * textLabelNumberOfLines : oneLineSize.height;
    } else if (label == self.detailTextLabel && detailTextLabelLineBreakMode == UILineBreakModeTailTruncation) {
        CGSize oneLineSize = [label.text sizeWithFont:label.font];
        labelSize.height = (labelSize.height > oneLineSize.height) ? oneLineSize.height * detailTextLabelNumberOfLines : oneLineSize.height;
    }
    
    label.frame = CGRectMake(label.frame.origin.x, topPadding + height, label.frame.size.width, labelSize.height);
}

- (void) layoutSubviews {
    
    CGFloat textWidth = self.textLabel.frame.size.width;
    CGFloat detailWidth = self.detailTextLabel.frame.size.width;
    
	[super layoutSubviews]; // this resizes labels to default size
    
    if (textWidth > 0) {
        CGRect frame = self.textLabel.frame;
        frame.size.width = textWidth;
        self.textLabel.frame = frame;
    }
    if (detailWidth > 0) {
        CGRect frame = self.detailTextLabel.frame;
        frame.size.width = detailWidth;
        self.detailTextLabel.frame = frame;
    }
    
    self.textLabel.lineBreakMode = textLabelLineBreakMode;
    self.textLabel.numberOfLines = textLabelNumberOfLines;
    
    self.detailTextLabel.lineBreakMode = detailTextLabelLineBreakMode;
    self.detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;

    if (textLabelNumberOfLines != 1) {
        [self layoutLabel:self.textLabel atHeight:0];
    }
    
    [self layoutLabel:self.detailTextLabel atHeight:self.textLabel.frame.size.height];

	// make sure any extra views are drawn on top of standard testLabel and detailTextLabel
	NSMutableArray *extraSubviews = [NSMutableArray arrayWithCapacity:[self.contentView.subviews count]];
	for (UIView *aView in self.contentView.subviews) {
		if (aView != self.textLabel && aView != self.detailTextLabel) {
			[extraSubviews addObject:aView];
			[aView removeFromSuperview];
		}
	}
	for (UIView *aView in extraSubviews) {
        // TODO: generalize this more if the following assumption no longer holds
        // right now we assume extra views are on the same line as the detailTextLabel
        // (true for stellar announcements and events calendar)
        CGRect frame = aView.frame;
        frame.origin.y = self.detailTextLabel.frame.origin.y;
        aView.frame = frame;
		[self.contentView addSubview:aView];
	}
}

- (id) initWithStyle: (UITableViewCellStyle)cellStyle reuseIdentifier: (NSString *)reuseIdentifier {
    if(self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier]) {		
		topPadding = DEFAULT_TOP_PADDING;
		bottomPadding = DEFAULT_BOTTOM_PADDING;
        
        textLabelLineBreakMode = UILineBreakModeWordWrap;
        textLabelNumberOfLines = 0;
        
        detailTextLabelLineBreakMode = UILineBreakModeWordWrap;
        detailTextLabelNumberOfLines = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

+ (CGFloat) widthAdjustmentForAccessoryType: (UITableViewCellAccessoryType)accessoryType isGrouped: (BOOL)isGrouped {
	
	CGFloat adjustment = 0;
	switch (accessoryType) {
		case UITableViewCellAccessoryNone:
			adjustment = 0;
			break;
		case UITableViewCellAccessoryDisclosureIndicator:
			adjustment = 20;
			break;
		case UITableViewCellAccessoryDetailDisclosureButton:
			adjustment = 33;
			break;
		case UITableViewCellAccessoryCheckmark:
			adjustment = 20;
			break;
	}
	
	if(isGrouped) {
		adjustment = adjustment + 21;
	}
	
	return adjustment;
}
	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main
							detail: (NSString *)detail
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped {
	
	return [self 
		cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main
							detail: (NSString *)detail 
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped
						topPadding: (CGFloat)topPadding {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:topPadding
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
							detail: (NSString *)detail 
				   widthAdjustment: (CGFloat)widthAdjustment {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:widthAdjustment
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail 
						detailFont: (UIFont *)detailFont
					accessoryType: (UITableViewCellAccessoryType)accessoryType 
						 isGrouped: (BOOL)isGrouped {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:mainFont
		detail:detail 
		detailFont:detailFont
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail 
						detailFont: (UIFont *)detailFont
				   widthAdjustment: (CGFloat)widthAdjustment 
						topPadding: (CGFloat)topPadding 
					 bottomPadding: (CGFloat)bottomPadding {
	
	CGFloat width = tableView.frame.size.width - widthAdjustment - 21.0;

	CGFloat mainHeight = [main 
		sizeWithFont:mainFont
		constrainedToSize:CGSizeMake(width, 600.0)         
		lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat detailHeight;
	if(detail) {
		detailHeight = [detail
			sizeWithFont:detailFont
			constrainedToSize:CGSizeMake(width, 600.0)         
			lineBreakMode:UILineBreakModeWordWrap].height;
	} else {
		detailHeight = 0;
	}

	return (mainHeight + detailHeight) + topPadding + bottomPadding;
}
@end

