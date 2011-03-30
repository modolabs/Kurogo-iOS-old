#import "KGODetailPageHeaderView.h"
#import "KGOSearchModel.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

#define LABEL_PADDING 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

@interface KGODetailPageHeaderView (Private)

- (void)toggleBookmark:(id)sender;
- (void)layoutBookmarkButton;
- (void)layoutShareButton;
- (void)hideShareButton;
- (void)hideBookmarkButton;
- (CGFloat)headerWidthWithButtons;

@end


@implementation KGODetailPageHeaderView

@synthesize showsShareButton, showsBookmarkButton, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.detailItem = nil;
    [self hideShareButton];
    [self hideBookmarkButton];
    [_titleLabel release];
    [_subtitleLabel release];
    [super dealloc];
}

- (void)layoutSubviews
{
    if (_titleLabel) {
        CGFloat maxWidth = self.frame.size.width - 2 * LABEL_PADDING;
        CGSize constraintSize = CGSizeMake(maxWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
        CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
        _titleLabel.frame = CGRectMake(LABEL_PADDING, LABEL_PADDING, maxWidth, textSize.height);
        
        if (![_titleLabel isDescendantOfView:self]) {
            [self addSubview:_titleLabel];
        }
        
        CGRect frame = self.frame;
        frame.size.height = fmaxf(frame.size.height, LABEL_PADDING * 2 + _titleLabel.frame.size.height);
        self.frame = frame;
    }
    
    if (_subtitleLabel) {
        CGFloat maxWidth = [self headerWidthWithButtons] - 2 * LABEL_PADDING;
        CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
        CGSize textSize = [_titleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
        CGFloat y = LABEL_PADDING;
        if (_titleLabel) {
            y += _titleLabel.frame.size.height + LABEL_PADDING;
        }
        _subtitleLabel.frame = CGRectMake(LABEL_PADDING, y, maxWidth, textSize.height);
        
        if (![_subtitleLabel isDescendantOfView:self]) {
            [self addSubview:_subtitleLabel];
        }
        
        CGRect frame = self.frame;
        frame.size.height = fmaxf(frame.size.height, LABEL_PADDING + _subtitleLabel.frame.origin.y + _subtitleLabel.frame.size.height);
        self.frame = frame;
    }
    
    if (_bookmarkButton || _shareButton) {
        CGRect frame = frame;
        CGFloat height = _bookmarkButton != nil ? _bookmarkButton.frame.size.height : _shareButton.frame.size.height;
        frame.size.height = fmaxf(frame.size.height, LABEL_PADDING * 2 + height);
        self.frame = frame;
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [[KGOTheme sharedTheme] fontForContentTitle];
        _titleLabel.textColor = [[KGOTheme sharedTheme] textColorForContentTitle];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel
{
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.font = [[KGOTheme sharedTheme] fontForBodyText];
        _subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForBodyText];
    }
    return _subtitleLabel;
}

- (BOOL)showsShareButton
{
    return _showsShareButton;
}

- (BOOL)showsBookmarkButton
{
    return _showsBookmarkButton;
}

- (void)setShowsShareButton:(BOOL)shows
{
    _showsShareButton = shows;
    
    if (_showsShareButton) {
        [self layoutShareButton];
    } else {
        [self hideShareButton];
    }
}

- (void)setShowsBookmarkButton:(BOOL)shows
{
    _showsBookmarkButton = shows;
    
    if (_showsBookmarkButton) {
        [self layoutBookmarkButton];
    } else {
        [self hideBookmarkButton];
    }
}

- (id<KGOSearchResult>)detailItem
{
    return _detailItem;
}

- (void)setDetailItem:(id<KGOSearchResult>)item
{
    [_detailItem release];
    _detailItem = [item retain];
    
    self.titleLabel.text = _detailItem.title;
    if ([_detailItem respondsToSelector:@selector(subtitle)]) {
        self.subtitleLabel.text = [_detailItem subtitle];
    }
}

- (CGFloat)headerWidthWithButtons
{
    // assuming share button occupies far right
    // and bookmark button comes after share
    CGFloat result = self.bounds.size.width - 10;
    if (_shareButton) {
        result -= _shareButton.frame.size.width + 10;
    }
    if (_bookmarkButton) {
        result -= _bookmarkButton.frame.size.width + 10;
    }
    return result;
}

- (void)toggleBookmark:(id)sender
{
    if ([self.detailItem isBookmarked]) {
        [self.detailItem removeBookmark];
    } else {
        [self.detailItem addBookmark];
    }

    [self layoutBookmarkButton];
}


- (void)layoutBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - placeholder.size.width;
        CGFloat buttonY = LABEL_PADDING + (_titleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(buttonX, buttonY, placeholder.size.width, placeholder.size.height);
        
        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_bookmarkButton];
    }
    
    UIImage *buttonImage, *pressedButtonImage;
    if ([self.detailItem isBookmarked]) {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_on.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_on_pressed.png"];
    } else {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_off_pressed.png"];
    }
    [_bookmarkButton setImage:buttonImage forState:UIControlStateNormal];
    [_bookmarkButton setImage:pressedButtonImage forState:UIControlStateHighlighted];
}

- (void)hideBookmarkButton
{
    if (_bookmarkButton) {
        [_bookmarkButton removeFromSuperview];
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}

- (void)layoutShareButton
{
    if (!_shareButton) {
        UIImage *buttonImage = [UIImage imageWithPathName:@"common/share.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - buttonImage.size.width;
        CGFloat buttonY = LABEL_PADDING + (_titleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
        
        _shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _shareButton.frame = CGRectMake(buttonX, buttonY, buttonImage.size.width, buttonImage.size.height);
        [_shareButton setImage:buttonImage forState:UIControlStateNormal];
        [_shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];
        if ([self.delegate respondsToSelector:@selector(shareButtonPressed:)]) {
            [_shareButton addTarget:self.delegate action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_shareButton];
        
        if (_bookmarkButton) {
            CGRect frame = _bookmarkButton.frame;
            frame.origin.x = [self headerWidthWithButtons];
            _bookmarkButton.frame = frame;
        }
    }
}

- (void)hideShareButton
{
    if (_shareButton) {
        [_shareButton removeFromSuperview];
        [_shareButton release];
        _shareButton = nil;
    }
    
    // make sure bookmark button is flushed right
    if (_bookmarkButton) {
        CGRect frame = _bookmarkButton.frame;
        frame.origin.x = [self headerWidthWithButtons];
        _bookmarkButton.frame = frame;
    }
}

@end
