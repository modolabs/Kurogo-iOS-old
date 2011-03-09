#import "SpringboardIcon.h"
#import "KGOHomeScreenViewController.h"
#import "KGOModule.h"

@implementation SpringboardIcon

@synthesize springboard, compact;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.compact;
    }
    return self;
}

- (KGOModule *)module {
    return _module;
}

- (void)setModule:(KGOModule *)aModule {
    [_module release];
    _module = [aModule retain];
    
    if (_module && self.springboard) {
        UIImage *image = [[self.module iconImage] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
        if (image) {
            
            [self setImage:image forState:UIControlStateNormal];
            
            self.titleLabel.numberOfLines = 0;
            self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
            self.titleLabel.textAlignment = UITextAlignmentCenter;
            
            // TODO: add config setting for icon titles to be displayed on springboard
            NSString *title = self.module.longName;
            [self setTitle:title forState:UIControlStateNormal];

            UIFont *titleFont;
            CGFloat titleImageGap;

            if (self.module.secondary) {
                self.titleLabel.textColor = [self.springboard secondaryModuleLabelTextColor];
                [self setTitleColor:[self.springboard secondaryModuleLabelTextColor] forState:UIControlStateNormal];
                titleFont = [self.springboard secondaryModuleLabelFont];
                titleImageGap = [self.springboard secondaryModuleLabelTitleMargin];
            } else {
                self.titleLabel.textColor = [self.springboard moduleLabelTextColor];
                [self setTitleColor:[self.springboard moduleLabelTextColor] forState:UIControlStateNormal];
                titleFont = self.compact ? [self.springboard moduleLabelFont] : [self.springboard moduleLabelFontLarge];
                titleImageGap = [self.springboard moduleLabelTitleMargin];
            }
            self.titleLabel.font = titleFont;

            // calculate title edge insets.
            
            if (self.compact) {
                // we want to top-align the label
                CGFloat extraLineHeight = 0;
                NSArray *words = [title componentsSeparatedByString:@" "];
                if (words.count > 1) {
                    extraLineHeight = (words.count - 1) * [titleFont lineHeight];
                }
                self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, self.frame.size.height - image.size.height, 0);
                self.titleEdgeInsets = UIEdgeInsetsMake(image.size.height + titleImageGap + extraLineHeight, // we want title below the image
                                                        -self.frame.size.width,                              // and not to the right
                                                        0, 0);
            } else {
                // we want to left-align the label and image
                CGSize titleSize = [title sizeWithFont:titleFont];
                CGFloat rightPadding = self.frame.size.width - image.size.width - titleSize.width;

                UIEdgeInsets insets = self.titleEdgeInsets;
                insets.right = rightPadding;
                self.titleEdgeInsets = insets;
                
                insets = self.imageEdgeInsets;
                insets.right = rightPadding;
                self.imageEdgeInsets = insets;
            }
            
            [self addTarget:self.springboard action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (NSString *)moduleTag {
    return self.module.tag;
}
    

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
