#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class MITThumbnailView;

@protocol MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data;

@end

// set backgroundColor to [UIColor colorwithPatternImage:] to use a placeholder thumbnail
@interface MITThumbnailView : UIView <ConnectionWrapperDelegate> {
    NSString *imageURL;
    ConnectionWrapper *connection;
    NSData *_imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
    id<MITThumbnailDelegate> delegate;
    
    BOOL _didDisplayImage;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;
- (void)setPlaceholderImage:(UIImage *)image;

@property (nonatomic, assign) id<MITThumbnailDelegate> delegate;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
