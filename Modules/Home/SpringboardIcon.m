#import "SpringboardIcon.h"
#import "KGOHomeScreenViewController.h"
#import "KGOModule.h"

@implementation SpringboardIcon

@synthesize springboard, compact;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.compact = YES;
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
            CGSize imageSize;

            if (self.module.secondary) {
                self.titleLabel.textColor = [self.springboard secondaryModuleLabelTextColor];
                [self setTitleColor:[self.springboard secondaryModuleLabelTextColor] forState:UIControlStateNormal];
                titleFont = [self.springboard secondaryModuleLabelFont];
                titleImageGap = [self.springboard secondaryModuleLabelTitleMargin];
                imageSize = [self.springboard secondaryModuleIconSize];
            } else {
                self.titleLabel.textColor = [self.springboard moduleLabelTextColor];
                [self setTitleColor:[self.springboard moduleLabelTextColor] forState:UIControlStateNormal];
                titleFont = self.compact ? [self.springboard moduleLabelFont] : [self.springboard moduleLabelFontLarge];
                titleImageGap = [self.springboard moduleLabelTitleMargin];
                imageSize = [self.springboard moduleIconSize];
            }
            self.titleLabel.font = titleFont;

            // calculate title edge insets.
            if (!imageSize.width || !imageSize.height) {
                imageSize = image.size;
            }
            
            if (self.compact) {
                // we want to top-align the label
                CGFloat extraLineHeight = 0;
                NSArray *words = [title componentsSeparatedByString:@" "];
                if (words.count > 1) {
                    extraLineHeight = (words.count - 1) * [titleFont lineHeight];
                }
                CGFloat sideInsets = floor((self.frame.size.width - imageSize.width) / 2);
                self.imageEdgeInsets = UIEdgeInsetsMake(0, sideInsets, self.frame.size.height - imageSize.height, sideInsets);
                self.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height + titleImageGap + extraLineHeight, // want title below image
                                                        -self.frame.size.width,                             // and not to the right
                                                        0, 0);
            } else {
                // we want to left-align the label and image
                CGSize titleSize = [title sizeWithFont:titleFont];
                CGFloat rightPadding = self.frame.size.width - imageSize.width - titleSize.width;

                // TODO: account for user-set icon dimensions
                UIEdgeInsets insets = self.titleEdgeInsets;
                insets.right = rightPadding;
                self.titleEdgeInsets = insets;
                
                insets = self.imageEdgeInsets;
                insets.right = rightPadding;
                self.imageEdgeInsets = insets;
            }
            
            [self addTarget:self.springboard action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

        }
#ifdef DEBUG
        else {
            NSString *message = [NSString stringWithFormat:@"missing image: %@ not found", [self.module iconImage]];
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"debug warning"
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles: nil] autorelease];
            [alertView show];
        }
#endif
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
