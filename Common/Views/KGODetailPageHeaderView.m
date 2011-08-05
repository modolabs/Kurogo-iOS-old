#import "KGODetailPageHeaderView.h"
#import "KGOSearchModel.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

#define LABEL_PADDING 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

@implementation KGODetailPageHeaderView

@synthesize showsShareButton, showsBookmarkButton, delegate;
/*
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
*/
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
    CGRect oldFrame = self.frame;
    CGFloat titleHeight = 0;
    CGFloat subtitleHeight = 0;
    CGFloat buttonHeight = 0;
    
    if (_showsShareButton) {
        [self layoutShareButton];
        buttonHeight = _shareButton.frame.size.height + LABEL_PADDING;
    }
    
    if (_showsBookmarkButton) {
        [self layoutBookmarkButton];
        buttonHeight = _bookmarkButton.frame.size.height + LABEL_PADDING;
    }
    
    if (_titleLabel) {
        CGFloat maxWidth;
        if (_subtitleLabel) {
            maxWidth = self.bounds.size.width - 2 * LABEL_PADDING;
        } else {
            maxWidth = [self headerWidthWithButtons] - 2 * LABEL_PADDING;
        }
        CGSize constraintSize = CGSizeMake(maxWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
        CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
        _titleLabel.frame = CGRectMake(LABEL_PADDING, LABEL_PADDING, maxWidth, textSize.height);
        titleHeight = _titleLabel.frame.size.height + LABEL_PADDING;
    }
    
    if (_subtitleLabel) {
        CGFloat maxWidth = [self headerWidthWithButtons] - 2 * LABEL_PADDING;
        CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
        CGSize textSize = [_subtitleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
        CGFloat y = LABEL_PADDING;
        if (_titleLabel) {
            y += _titleLabel.frame.size.height + LABEL_PADDING;
            
            CGRect buttonFrame = _bookmarkButton.frame;
            buttonFrame.origin.y = y;
            _bookmarkButton.frame = buttonFrame;
            
            buttonFrame = _shareButton.frame;
            buttonFrame.origin.y = y;
            _shareButton.frame = buttonFrame;
        }
        _subtitleLabel.frame = CGRectMake(LABEL_PADDING, y, maxWidth, textSize.height);
        subtitleHeight = _subtitleLabel.frame.size.height + LABEL_PADDING;
    }
    
    CGRect frame = self.frame;
    frame.size.height = titleHeight + fmaxf(subtitleHeight, buttonHeight) + LABEL_PADDING;
    self.frame = frame;

    if ((self.frame.size.width != oldFrame.size.width || self.frame.size.height != oldFrame.size.height)
        && [self.delegate respondsToSelector:@selector(headerViewFrameDidChange:)]
    ) {
        [self.delegate headerViewFrameDidChange:self];
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        _titleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
        _titleLabel.numberOfLines = MAX_TITLE_LINES;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel
{
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
        _subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentSubtitle];
        _subtitleLabel.numberOfLines = MAX_SUBTITLE_LINES;
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
    
    if (!_showsShareButton) {
        [self hideShareButton];
    }
}

- (void)setShowsBookmarkButton:(BOOL)shows
{
    _showsBookmarkButton = shows;
    
    if (!_showsBookmarkButton) {
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
    
    CGRect frame = self.frame;
    frame.size.height = 0;
    self.frame = frame;
    
    self.titleLabel.text = _detailItem.title;
    if (![_titleLabel isDescendantOfView:self]) {
        [self addSubview:_titleLabel];
    }
    
    NSString *subtitle = nil;
    if ([_detailItem respondsToSelector:@selector(subtitle)]) {
        subtitle = [_detailItem subtitle];
    }
    
    if (subtitle) {
        self.subtitleLabel.text = [_detailItem subtitle];
        if (![_subtitleLabel isDescendantOfView:self]) {
            [self addSubview:_subtitleLabel];
        }
    
    } else {
        [_subtitleLabel removeFromSuperview];
        [_subtitleLabel release];
        _subtitleLabel = nil;
    }
}

- (CGFloat)headerWidthWithButtons
{
    // assuming share button occupies far right
    // and bookmark button comes after share
    CGFloat result = self.bounds.size.width - LABEL_PADDING;
    if (_shareButton) {
        result -= _shareButton.frame.size.width + LABEL_PADDING;
    }
    if (_bookmarkButton) {
        result -= _bookmarkButton.frame.size.width + LABEL_PADDING;
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

    [self setupBookmarkButtonImages];
}

- (void)setupBookmarkButtonImages
{
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

- (void)layoutBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - placeholder.size.width;
        CGFloat buttonY = LABEL_PADDING + (_subtitleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(buttonX, buttonY, placeholder.size.width, placeholder.size.height);
        
        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_bookmarkButton];
        
    }
    
    [self setupBookmarkButtonImages];
    
    CGRect frame = _bookmarkButton.frame;
    if (_shareButton) {
        frame.origin.x = self.bounds.size.width - _shareButton.frame.size.width - frame.size.width - 2 * LABEL_PADDING;
    }
    frame.origin.y = LABEL_PADDING + (_subtitleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
    _bookmarkButton.frame = frame;
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
        CGFloat buttonX = self.frame.size.width - buttonImage.size.width - LABEL_PADDING;
        CGFloat buttonY = LABEL_PADDING + (_titleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
        
        _shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _shareButton.frame = CGRectMake(buttonX, buttonY, buttonImage.size.width, buttonImage.size.height);
        [_shareButton setImage:buttonImage forState:UIControlStateNormal];
        [_shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];
        if ([self.delegate respondsToSelector:@selector(headerView: shareButtonPressed:)]) {
            [_shareButton addTarget:self.delegate action:@selector(headerView: shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_shareButton];
        
    } else {
        CGRect frame = _shareButton.frame;
        frame.origin.y = LABEL_PADDING + (_titleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);
        _shareButton.frame = frame;
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
