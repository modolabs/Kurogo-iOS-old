#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"
#define DEFAULT_MAIN_FONT [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
#define DEFAULT_DETAIL_FONT [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]

@implementation MultiLineTableViewCell
//@synthesize topPadding, bottomPadding;
@synthesize textLabelLineBreakMode, textLabelNumberOfLines, detailTextLabelLineBreakMode, detailTextLabelNumberOfLines;

/*
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
*/

+ (CGFloat)widthForTextLabel:(BOOL)isTextLabel
                   cellStyle:(UITableViewCellStyle)style
                   tableView:(UITableView *)tableView 
               accessoryType:(UITableViewCellAccessoryType)accessoryType
                   cellImage:(BOOL)cellImage
{
    CGFloat width = tableView.frame.size.width - 20.0; // 10px padding either side within cell
    if (tableView.style == UITableViewStyleGrouped) width -= 20.0; // 10px margin either side of table

    switch (style) {
        case UITableViewCellStyleValue2:
        {
            width -= 10.0; // 10px spacing between text and detailText
            if (isTextLabel) {
                width = floor(width * 0.76);
                switch (accessoryType) {
                    case UITableViewCellAccessoryCheckmark:
                    case UITableViewCellAccessoryDetailDisclosureButton:
                        width -= 10.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
            } else {
                width = floor(width * 0.24);
                if (cellImage) width -= 33.0;
            }
            break;
        }
        case UITableViewCellStyleValue1: // please please just don't make multiline cells with this style
        {
            width -= 10.0; // 10px spacing between text and detailText
            width = floor(width * 0.5);
            if (isTextLabel) {
                switch (accessoryType) {
                    case UITableViewCellAccessoryCheckmark:
                    case UITableViewCellAccessoryDetailDisclosureButton:
                        width -= 10.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
            } else {
                if (cellImage) width -= 33.0;
            }
            break;
        }
        default:
        {
            if (cellImage) width -= 33.0;
            
            switch (accessoryType) {
                case UITableViewCellAccessoryCheckmark:
                case UITableViewCellAccessoryDetailDisclosureButton:
                    width -= 21.0;
                    break;
                case UITableViewCellAccessoryDisclosureIndicator:
                    width -= 33.0;
                    break;
            }
            
            break;
        }
    }
    return width;
}

+ (CGFloat)heightForLabelWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width maxLines:(NSInteger)maxLines
{
    CGFloat height;
    if (maxLines == 0) {
        CGSize size = CGSizeMake(width, 2000.0);
        height = [text sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap].height;
    } else if (maxLines == 1) {
        height = [text sizeWithFont:font].height;
    } else {
        height = [text sizeWithFont:font].height;
        CGSize size = CGSizeMake(width, height * maxLines);
        height = [text sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap].height;
    }
    return height;
}

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
{
    CGFloat textWidth = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
    CGFloat detailTextWidth = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage];

    if (font == nil) font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGFloat textHeight = [MultiLineTableViewCell heightForLabelWithText:text font:font width:textWidth maxLines:maxTextLines];

    CGFloat detailTextHeight = 0.0;
    if (detailText) {
        if (detailFont == nil) detailFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        detailTextHeight = [MultiLineTableViewCell heightForLabelWithText:detailText font:detailFont width:detailTextWidth maxLines:maxDetailLines];
    }

    NSLog(@"text width: %.1f, height: %.1f; detail width: %.1f, height: %.1f", textWidth, textHeight, detailTextWidth, detailTextHeight);
    
    if (style == UITableViewCellStyleValue1 || style == UITableViewCellStyleValue2) {
        return (textHeight > detailTextHeight ? textHeight : detailTextHeight) + 20.0;
    } else {
        return textHeight + detailTextHeight + 20.0;
    }
}

- (void)layoutSubviews {    
	[super layoutSubviews]; // this resizes labels to default size

    CGFloat heightAdded;
    UITableView *tableView = (UITableView *)self.superview;
    BOOL cellImage = (self.imageView.image != nil);
    
    UITableViewCellAccessoryType accessoryType = self.accessoryType;
    if (accessoryType == UITableViewCellAccessoryNone && self.accessoryView != nil) {
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    if (textLabelNumberOfLines != 1) {
        self.textLabel.numberOfLines = textLabelNumberOfLines;
        self.textLabel.lineBreakMode = textLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        CGRect frame = self.textLabel.frame;
        frame.size.width = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
        frame.size.height = [MultiLineTableViewCell heightForLabelWithText:self.textLabel.text
                                                                      font:self.textLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.textLabel.numberOfLines];
        heightAdded = frame.size.height - self.textLabel.frame.size.height;
        self.textLabel.frame = frame;
    }
    
    if (self.detailTextLabel.text && detailTextLabelNumberOfLines != 1) {
        self.detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;
        self.detailTextLabel.lineBreakMode = detailTextLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        CGRect frame = self.detailTextLabel.frame;
        frame.origin.y += heightAdded;
        frame.size.width = [MultiLineTableViewCell widthForTextLabel:NO cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
        frame.size.height = [MultiLineTableViewCell heightForLabelWithText:self.detailTextLabel.text
                                                                      font:self.detailTextLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.detailTextLabel.numberOfLines];
        self.detailTextLabel.frame = frame;
    }
    
    NSLog(@"laying out text origin: %.1f width: %.1f, height: %.1f; detail width: %.1f, height: %.1f",
          self.textLabel.frame.origin.y,
          self.textLabel.frame.size.width,
          self.textLabel.frame.size.height,
          self.detailTextLabel.frame.size.width,
          self.detailTextLabel.frame.size.height);

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
		//topPadding = CELL_VERTICAL_PADDING;
		//bottomPadding = CELL_VERTICAL_PADDING;
        _style = cellStyle;
        
        //textLabelLineBreakMode = UILineBreakModeWordWrap;
        textLabelNumberOfLines = 0;
        
        //detailTextLabelLineBreakMode = UILineBreakModeWordWrap;
        detailTextLabelNumberOfLines = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}
/*
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
		topPadding:CELL_VERTICAL_PADDING
		bottomPadding:CELL_VERTICAL_PADDING];
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
		bottomPadding:CELL_VERTICAL_PADDING];
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
		topPadding:CELL_VERTICAL_PADDING
		bottomPadding:CELL_VERTICAL_PADDING];
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
		topPadding:CELL_VERTICAL_PADDING
		bottomPadding:CELL_VERTICAL_PADDING];
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
*/

@end

