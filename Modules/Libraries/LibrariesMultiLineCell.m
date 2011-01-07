/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "LibrariesMultiLineCell.h"
#import "MITUIConstants.h"

#define CELL_IMAGE_WIDTH 33.0

@implementation LibrariesMultiLineCell
@synthesize textLabelNumberOfLines, detailTextLabelNumberOfLines;

+ (CGFloat)widthForTextLabel:(BOOL)isTextLabel
                   cellStyle:(UITableViewCellStyle)style
                   tableView:(UITableView *)tableView
               accessoryType:(UITableViewCellAccessoryType)accessoryType
                   cellImage:(BOOL)cellImage
{
    CGFloat width = tableView.frame.size.width;
    if (tableView.style == UITableViewStyleGrouped) width -= 20.0; // 10px margin either side of table
	
    width -= 20.0; // 10px padding either side within cell
	
    switch (style) {
        case UITableViewCellStyleValue2:
        {
			if (isTextLabel) {
                width = floor(width * 0.24);
                if (cellImage) width -= CELL_IMAGE_WIDTH;
            } else {
				width = floor(width * 0.76);
				if (cellImage) width -= CELL_IMAGE_WIDTH;
                
                switch (accessoryType) {
                    case UITableViewCellAccessoryCheckmark:
                    case UITableViewCellAccessoryDetailDisclosureButton:
                        width -= 21.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
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
                        width -= 21.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
            } else {
                if (cellImage) width -= CELL_IMAGE_WIDTH;
            }
            break;
        }
        default:
        {
            if (cellImage) width -= CELL_IMAGE_WIDTH;
            
            switch (accessoryType) {
                case UITableViewCellAccessoryCheckmark:
                case UITableViewCellAccessoryDetailDisclosureButton:
                    width -= 21.0;
                    break;
                case UITableViewCellAccessoryDisclosureIndicator:
                    width -= 15.0;
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
        CGSize size = CGSizeMake(width, height * maxLines * 1.1);
        height = [text sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap].height;
    }
    //DLog(@"height for label with text %@ and width %.1f is %.1f", text, width, height);
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
    CGFloat textWidth = [LibrariesMultiLineCell widthForTextLabel:YES cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
    CGFloat detailTextWidth = [LibrariesMultiLineCell widthForTextLabel:NO cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
	
    if (font == nil) font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGFloat textHeight = [LibrariesMultiLineCell heightForLabelWithText:text font:font width:textWidth maxLines:maxTextLines];
	
    CGFloat detailTextHeight = 0.0;
    if (detailText) {
        if (detailFont == nil) detailFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        detailTextHeight = [LibrariesMultiLineCell heightForLabelWithText:detailText font:detailFont width:detailTextWidth maxLines:maxDetailLines];
    }
    
    CGFloat result;
    if (style == UITableViewCellStyleValue1 || style == UITableViewCellStyleValue2) {
        result = (textHeight > detailTextHeight ? textHeight : detailTextHeight) + 20.0;
    } else {
        result = textHeight + detailTextHeight + 20.0;
    }
    
    return result;
}

- (void)layoutSubviews {
	[super layoutSubviews]; // this resizes labels to default size
    
    CGFloat heightAdded = 0.0;
    UITableView *tableView = (UITableView *)self.superview;
    if (!tableView) return;
    
    BOOL cellImage = (self.imageView.image != nil);
    CGRect frame;
    
    UITableViewCellAccessoryType accessoryType = self.accessoryType;
    if (accessoryType == UITableViewCellAccessoryNone && self.accessoryView != nil) {
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    if (textLabelNumberOfLines != 1) {
        self.textLabel.numberOfLines = textLabelNumberOfLines;
        self.textLabel.lineBreakMode = textLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        frame = self.textLabel.frame;
		frame.origin.x = 10.0;
        if (frame.origin.y <= 0.0) {
            // TODO: find out why this happens
            heightAdded += 10.0 - frame.origin.y;
            frame.origin.y = 10.0;
        }
		
        frame.size.width = [LibrariesMultiLineCell widthForTextLabel:YES cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
        frame.size.height = [LibrariesMultiLineCell heightForLabelWithText:self.textLabel.text
                                                                      font:self.textLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.textLabel.numberOfLines];
        heightAdded += frame.size.height - self.textLabel.frame.size.height;
        self.textLabel.frame = frame;
    }
    
    if (self.detailTextLabel.text && detailTextLabelNumberOfLines != 1) {
        
        self.detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;
        self.detailTextLabel.lineBreakMode = detailTextLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        frame = self.detailTextLabel.frame;
        if (_style == UITableViewCellStyleSubtitle)
            frame.origin.y += heightAdded;
        frame.size.width = [LibrariesMultiLineCell widthForTextLabel:NO cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage];
        frame.size.height = [LibrariesMultiLineCell heightForLabelWithText:self.detailTextLabel.text
                                                                      font:self.detailTextLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.detailTextLabel.numberOfLines];
        self.detailTextLabel.frame = frame;
        
        // for cells with detail text only...
        // if the OS is more aggressive with accessory sizes,
        // it will make the text narrower and taller
        // than we make it, and recenter the labels within the cell.
        // so we re-recenter the frame based on its actual size
        CGFloat innerHeight = self.detailTextLabel.frame.origin.y - self.textLabel.frame.origin.y + self.detailTextLabel.frame.size.height;

        frame = self.textLabel.frame;
        frame.origin.y = floor((self.frame.size.height - innerHeight) / 2);
        heightAdded = frame.origin.y - self.textLabel.frame.origin.y;
        self.textLabel.frame = frame;
        //if (heightAdded > 0) {
            frame = self.detailTextLabel.frame;
            frame.origin.y += heightAdded;
            self.detailTextLabel.frame = frame;
        //}
    }
    
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
        // right now we assume extra views are on the same line as the textLabel
        // (true for stellar announcements and events calendar)
        CGRect frame = aView.frame;
        frame.origin.y = self.detailTextLabel.frame.origin.y;
		
		// Position of the Status Icon next to the textLabel
		if (frame.origin.x < self.textLabel.frame.origin.x)
			frame.origin.x = self.textLabel.frame.origin.x - 30;
		
        aView.frame = frame;
		[self.contentView addSubview:aView];
	}
	
}

- (id) initWithStyle: (UITableViewCellStyle)cellStyle reuseIdentifier: (NSString *)reuseIdentifier {
    if(self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier]) {		
        _style = cellStyle;
        textLabelNumberOfLines = 0;
        detailTextLabelNumberOfLines = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


@end

