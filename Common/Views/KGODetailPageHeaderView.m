#import "KGODetailPageHeaderView.h"
#import "KGOSearchModel.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

#define LABEL_PADDING 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

@implementation KGODetailPageHeaderView

@synthesize showsShareButton, showsBookmarkButton, delegate;

@synthesize showsSubtitle;
@synthesize actionButtons = _actionButtons;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.actionButtons = [NSMutableArray array];
        self.showsSubtitle = YES;
    }
    return self;
}

- (void)dealloc
{
    self.actionButtons = nil;
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
    
    if (self.actionButtons.count) {
        UIButton *aButton = [self.actionButtons objectAtIndex:0];
        buttonHeight = aButton.frame.size.height + LABEL_PADDING;
    }
    
    if (_titleLabel) {
        CGFloat maxWidth = 0;
        if (_subtitleLabel) {
            maxWidth = self.bounds.size.width - 2 * LABEL_PADDING;
        } else {
            maxWidth = [self headerWidthWithButtons];// - 2 * LABEL_PADDING;
        }
        CGSize constraintSize = CGSizeMake(maxWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
        CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
        _titleLabel.frame = CGRectMake(LABEL_PADDING, LABEL_PADDING, maxWidth, textSize.height);
        titleHeight = _titleLabel.frame.size.height + LABEL_PADDING;
    }
    
    if (_subtitleLabel) {
        CGFloat maxWidth = [self headerWidthWithButtons];// - 2 * LABEL_PADDING;
        CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
        CGSize textSize = [_subtitleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
        CGFloat y = LABEL_PADDING + titleHeight;
        _subtitleLabel.frame = CGRectMake(LABEL_PADDING, y, maxWidth, textSize.height);
        // in case the row of buttons is taller than the subtitle
        subtitleHeight = fmaxf(_subtitleLabel.frame.size.height, buttonHeight) + LABEL_PADDING;
    }
    
    [self layoutActionButtons];
    
    CGRect frame = self.frame;
    frame.size.height = titleHeight + subtitleHeight + LABEL_PADDING;
    self.frame = frame;

    if ((self.frame.size.width != oldFrame.size.width || self.frame.size.height != oldFrame.size.height)
        && [self.delegate respondsToSelector:@selector(headerViewFrameDidChange:)]
    ) {
        [self.delegate headerViewFrameDidChange:self];
    }
}

- (UILabel *)titleLabel
{
    return _titleLabel;
}

- (UILabel *)subtitleLabel
{
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
    } else {
        [self addShareButton];
    }
}

- (void)setShowsBookmarkButton:(BOOL)shows
{
    _showsBookmarkButton = shows;
    
    if (!_showsBookmarkButton) {
        [self hideBookmarkButton];
    } else {
        [self addBookmarkButton];
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
    
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        _titleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
        _titleLabel.numberOfLines = MAX_TITLE_LINES;
    }
    self.titleLabel.text = _detailItem.title;
    if (![_titleLabel isDescendantOfView:self]) {
        [self addSubview:_titleLabel];
    }

    NSString *subtitle = nil;
    if (self.showsSubtitle && [_detailItem respondsToSelector:@selector(subtitle)]) {
        subtitle = [_detailItem subtitle];
    }

    if (subtitle) {
        if (!_subtitleLabel) {
            _subtitleLabel = [[UILabel alloc] init];
            _subtitleLabel.backgroundColor = [UIColor clearColor];
            _subtitleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
            
            _subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentSubtitle];
            _subtitleLabel.numberOfLines = MAX_SUBTITLE_LINES;
        }
        self.subtitleLabel.text = subtitle;
        if (![_subtitleLabel isDescendantOfView:self]) {
            [self addSubview:_subtitleLabel];
        }

    } else if (_subtitleLabel) {
        [_subtitleLabel removeFromSuperview];
        [_subtitleLabel release];
        _subtitleLabel = nil;
    }
}

- (CGFloat)headerWidthWithButtons
{    
    CGFloat fullWidth = self.bounds.size.width - 2 * LABEL_PADDING;
    for (UIButton *aButton in self.actionButtons) {
        fullWidth -= aButton.frame.size.width + LABEL_PADDING;
    }
    return fullWidth;
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

- (void)addButton:(UIButton *)button
{
    if (![_actionButtons containsObject:button]) {
        [_actionButtons addObject:button];
    }
}

- (void)addBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(0, 0, placeholder.size.width, placeholder.size.height);
        
        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self addButton:_bookmarkButton];
}

- (void)addShareButton
{
    if (!_shareButton) {
        UIImage *buttonImage = [UIImage imageWithPathName:@"common/share.png"];
        _shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _shareButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        [_shareButton setImage:buttonImage forState:UIControlStateNormal];
        [_shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];
        if ([self.delegate respondsToSelector:@selector(headerView:shareButtonPressed:)]) {
            [_shareButton addTarget:self.delegate
                             action:@selector(headerView:shareButtonPressed:)
                   forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [self addButton:_shareButton];
}

- (void)layoutActionButtons
{
    CGRect frame = CGRectZero;
    frame.origin.x = self.bounds.size.width;
    
    // if there is no subtitle, make title label narrower
    // and align buttons at the top.
    // if there is a subtitle, make title label the full width,
    // subtitle label narrower, and align buttons with subtitle.
    frame.origin.y = LABEL_PADDING + (_subtitleLabel == nil ? 0 : _titleLabel.frame.size.height + LABEL_PADDING);

    for (UIButton *aButton in self.actionButtons) {
        if (![aButton isDescendantOfView:self]) {
            [self addSubview:aButton];
        }
        
        frame.size = aButton.frame.size;
        frame.origin.x -= frame.size.width + LABEL_PADDING;
        aButton.frame = frame;

        if (aButton == _bookmarkButton) {
            [self setupBookmarkButtonImages];
        }
    }
}

- (void)hideBookmarkButton
{
    if (_bookmarkButton) {
        [_bookmarkButton removeFromSuperview];
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}

- (void)hideShareButton
{
    if (_shareButton) {
        [_shareButton removeFromSuperview];
        [_shareButton release];
        _shareButton = nil;
    }
}

@end
