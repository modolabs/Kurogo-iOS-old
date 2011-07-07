#import "KGOLabel.h"


@implementation KGOLabel

+ (KGOLabel *)multilineLabelWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width {
	CGSize labelSize = [text sizeWithFont:font
                        constrainedToSize:CGSizeMake(width, 1000)
                            lineBreakMode:UILineBreakModeWordWrap];
    KGOLabel *label = [[[KGOLabel alloc] initWithFrame:CGRectMake(0, 0, width, labelSize.height)] autorelease];
    label.text = text;
    label.font = font;
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.backgroundColor = [UIColor clearColor];
    
    return label;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect
{
    CGSize size = [self.text sizeWithFont:self.font constrainedToSize:rect.size lineBreakMode:self.lineBreakMode];
    if (size.height < rect.size.height) {
        rect.size = size;
    }
    if (size.width < self.frame.size.width) {
        CGFloat xOriginOffset = 0;
        switch (self.textAlignment) {
            case UITextAlignmentLeft:
                xOriginOffset = 0;
                break;
                
            case UITextAlignmentCenter:
                xOriginOffset = (self.frame.size.width - size.width) / 2;
                break;
                
            case UITextAlignmentRight:
                xOriginOffset = self.frame.size.width - size.width;
                break;
        }
        rect.origin.x += xOriginOffset;
    }
    [super drawTextInRect:rect];
}

- (void)dealloc
{
    [super dealloc];
}

@end
