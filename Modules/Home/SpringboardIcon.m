#import "SpringboardIcon.h"
#import "KGOHomeScreenViewController.h"
#import "KGOModule.h"
#import "UIKit+KGOAdditions.h"

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
        UIImage *image = [self.module iconImage];
        if (!image) {
            image = [UIImage blankImageOfSize:self.frame.size];
        }
        
        if (image) {
            [self setImage:image forState:UIControlStateNormal];
            
            // TODO: add config setting for icon titles to be displayed on springboard
            NSString *title = self.module.longName;
            [self setTitle:title forState:UIControlStateNormal];
            
            if (self.module.secondary) {
                [self setTitleColor:[self.springboard secondaryModuleLabelTextColor] forState:UIControlStateNormal];
            } else {
                [self setTitleColor:[self.springboard moduleLabelTextColor] forState:UIControlStateNormal];
            }
            [self addTarget:self.springboard action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

// need to recalculate titleEdgeInsets and imageEdgeInsets when title font changes.
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSString *title = [self titleForState:UIControlStateNormal];
    UIImage *image = [self imageForState:UIControlStateNormal];
    CGSize imageSize = CGSizeZero;
    CGFloat titleImageGap = 0;
    
    UILabel *titleLabel = self.titleLabel;
    
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    titleLabel.textAlignment = UITextAlignmentCenter;
    
    if (self.module.secondary) {
        imageSize = [self.springboard secondaryModuleIconSize];
        titleImageGap = [self.springboard secondaryModuleLabelTitleMargin];
        titleLabel.font = [self.springboard secondaryModuleLabelFont];
    } else {
        imageSize = [self.springboard moduleIconSize];
        titleImageGap = [self.springboard moduleLabelTitleMargin];
        titleLabel.font = self.compact ? [self.springboard moduleLabelFont] : [self.springboard moduleLabelFontLarge];
    }

    // calculate title edge insets.
    if (!imageSize.width || !imageSize.height) {
        imageSize = image.size;
    }
    
    if (self.compact) {
        // we want to top-align the label
        CGFloat extraLineHeight = 0;
        NSArray *words = [title componentsSeparatedByString:@" "];
        if (words.count > 1) {
            extraLineHeight = (words.count - 1) * [self.titleLabel.font lineHeight];
        }
        CGFloat sideInsets = floor((self.frame.size.width - imageSize.width) / 2);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, sideInsets, self.frame.size.height - imageSize.height, sideInsets);
        self.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height + titleImageGap + extraLineHeight, // want title below image
                                                -self.frame.size.width,                             // and not to the right
                                                0, 0);
    } else {
        // we want to left-align the label and image
        CGSize titleSize = [title sizeWithFont:self.titleLabel.font];
        CGFloat rightPadding = self.frame.size.width - imageSize.width - titleSize.width;
        
        // TODO: account for user-set icon dimensions
        UIEdgeInsets insets = self.titleEdgeInsets;
        insets.right = rightPadding;
        self.titleEdgeInsets = insets;
        
        insets = self.imageEdgeInsets;
        insets.right = rightPadding;
        self.imageEdgeInsets = insets;
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
