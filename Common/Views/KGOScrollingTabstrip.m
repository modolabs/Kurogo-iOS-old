#import "KGOScrollingTabstrip.h"
#import "UIKit+KGOAdditions.h"

#define SCROLL_TAB_HORIZONTAL_MARGIN 5.0
#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define MINIMUM_BUTTON_WIDTH 36.0

@interface KGOScrollingTabstrip (Private)

- (void)sideButtonPressed:(id)sender;
- (void)buttonPressed:(id)sender;

@end


@implementation KGOScrollingTabstrip

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame delegate:(id<KGOScrollingTabstripDelegate>)delegate buttonTitles:(NSString *)title, ... {
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [[NSMutableArray alloc] init];
        
        va_list args;
        va_start(args, title);
        for (NSString *arg = title; arg != nil; arg = va_arg(args, NSString*)) {
            [self addButtonWithTitle:title];
        }
        va_end(args);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _buttons = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setShowsSearchButton:(BOOL)shows {
    if (shows != (_searchButton != nil)) {
        if (shows) {
            _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *image = [UIImage imageWithPathName:@"common/search.png"];
            [_searchButton setImage:image forState:UIControlStateNormal];
            _searchButton.adjustsImageWhenHighlighted = NO;
            // ensure that button is wide enough to tap
            CGFloat buttonWidth = image.size.width;
            CGFloat insetWidth = 0;
            if (buttonWidth < MINIMUM_BUTTON_WIDTH) {
                insetWidth = floor((MINIMUM_BUTTON_WIDTH - buttonWidth) / 2);
                buttonWidth = MINIMUM_BUTTON_WIDTH;
            }
            _searchButton.imageEdgeInsets = UIEdgeInsetsMake(-1, insetWidth, 0, insetWidth);
            CGFloat yOrigin = floor((self.frame.size.height - image.size.height) / 2);
            _searchButton.frame = CGRectMake(0, yOrigin, buttonWidth, image.size.height);
            [_searchButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            if ([_buttons count] > 0) {
                [_buttons insertObject:_searchButton atIndex:0];
            } else {
                [_buttons addObject:_searchButton];
            }
        } else {
            [_buttons removeObject:_searchButton];
            _searchButton = nil;
        }
    }
}

- (BOOL)showsSearchButton {
    return _searchButton != nil;
}

- (void)setShowsBookmarkButton:(BOOL)shows {
    if (shows != (_bookmarkButton != nil)) {
        
        if (shows) {
            _bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *image = [UIImage imageWithPathName:@"common/bookmark.png"];
            [_bookmarkButton setImage:image forState:UIControlStateNormal];
            _bookmarkButton.adjustsImageWhenHighlighted = NO;
            // ensure that button is wide enough to tap
            CGFloat buttonWidth = image.size.width;
            CGFloat insetWidth = 0;
            if (buttonWidth < MINIMUM_BUTTON_WIDTH) {
                insetWidth = floor((MINIMUM_BUTTON_WIDTH - buttonWidth) / 2);
                buttonWidth = MINIMUM_BUTTON_WIDTH;
            }
            _bookmarkButton.imageEdgeInsets = UIEdgeInsetsMake(-1, insetWidth, 0, insetWidth);
            CGFloat yOrigin = floor((self.frame.size.height - image.size.height) / 2);
            _bookmarkButton.frame = CGRectMake(0, yOrigin, buttonWidth, image.size.height);
            [_bookmarkButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            NSUInteger insertIndex = 0;
            if (self.showsSearchButton) {
                insertIndex++;
            }
            
            if ([_buttons count] > insertIndex) {
                [_buttons insertObject:_bookmarkButton atIndex:insertIndex];
            } else {
                [_buttons addObject:_bookmarkButton];
            }
        } else {
            [_buttons removeObject:_bookmarkButton];
            _bookmarkButton = nil;
        }
    }
}

- (BOOL)showsBookmarkButton {
    return _bookmarkButton != nil;
}

// TODO: get assets from config
- (void)addButtonWithTitle:(NSString *)title {
    UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [aButton setTitle:title forState:UIControlStateNormal];
    [aButton setTitleColor:[UIColor colorWithHexString:@"#E0E0E0"] forState:UIControlStateNormal];
    [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    aButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    aButton.titleLabel.tag = 1002;
    aButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
    CGSize size = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];

    // TODO: make configurable
	UIImage *stretchableButtonImage = [[UIImage imageWithPathName:@"common/scrolltabs-selected.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    [aButton setBackgroundImage:nil forState:UIControlStateNormal];
    [aButton setBackgroundImage:stretchableButtonImage forState:UIControlStateHighlighted];
    
    CGFloat yOrigin = floor((self.frame.size.height - stretchableButtonImage.size.height) / 2);
    aButton.frame = CGRectMake(0, yOrigin, size.width + 2 * SCROLL_TAB_HORIZONTAL_PADDING, stretchableButtonImage.size.height);
    [aButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [_buttons addObject:aButton];
}

- (NSString *)buttonTitleAtIndex:(NSUInteger)index {
    UIButton *button = [_buttons objectAtIndex:index];
    if (button == _searchButton || button == _bookmarkButton) {
        return nil;
    }
    return [button titleForState:UIControlStateNormal];
}

- (NSInteger)searchButtonIndex {
    if (_searchButton) {
        return [_buttons indexOfObject:_searchButton];
    }
    return NSNotFound;
}

- (NSInteger)bookmarkButtonIndex {
    if (_bookmarkButton) {
        return [_buttons indexOfObject:_bookmarkButton];
    }
    return NSNotFound;
}

- (NSUInteger)numberOfButtons {
    return [_buttons count];
}

// TODO: get config values for tabstrip
- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_backgroundImageView) {
        UIImage *backgroundImage = [UIImage imageWithPathName:@"common/scrolltabs-background-opaque.png"];
        _backgroundImageView = [[[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]] autorelease];
        [self addSubview:_backgroundImageView];
    }

    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        
        _contentView = [[UIView alloc] initWithFrame:self.frame];
        
        [_scrollView addSubview:_contentView];
        [self addSubview:_scrollView];
    }
    
    CGFloat xOffset = SCROLL_TAB_HORIZONTAL_MARGIN;
    for (UIButton *aButton in _buttons) {
        aButton.frame = CGRectMake(xOffset, aButton.frame.origin.y, aButton.frame.size.width, aButton.frame.size.height);
        xOffset += aButton.frame.size.width + SCROLL_TAB_HORIZONTAL_MARGIN;
        
        if (![aButton isDescendantOfView:self]) {
            [_contentView addSubview:aButton];
        }
        
        if (_contentView.frame.size.width < xOffset) {
            _contentView.frame = CGRectMake(_contentView.frame.origin.x, _contentView.frame.origin.y, xOffset, _contentView.frame.size.height);
            _scrollView.contentSize = _contentView.frame.size;
        }
    }
    
    // allow a few pixel overflow before we start adding scroll buttons
    // TODO: stop cheating
    if (_contentView.frame.size.width > self.frame.size.width + 10) {
        if (!_leftScrollButton) {
            UIImage *leftScrollImage = [UIImage imageWithPathName:@"common/scrolltabs-leftarrow.png"];
            CGRect imageFrame = CGRectMake(0, 0, leftScrollImage.size.width, leftScrollImage.size.height);
            _leftScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _leftScrollButton.frame = imageFrame;
            _leftScrollButton.hidden = YES;
            [_leftScrollButton setImage:leftScrollImage forState:UIControlStateNormal];
            [_leftScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_leftScrollButton];
        
        if (!_rightScrollButton) {
            UIImage *rightScrollImage = [UIImage imageWithPathName:@"common/scrolltabs-rightarrow.png"];
            CGRect imageFrame = CGRectMake(self.frame.size.width - rightScrollImage.size.width,0,rightScrollImage.size.width,rightScrollImage.size.height);
            _rightScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _rightScrollButton.frame = imageFrame;
            _rightScrollButton.hidden = NO;
            [_rightScrollButton setImage:rightScrollImage forState:UIControlStateNormal];
            [_rightScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_rightScrollButton];
    }
}

- (void)selectButtonAtIndex:(NSUInteger)index {
    UIButton *button = [_buttons objectAtIndex:index];
    [self buttonPressed:button];
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
    
    if (pressedButton != _pressedButton && [_buttons containsObject:pressedButton]) {
        
        if (_pressedButton.adjustsImageWhenHighlighted) {
            [_pressedButton setTitleColor:[UIColor colorWithHexString:@"#E0E0E0"] forState:UIControlStateNormal];
            [_pressedButton setBackgroundImage:nil forState:UIControlStateNormal];
        }

        if (pressedButton.adjustsImageWhenHighlighted) {
            UIImage *buttonImage = [UIImage imageWithPathName:@"common/scrolltabs-selected.png"];
            UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
            
            [pressedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [pressedButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
        }

        _pressedButton = pressedButton;
    }
    
    NSUInteger index = [_buttons indexOfObject:_pressedButton];
    [self.delegate tabstrip:self clickedButtonAtIndex:index];
}

- (void)sideButtonPressed:(id)sender {
	// This is a slight cheat. The bumpers scroll the next text button so it fits completely into view, 
	// but if all of the buttons in navbuttons are already in view, this scrolls by default to the far
	// left, where the search and bookmark buttons sit.
    CGPoint offset = _scrollView.contentOffset;
	CGRect tabRect = CGRectMake(0, 0, 1, 1); // Because CGRectZero is ignored by -scrollRectToVisible:
	
    if (sender == _leftScrollButton) {
        NSInteger i, count = [_buttons count];
        for (i = count - 1; i >= 0; i--) {
            UIButton *tab = [_buttons objectAtIndex:i];
            if (CGRectGetMinX(tab.frame) - offset.x < 0) {
                tabRect = tab.frame;
                tabRect.origin.x -= _leftScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    } else if (sender == _rightScrollButton) {
        for (UIButton *tab in _buttons) {
            if (CGRectGetMaxX(tab.frame) - (offset.x + _scrollView.frame.size.width) > 0) {
                tabRect = tab.frame;
                tabRect.origin.x += _rightScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    }
	[_scrollView scrollRectToVisible:tabRect animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == _scrollView) {
		CGPoint offset = scrollView.contentOffset;
		if (offset.x <= 0) {
			_leftScrollButton.hidden = YES;
		} else {
			_leftScrollButton.hidden = NO;
		}
		if (offset.x >= _scrollView.contentSize.width - _scrollView.frame.size.width) {
			_rightScrollButton.hidden = YES;
		} else {
			_rightScrollButton.hidden = NO;
		}
	}
}

- (void)dealloc {
    [_contentView release];
    [_scrollView release];
    [_buttons release];
    [super dealloc];
}

@end

