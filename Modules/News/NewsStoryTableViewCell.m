#import "NewsStoryTableViewCell.h"
#import "KGOLabel.h"
#import "NewsModel.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"

@implementation NewsStoryTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString *)reuseIdentifier
{
    return [[self class] commonReuseIdentifier];
}

+ (NSString *)commonReuseIdentifier
{
    static NSString *reuseIdentifier = @"faheuif23";
    return reuseIdentifier;
}

- (void)configureLabelsTheme {
    _titleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyMediaListTitle];
    _titleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyMediaListTitle];
    
    _dekLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyMediaListSubtitle];
    _dekLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyMediaListSubtitle];
}

- (void)setStory:(NewsStory *)story
{
    [_story release];
    _story = [story retain];

    // title
    NSString *title = [_story.title stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"&apos;"] withString:@"'"];
    _titleLabel.text = title;
    CGSize constraint = CGSizeMake(_titleLabel.frame.size.width, self.frame.size.height - 10);
    CGSize size = [_story.title sizeWithFont:_titleLabel.font constrainedToSize:constraint];
    CGRect frame = _titleLabel.frame;
    frame.size.height = size.height;
    _titleLabel.frame = frame;

    // dek
    CGFloat constraintHeight = self.frame.size.height - _titleLabel.frame.size.height - 14;
    if (size.height >= _dekLabel.font.lineHeight) {
        size = [_story.summary sizeWithFont:_dekLabel.font constrainedToSize:CGSizeMake(_dekLabel.frame.size.width, constraintHeight)];
        _dekLabel.text = _story.summary;
        frame = _dekLabel.frame;
        frame.origin.y = _titleLabel.frame.size.height;
        frame.size.height = size.height;
        _dekLabel.frame = frame;
    } else {
        // if not even one line will fit, don't show the deck at all
        _dekLabel.text = nil;
    }
    
    if (_story.thumbImage) {
        _thumbnailView.delegate = self;
        _thumbnailView.imageURL = _story.thumbImage.url;
        _thumbnailView.imageData = _story.thumbImage.data;
        [_thumbnailView loadImage];
        
    } else {
        _thumbnailView.imageURL = nil;
        [_thumbnailView setPlaceholderImage:[UIImage imageWithPathName:@"modules/news/news-placeholder.png"]];
    }
}

- (NewsStory *)story
{
    return _story;
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    self.story.thumbImage.data = data;
    [[CoreDataManager sharedManager] saveData];
}

@end
